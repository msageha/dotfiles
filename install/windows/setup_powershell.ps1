#!/usr/bin/env pwsh
# Windows 向けセットアップ: Starship + SauceCodePro Nerd Font + PowerShell プロファイル。
# 通常は chezmoi apply (home/.chezmoiscripts/run_once_before_02_windows.ps1.tmpl) から
# 自動実行される。chezmoi の config (.chezmoi.toml.tmpl の [interpreters.ps1]) で実行ホストを
# Windows 標準搭載の Windows PowerShell 5.1 に固定しているため、5.1 互換の
# 構文のみを使うこと (pwsh 専用の演算子・cmdlet は使わない)。
# 手動実行する場合は pwsh を使う:
#   pwsh -File install/windows/setup_powershell.ps1
# (このファイルは BOM 無し UTF-8 のため、Windows PowerShell 5.1 で直接実行すると
#  日本語コメントが ANSI として解釈され構文が壊れる。chezmoi 経由の実行では
#  .chezmoiscripts テンプレートが先頭に BOM を付与するため 5.1 でも問題ない)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 の Invoke-WebRequest / Expand-Archive はプログレスバー描画で
# 処理が極端に遅くなるため無効化する
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

# winget/Store でインストールしたコマンドを現在のセッションの PATH に反映する。
# 置換ではなく追記マージにする (置換するとプロセス固有の PATH 追加分、
# 例えば CI が GITHUB_PATH で注入したパスが落ちる)。
function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $current = @($env:Path -split ';' | Where-Object { $_ })
    $added   = @((($machine, $user) -join ';') -split ';' | Where-Object { $_ -and ($current -notcontains $_) })
    $env:Path = ($current + $added) -join ';'
}

# home/.chezmoiexternal.toml の nerd-fonts external (SourceCodePro.zip / NerdFontsSymbolsOnly.zip)
# のバージョンと揃える
$NerdFontsVersion = 'v3.4.0'
$WindowsTerminalFont = 'SauceCodePro NF'
$WindowsTerminalColorScheme = 'Dracula'

