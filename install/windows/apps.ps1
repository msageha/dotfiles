#!/usr/bin/env pwsh
# Windows 向け GUI アプリのインストール (winget)。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

# 既定のソースは winget。winget-pkgs に無く Microsoft Store 配布のみのものは Source を明示する。
$Apps = @(
    @{ Id = 'Google.Chrome' }
    @{ Id = 'Google.JapaneseIME' }
    @{ Id = 'Discord.Discord' }
    @{ Id = '7zip.7zip' }
    @{ Id = 'Microsoft.VisualStudioCode' }
    @{ Id = 'Microsoft.PowerToys' }
    @{ Id = 'AgileBits.1Password' }
    @{ Id = 'Google.GoogleDrive' }
    @{ Id = '9NT1R1C2HH7J'; Source = 'msstore' } # ChatGPT
)

function Install-GuiApps {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn 'winget が見つかりません。GUI アプリを手動で導入してください。'
        return
    }
    foreach ($app in $Apps) {
        $id = $app.Id
        $source = if ($app.ContainsKey('Source')) { $app.Source } else { 'winget' }
        winget list --id $id --exact --source $source --accept-source-agreements *> $null
        if ($LASTEXITCODE -eq 0) {
            Write-Step "$id is already installed. Skipping"
            continue
        }
        Write-Step "Installing $id via winget ($source)..."
        winget install --id $id --exact --source $source `
            --accept-package-agreements --accept-source-agreements
        # 1 つの失敗 (msstore の未サインイン等) で apply 全体を止めないよう、警告して続行する
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "$id のインストールが終了コード $LASTEXITCODE で失敗しました。続行します。"
        }
    }
}

function Uninstall-OneDrive {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn 'winget が見つかりません。OneDrive のアンインストールをスキップします。'
        return
    }
    # プリインストール版は ARP エントリで検出したいため --source は指定しない
    winget list --id Microsoft.OneDrive --exact --accept-source-agreements *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Step 'OneDrive はインストールされていないため、スキップします。'
        return
    }
    Write-Step 'OneDrive をアンインストールしています...'
    # 実行中だとアンインストーラが失敗することがあるため先に停止する
    Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue
    winget uninstall --id Microsoft.OneDrive --exact --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "OneDrive のアンインストールが終了コード $LASTEXITCODE で失敗しました。続行します。"
    }
}

function Set-PowerToysSettings {
    # PowerToys の設定 JSON はバージョン間でスキーマが変わりうるうえ、一度も起動していないと存在しないため、
    # 直接書き換えず公式の設定 CLI (PowerToys.DSC.exe、v0.95.0 以降に同梱) を使う。
    $dscExe = @(
        (Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.DSC.exe')
        (Join-Path $env:ProgramFiles 'PowerToys\PowerToys.DSC.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $dscExe) {
        Write-Warn 'PowerToys.DSC.exe が見つかりません (PowerToys 未インストール、または v0.95.0 より古い可能性があります)。PowerToys の設定はスキップします。'
        return
    }

    # 有効/無効の切り替えだけなので、アプリ全体の設定を扱う "App" モジュールを使う。
    # PowerLauncher は PowerToys Run、Hosts は Hosts File Editor の内部名。
    $config = @{
        settings = @{
            properties = @{
                Enabled = @{
                    FancyZones           = $true
                    PowerLauncher        = $true
                    Hosts                = $true
                    EnvironmentVariables = $true
                }
            }
            name    = 'App'
            version = '1.0'
        }
    } | ConvertTo-Json -Depth 10 -Compress

    # Windows PowerShell 5.1 はネイティブ exe への引数内の " をエスケープせず渡すため、
    # そのままだと子プロセス側で引用符が剥がれて JSON として不正になる
    $config = $config -replace '"', '\"'

    # DSC exe の起動失敗 (AppLocker 等) も警告に留め、後続のセットアップを止めない
    try {
        & $dscExe set --resource 'settings' --module App --input $config
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "PowerToys の設定適用が終了コード $LASTEXITCODE を返しました。PowerToys の設定画面から手動で有効化してください。"
            return
        }
        Write-Step 'PowerToys の FancyZones / PowerToys Run / Hosts File Editor / Environment Variables を有効化しました。'
    }
    catch {
        Write-Warn "PowerToys の設定適用に失敗しました。PowerToys の設定画面から手動で有効化してください: $($_.Exception.Message)"
    }
}

function Test-DefaultAppsAlreadySet {
    # UserChoice はハッシュ保護で書き込めないが、読み取りはできる。
    # 7-Zip は拡張子ごとに ProgId を持つが、.zip だけを代表として見る簡易判定にする。
    $browserProgId = Get-RegistryValueOrNull 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' 'ProgId'
    $zipProgId = Get-RegistryValueOrNull 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.zip\UserChoice' 'ProgId'

    $browserIsChrome = $browserProgId -like 'ChromeHTML*'
    $zipIs7Zip = $zipProgId -like '7-Zip.*'

    return ($browserIsChrome -and $zipIs7Zip)
}

function Open-DefaultAppsSettings {
    # 既定のブラウザ・展開ツールは UserChoice のハッシュ保護 (Windows 10/11 では UCPD ドライバも) により
    # スクリプトから設定できないため、設定アプリを開いてユーザーに選ばせる
    if (Test-DefaultAppsAlreadySet) {
        Write-Step '既定のブラウザ (Chrome) と展開ツール (7-Zip) は設定済みのため、既定アプリ設定はスキップします。'
        return
    }
    Write-Step '既定のアプリ設定を開きます。ブラウザは Chrome、展開ツールは 7-Zip に変更したい場合は選択してください。'
    try {
        Start-Process 'ms-settings:defaultapps'
    }
    catch {
        Write-Warn "既定のアプリ設定を開けませんでした: $($_.Exception.Message)"
    }
}

function Find-GoogleJapaneseInputTip {
    # IME の InputMethodTips は "<LCID>:{CLSID}{ProfileGUID}" 形式 (キーボードレイアウトの "0411:00000411" 等は一致しない)。
    # CLSID の TSF 登録情報の説明文字列に "Google" を含むものを探す。32bit の COM 登録もありうるため WOW6432Node も見る。
    param([string[]]$Tips)

    foreach ($tip in $Tips) {
        $m = [regex]::Match($tip, '^([0-9A-Fa-f]{4}):(\{[0-9A-Fa-f\-]+\})(\{[0-9A-Fa-f\-]+\})$')
        if (-not $m.Success) { continue }
        $langId  = $m.Groups[1].Value
        $clsid   = $m.Groups[2].Value
        # $profile は PowerShell の自動変数 (プロファイルパス) のため別名にする
        $profileGuid = $m.Groups[3].Value
        $candidatePaths = @(
            "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$clsid"
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\CTF\TIP\$clsid"
        )
        foreach ($path in $candidatePaths) {
            # 説明文字列は TIP キー直下、または言語プロファイル配下の
            # 既定値 / Description 値のいずれかに入っている
            $keys = @(
                Get-Item -Path $path -ErrorAction SilentlyContinue
                Get-Item -Path "$path\LanguageProfile\0x0000$langId\$profileGuid" -ErrorAction SilentlyContinue
            ) | Where-Object { $_ }
            foreach ($key in $keys) {
                $descriptions = @($key.GetValue(''), $key.GetValue('Description'))
                if ($descriptions | Where-Object { $_ -like '*Google*' }) {
                    return $tip
                }
            }
        }
    }
    return $null
}

function Set-DefaultInputMethod {
    # 既定の入力方式は UserChoice の保護対象外で、International モジュールの cmdlet で設定できる。
    # インストール直後は Google 日本語入力の IME が見つからないことがあるため、失敗は警告に留める。
    if (-not (Get-Command Set-WinDefaultInputMethodOverride -ErrorAction SilentlyContinue)) {
        Write-Warn 'Set-WinDefaultInputMethodOverride が見つかりません (International モジュール無し)。IME の既定化をスキップします。'
        return
    }
    try {
        $japanese = Get-WinUserLanguageList | Where-Object { $_.LanguageTag -eq 'ja-JP' }
        if (-not $japanese) {
            Write-Warn '言語リストに日本語 (ja-JP) が無いため、IME の既定化をスキップします。'
            return
        }
        $googleTip = Find-GoogleJapaneseInputTip -Tips $japanese.InputMethodTips
        if (-not $googleTip) {
            Write-Warn 'Google 日本語入力の IME が見つかりません (インストール直後はサインインし直すまで反映されないことがあります)。既定化をスキップします。'
            return
        }
        $current = Get-WinDefaultInputMethodOverride -ErrorAction SilentlyContinue
        if ($current -and $current.InputMethodTip -eq $googleTip) {
            Write-Step '既定の入力方式は既に Google 日本語入力のため、スキップします。'
            return
        }
        Set-WinDefaultInputMethodOverride -InputTip $googleTip
        Write-Step "既定の入力方式を Google 日本語入力に設定しました ($googleTip)"
    }
    catch {
        Write-Warn "IME の既定化に失敗しました: $($_.Exception.Message)"
    }
}

function Main {
    # GUI アプリの導入は時間がかかり対話を伴いうるため、CI ではスキップする
    if ($env:CI) {
        Write-Step 'CI 環境のため GUI アプリ導入・設定をスキップします。'
        return
    }
    Uninstall-OneDrive
    Install-GuiApps
    Set-PowerToysSettings
    Open-DefaultAppsSettings
    Set-DefaultInputMethod
}

Main
