#!/usr/bin/env pwsh
# Windows 向け GUI アプリのインストール (winget)。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

# winget のパッケージ ID (`winget search <name>` で確認できる)。
# 既定のソースは community リポジトリ (winget)。ChatGPT のように winget-pkgs に
# 登録が無く Microsoft Store 配布のみのものは Source を明示する。
$Apps = @(
    @{ Id = 'Google.Chrome' }
    @{ Id = 'Google.JapaneseIME' }
    @{ Id = 'Discord.Discord' }
    @{ Id = '7zip.7zip' }
    @{ Id = 'Microsoft.VisualStudioCode' }
    @{ Id = 'Microsoft.PowerToys' }
    @{ Id = 'AgileBits.1Password' }
    @{ Id = 'Google.GoogleDrive' }
    @{ Id = '9NT1R1C2HH7J'; Source = 'msstore' } # ChatGPT (winget-pkgs に無く Microsoft Store 配布のみ)
)

function Install-GuiApps {
    # GUI アプリは mac (brew.sh の cask) と同様、時間がかかり対話を伴いうるため CI ではスキップする
    if ($env:CI) {
        Write-Step 'CI 環境のため GUI アプリのインストールをスキップします。'
        return
    }
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
        # GUI アプリは best-effort とし、1 つの失敗 (msstore の未サインイン等) で
        # apply 全体を止めない。ただし黙って流さず警告は出す
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "$id のインストールが終了コード $LASTEXITCODE で失敗しました。続行します。"
        }
    }
}

function Set-PowerToysSettings {
    # PowerToys の設定は %LOCALAPPDATA%\Microsoft\PowerToys\ 配下の JSON で管理されており、
    # バージョン間でスキーマが変わりうる上、PowerToys が一度も実行されていないとファイル自体が
    # 存在しない等、レジストリほど安定した対象ではない。そのため生の JSON を直接書き換えるのではなく、
    # PowerToys 公式の設定 CLI (PowerToys.DSC.exe, v0.95.0 以降同梱) を経由して行う。
    if ($env:CI) {
        return
    }
    $dscExe = @(
        (Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.DSC.exe')
        (Join-Path $env:ProgramFiles 'PowerToys\PowerToys.DSC.exe')
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1

    if (-not $dscExe) {
        Write-Warn 'PowerToys.DSC.exe が見つかりません (PowerToys 未インストール、または v0.95.0 より古い可能性があります)。PowerToys の設定はスキップします。'
        return
    }

    # FancyZones / PowerToys Run (内部名 PowerLauncher) / Hosts File Editor (内部名 Hosts) /
    # Environment Variables を有効化する。個別モジュールの詳細設定 (ショートカット等) ではなく
    # 有効/無効の切り替えのみのため、アプリ全体設定を扱う "App" モジュールを使う。
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
    # UserChoice は「書き込み」はハッシュ保護されるが「読み取り」は誰でもできるため、
    # 既に望む状態になっているかはここで判定できる。7-Zip は拡張子ごとに ProgId を持つが、
    # .zip を代表として確認する (全拡張子を厳密に見るのはやり過ぎなので簡易判定とする)。
    $browserProgId = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice' -ErrorAction SilentlyContinue).ProgId
    $zipProgId = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.zip\UserChoice' -ErrorAction SilentlyContinue).ProgId

    $browserIsChrome = $browserProgId -like 'ChromeHTML*'
    $zipIs7Zip = $zipProgId -like '7-Zip.*'

    return ($browserIsChrome -and $zipIs7Zip)
}

function Open-DefaultAppsSettings {
    # ブラウザ (Chrome) や展開ツール (7-Zip) の既定アプリ変更は Windows 8+ の UserChoice
    # ハッシュ保護 (Windows 10/11 では UCPD ドライバによる改ざん防止も追加) により、
    # スクリプトから安全に自動設定する方法が無い。設定アプリの該当ページを開き、
    # ユーザーが選ぶだけの状態にする。実行のたびにポップアップが出ると煩わしいため、
    # 既に両方とも設定済みなら開かない。
    if ($env:CI) {
        return
    }
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
    # IME の InputMethodTips は "<LCID>:{CLSID}{ProfileGUID}" 形式 (キーボードレイアウトは
    # "0411:00000411" のような形式なので正規表現に一致しない)。CLSID の TSF 登録情報の
    # 説明文字列から "Google" を含むものを探す。32bit COM 登録の可能性があるため
    # WOW6432Node 側も見る。見つからなければ $null を返す (呼び出し側で best-effort に扱う)。
    param([string[]]$Tips)

    foreach ($tip in $Tips) {
        $m = [regex]::Match($tip, '^([0-9A-Fa-f]{4}):(\{[0-9A-Fa-f\-]+\})(\{[0-9A-Fa-f\-]+\})$')
        if (-not $m.Success) { continue }
        $langId  = $m.Groups[1].Value
        $clsid   = $m.Groups[2].Value
        $profile = $m.Groups[3].Value
        $candidatePaths = @(
            "HKLM:\SOFTWARE\Microsoft\CTF\TIP\$clsid"
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\CTF\TIP\$clsid"
        )
        foreach ($path in $candidatePaths) {
            # 説明文字列は TIP キー直下、または言語プロファイル配下の
            # 既定値 / Description 値のいずれかに入っている
            $keys = @(
                Get-Item -Path $path -ErrorAction SilentlyContinue
                Get-Item -Path "$path\LanguageProfile\0x0000$langId\$profile" -ErrorAction SilentlyContinue
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
    # Google 日本語入力を既定の入力方式にする。ブラウザ等と違い UserChoice の保護対象外で、
    # 公式コマンドレット (International モジュール) で正規にスクリプト化できる。
    # ただし Google 側の内部 CLSID をインストール後に動的に探す必要があり、インストール直後は
    # セッションに反映されず見つからないことがあるため best-effort (失敗時は警告のみ) とする。
    if ($env:CI) {
        return
    }
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
    Install-GuiApps
    Set-PowerToysSettings
    Open-DefaultAppsSettings
    Set-DefaultInputMethod
}

Main