# chezmoi 経由の実行では一時ファイルにコピーされ $PSScriptRoot がリポジトリ外を指すため、
# 呼び出し元 (.chezmoiscripts) が設定する CHEZMOI_SOURCE_DIR を優先して使う。
$RepoRoot = if ($env:CHEZMOI_SOURCE_DIR) {
    (Resolve-Path (Join-Path $env:CHEZMOI_SOURCE_DIR '..')).Path
} else {
    (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
# リポジトリ内の starship.toml (chezmoi source) のパス
$StarshipSource = Join-Path $RepoRoot 'home\dot_config\starship.toml'

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
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Starship のインストールが終了コード $LASTEXITCODE で失敗しました。プロファイルの starship 初期化は次回のセットアップで有効になります。"
        return
    }
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
        # -UseBasicParsing: 5.1 は IE エンジン未初期化のクリーン環境だと
        # これ無しで失敗する (pwsh では既定動作なので無害)
        Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
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

function Set-ProfileManagedBlock([string]$ProfilePath, [string]$Begin, [string]$End, [string[]]$Lines) {
    # マーカーで囲んだ管理ブロックをプロファイルへ冪等に書き込む
    $block = (@($Begin) + $Lines + @($End)) -join "`n"

    if (-not (Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    }
    $current = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $current) { $current = '' }

    $pattern = [regex]::Escape($Begin) + '[\s\S]*?' + [regex]::Escape($End)
    if ($current -match $pattern) {
        # 置換テキスト内の $ や \ がパターンとして解釈されないよう MatchEvaluator で置換する
        $updated = [regex]::Replace($current, $pattern, { param($m) $block })
    }
    else {
        $sep = if ($current.TrimEnd().Length -gt 0) { "`n`n" } else { '' }
        $updated = $current.TrimEnd() + $sep + $block + "`n"
    }
    # -Encoding utf8 は Windows PowerShell 5.1 だと BOM 付きで書き出されるため、
    # pwsh/5.1 のどちらでも BOM 無し UTF-8 になるよう .NET API で明示的に書く。
    [System.IO.File]::WriteAllText($ProfilePath, $updated, [System.Text.UTF8Encoding]::new($false))
    Write-Step "Configured PowerShell profile -> $ProfilePath"
}

function Set-ProfileStarshipBlock([string]$ProfilePath) {
    # UTF-8 出力設定 (cp932 環境で starship のグリフが化けるのを防ぐ) と starship 初期化
    Set-ProfileManagedBlock $ProfilePath `
        '# >>> chezmoi starship (managed) >>>' `
        '# <<< chezmoi starship (managed) <<<' `
        @(
            '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
            '$OutputEncoding           = [System.Text.Encoding]::UTF8'
            'if (Get-Command starship -ErrorAction SilentlyContinue) {'
            '    Invoke-Expression (&starship init powershell)'
            '}'
        )
}

function Set-ProfileDraculaBlock([string]$ProfilePath) {
    # PSReadLine トークン色の Dracula テーマ (https://github.com/dracula/powershell の
    # theme/dracula-prompt-configuration.ps1 から PSReadLine 部分のみ取り込む。
    # posh-git ベースのプロンプト設定部分はプロンプトを starship が描画するため対象外)
    Set-ProfileManagedBlock $ProfilePath `
        '# >>> chezmoi dracula (managed) >>>' `
        '# <<< chezmoi dracula (managed) <<<' `
        @(
            'if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {'
            '    Set-PSReadLineOption -Colors @{'
            '        "Command"   = [ConsoleColor]::Green'
            '        "Parameter" = [ConsoleColor]::Gray'
            '        "Operator"  = [ConsoleColor]::Magenta'
            '        "Variable"  = [ConsoleColor]::White'
            '        "String"    = [ConsoleColor]::Yellow'
            '        "Number"    = [ConsoleColor]::Blue'
            '        "Type"      = [ConsoleColor]::Cyan'
            '        "Comment"   = [ConsoleColor]::DarkCyan'
            '    }'
            '}'
        )
}

function Set-PowerShellProfile {
    # $PROFILE は実行ホスト依存 (5.1 と pwsh でパスが異なる) のため、ユーザーが
    # どちらのシェルを使っても設定が有効になるよう両方のプロファイルに書く。
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $profilePaths = @(
        (Join-Path $documents 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1') # Windows PowerShell 5.1
        (Join-Path $documents 'PowerShell\Microsoft.PowerShell_profile.ps1')        # PowerShell 7+ (pwsh)
    )
    foreach ($profilePath in $profilePaths) {
        Set-ProfileStarshipBlock $profilePath
        Set-ProfileDraculaBlock $profilePath
    }
}

function Set-WindowsTerminalDraculaFragment {
    # Dracula カラースキームを Windows Terminal の JSON Fragment として配置する
    # (https://github.com/dracula/windows-terminal の dracula.json の静的コピー。
    # 公式の Add-TerminalProfileDracula.ps1 は実行時ダウンロード方式のため使わない)。
    # fragment がサポートするのは schemes の追加と GUID 指定のプロファイル更新のみで、
    # profiles.defaults は対象外のため、既定スキームの適用は Set-WindowsTerminalDefaults が行う
    $fragmentPath = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows Terminal\Fragments\chezmoi\dracula.json'
    $fragmentJson = @'
{
  "schemes": [
    {
      "name": "Dracula",
      "cursorColor": "#F8F8F2",
      "selectionBackground": "#44475A",
      "background": "#282A36",
      "foreground": "#F8F8F2",
      "black": "#21222C",
      "blue": "#BD93F9",
      "cyan": "#8BE9FD",
      "green": "#50FA7B",
      "purple": "#FF79C6",
      "red": "#FF5555",
      "white": "#F8F8F2",
      "yellow": "#F1FA8C",
      "brightBlack": "#6272A4",
      "brightBlue": "#D6ACFF",
      "brightCyan": "#A4FFFF",
      "brightGreen": "#69FF94",
      "brightPurple": "#FF92DF",
      "brightRed": "#FF6E6E",
      "brightWhite": "#FFFFFF",
      "brightYellow": "#FFFFA5"
    }
  ]
}
'@
    New-Item -ItemType Directory -Force -Path (Split-Path $fragmentPath) | Out-Null
    # Windows Terminal は BOM 無し UTF-8 の fragment を要求する
    [System.IO.File]::WriteAllText($fragmentPath, $fragmentJson, [System.Text.UTF8Encoding]::new($false))
    Write-Step "Installed Windows Terminal Dracula fragment -> $fragmentPath"
}

function Set-WindowsTerminalDefaults {
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
        $raw   = Get-Content -Path $path -Raw
        # JSONC の行コメントと trailing comma を除去してから解析する
        $clean = ($raw -split "`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
        $clean = $clean -replace ',(\s*[}\]])', '$1'
        $cfg   = $clean | ConvertFrom-Json

        # 設定済みなら書き換えない (再書き込みは下記のとおりコメントを失うため)
        $face = $null
        $scheme = $null
        if ($cfg.profiles.PSObject.Properties['defaults']) {
            if ($cfg.profiles.defaults.PSObject.Properties['font'] -and
                $cfg.profiles.defaults.font.PSObject.Properties['face']) {
                $face = $cfg.profiles.defaults.font.face
            }
            if ($cfg.profiles.defaults.PSObject.Properties['colorScheme']) {
                $scheme = $cfg.profiles.defaults.colorScheme
            }
        }
        if (($face -eq $WindowsTerminalFont) -and ($scheme -eq $WindowsTerminalColorScheme)) {
            Write-Step "Windows Terminal font/colorScheme are already $WindowsTerminalFont / $WindowsTerminalColorScheme. Skipping"
            return
        }

        Copy-Item $path "$path.bak" -Force
        if (-not $cfg.profiles.PSObject.Properties['defaults']) {
            $cfg.profiles | Add-Member -NotePropertyName defaults -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        if (-not $cfg.profiles.defaults.PSObject.Properties['font']) {
            $cfg.profiles.defaults | Add-Member -NotePropertyName font -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        $cfg.profiles.defaults.font | Add-Member -NotePropertyName face -NotePropertyValue $WindowsTerminalFont -Force
        # colorScheme 本体 (Dracula) は Set-WindowsTerminalDraculaFragment が fragment として供給する
        $cfg.profiles.defaults | Add-Member -NotePropertyName colorScheme -NotePropertyValue $WindowsTerminalColorScheme -Force

        # -Encoding utf8 は Windows PowerShell 5.1 だと BOM 付きで書き出され、
        # BOM 付き JSON を読めないパーサーがあるため .NET API で BOM 無し UTF-8 にする。
        $json = $cfg | ConvertTo-Json -Depth 32
        [System.IO.File]::WriteAllText($path, $json, [System.Text.UTF8Encoding]::new($false))
        Write-Step "Set Windows Terminal defaults -> font: $WindowsTerminalFont, colorScheme: $WindowsTerminalColorScheme"
        Write-Warn "settings.json は再シリアライズされるため JSONC コメントは保持されません (元ファイル: $path.bak)"
    }
    catch {
        Write-Warn "Windows Terminal の設定更新に失敗しました: $($_.Exception.Message)"
        Write-Warn "手動で font.face / colorScheme を設定してください (書き換え後に失敗した場合はバックアップ $path.bak から復元できます)。"
    }
}

function Main {
    Install-Starship
    Install-NerdFont
    Install-StarshipConfig
    Set-PowerShellProfile
    Set-WindowsTerminalDraculaFragment
    Set-WindowsTerminalDefaults
    Write-Step 'Done. 新しい PowerShell を開き直すと反映されます。'
}

Main
