#!/usr/bin/env pwsh
#Requires -Version 7.0
# Windows 向けセットアップ: Starship + SauceCodePro Nerd Font + PowerShell プロファイル。
# PowerShell 7 (pwsh) で実行すること: pwsh -File install/windows/setup.ps1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# install/common/fonts.sh の NERD_FONTS_VERSION と揃える
$NerdFontsVersion = 'v3.4.0'
$WindowsTerminalFont = 'SauceCodePro NF'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

# リポジトリ内の starship.toml (chezmoi source) のパス
$RepoRoot       = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$StarshipSource = Join-Path $RepoRoot 'home\dot_config\starship.toml'

# winget/Store でインストールしたコマンドを現在のセッションの PATH に反映する
function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = ($machine, $user | Where-Object { $_ }) -join ';'
}

function Install-Starship {
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        Write-Step 'Starship is already installed.'
        return
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warn 'winget が見つかりません。Starship を手動で導入してください (scoop install starship / cargo install starship)。'
        return
    }
    Write-Step 'Installing Starship via winget...'
    winget install --id Starship.Starship --exact --source winget `
        --accept-package-agreements --accept-source-agreements
    Update-SessionPath
}

function Install-NerdFont {
    $fontDest = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
    if (Get-ChildItem -Path $fontDest -Filter 'SauceCodePro*' -ErrorAction SilentlyContinue) {
        Write-Step 'SauceCodePro Nerd Font already installed.'
        return
    }
    Write-Step 'Installing SauceCodePro Nerd Font (per-user)...'

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("scp-nerd-" + [System.Guid]::NewGuid().ToString('N'))
    $zip = "$tmp.zip"
    $url = "https://github.com/ryanoasis/nerd-fonts/releases/download/$NerdFontsVersion/SourceCodePro.zip"
    try {
        Invoke-WebRequest -Uri $url -OutFile $zip
        Expand-Archive -Path $zip -DestinationPath $tmp -Force

        New-Item -ItemType Directory -Force -Path $fontDest | Out-Null
        $reg = 'HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts'
        Get-ChildItem -Path $tmp -Filter '*.ttf' -Recurse | ForEach-Object {
            Copy-Item $_.FullName -Destination $fontDest -Force
            New-ItemProperty -Path $reg -Name "$($_.BaseName) (TrueType)" `
                -Value (Join-Path $fontDest $_.Name) -PropertyType String -Force | Out-Null
        }
    }
    finally {
        Remove-Item -Path $zip, $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-StarshipConfig {
    if (-not (Test-Path $StarshipSource)) {
        Write-Warn "starship.toml が見つかりません: $StarshipSource"
        return
    }
    $destDir = Join-Path $env:USERPROFILE '.config'
    $dest    = Join-Path $destDir 'starship.toml'
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    # Nerd Font グリフを壊さないよう、変換せずバイト忠実にコピーする
    Copy-Item -Path $StarshipSource -Destination $dest -Force
    Write-Step "Installed starship.toml -> $dest"
}

function Set-PowerShellProfile {
    # UTF-8 出力設定 (cp932 環境で starship のグリフが化けるのを防ぐ) と
    # starship 初期化を、マーカーで囲んだ管理ブロックとして冪等に書き込む。
    $begin = '# >>> chezmoi starship (managed) >>>'
    $end   = '# <<< chezmoi starship (managed) <<<'
    $block = @(
        $begin
        '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
        '$OutputEncoding           = [System.Text.Encoding]::UTF8'
        'Invoke-Expression (&starship init powershell)'
        $end
    ) -join "`n"

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }
    $current = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue
    if ($null -eq $current) { $current = '' }

    $pattern = [regex]::Escape($begin) + '[\s\S]*?' + [regex]::Escape($end)
    if ($current -match $pattern) {
        # 置換テキスト内の $ や \ がパターンとして解釈されないよう MatchEvaluator で置換する
        $updated = [regex]::Replace($current, $pattern, { param($m) $block })
    }
    else {
        $sep = if ($current.TrimEnd().Length -gt 0) { "`n`n" } else { '' }
        $updated = $current.TrimEnd() + $sep + $block + "`n"
    }
    Set-Content -Path $PROFILE -Value $updated -Encoding utf8
    Write-Step "Configured PowerShell profile -> $PROFILE"
}

function Set-WindowsTerminalFont {
    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\settings.json')
    )
    $path = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $path) {
        Write-Warn 'Windows Terminal の settings.json が見つかりません (SSH 利用なら不要)。スキップします。'
        return
    }
    try {
        Copy-Item $path "$path.bak" -Force
        $raw   = Get-Content -Path $path -Raw
        # JSONC の行コメントを除去してから解析する
        $clean = ($raw -split "`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
        $cfg   = $clean | ConvertFrom-Json

        if (-not $cfg.profiles.PSObject.Properties['defaults']) {
            $cfg.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        if (-not $cfg.profiles.defaults.PSObject.Properties['font']) {
            $cfg.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        $cfg.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue $WindowsTerminalFont -Force

        $cfg | ConvertTo-Json -Depth 32 | Set-Content -Path $path -Encoding utf8
        Write-Step "Set Windows Terminal font -> $WindowsTerminalFont"
    }
    catch {
        Write-Warn "Windows Terminal の設定更新に失敗しました: $($_.Exception.Message)"
        Write-Warn "バックアップ ($path.bak) から復元し、手動で font.face を設定してください。"
    }
}

function Main {
    Install-Starship
    Install-NerdFont
    Install-StarshipConfig
    Set-PowerShellProfile
    Set-WindowsTerminalFont
    Write-Step 'Done. 新しい PowerShell を開き直すと反映されます。'
}

Main
