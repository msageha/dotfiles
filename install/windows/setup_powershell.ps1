#!/usr/bin/env pwsh
# Starship・SauceCodePro Nerd Font・PowerShell プロファイル・Windows Terminal の設定。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
# このファイルは BOM 無しの UTF-8 で、5.1 は日本語を ANSI として読み構文が壊れるため、単体で実行するときは pwsh を使う
# (`pwsh -File install/windows/setup_powershell.ps1`)。chezmoi 経由ではテンプレートが BOM を付ける。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

# winget で入れたコマンドを現在の session の PATH に反映する。
# 置き換えるとプロセス固有の追加分 (CI が GITHUB_PATH で足したパス等) が落ちるため、足りない分だけ追記する
function Update-SessionPath {
    $machine = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user    = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $current = @($env:Path -split ';' | Where-Object { $_ })
    $added   = @((($machine, $user) -join ';') -split ';' | Where-Object { $_ -and ($current -notcontains $_) })
    $env:Path = ($current + $added) -join ';'
}

# home/.chezmoitemplates/external-fonts.toml の nerd-fonts と同じ版にする (renovate が両方を更新する)
$NerdFontsVersion = 'v3.5.1'
$WindowsTerminalFont = 'SauceCodePro NF'
$WindowsTerminalColorScheme = 'Dracula'

# chezmoi 経由では一時ファイルから実行され $PSScriptRoot がリポジトリ外を指すため、
# chezmoi が渡す CHEZMOI_SOURCE_DIR (= <repo>/home) を優先する。
$RepoRoot = if ($env:CHEZMOI_SOURCE_DIR) {
    (Resolve-Path (Join-Path $env:CHEZMOI_SOURCE_DIR '..')).Path
} else {
    (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}
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

# PowerShell プロファイルへ書き込む管理ブロック (キーがマーカー名になる)
$ProfileBlocks = [ordered]@{
    # UTF-8 出力は共通にし、prompt と PSReadLine は人間の対話 shell に限定する。
    # Agent / human の判定は ~/.config/shell/env.sh と同じで、どちらでもない非対話 shell には環境変数を足さない。
    starship = @(
        '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8'
        '$OutputEncoding           = [System.Text.Encoding]::UTF8'
        '$dotfilesAgent = switch ($env:DOTFILES_SHELL_MODE) {'
        '    "agent" { $true }'
        '    "human" { $false }'
        '    default {'
        '        @("AI_AGENT", "CLAUDECODE", "CODEX_CI", "CODEX_SANDBOX", "GEMINI_CLI", "CURSOR_AGENT", "ANTIGRAVITY_AGENT" |'
        '            Where-Object { [Environment]::GetEnvironmentVariable($_) }).Count -gt 0 -or $env:GROK_AGENT -eq "1"'
        '    }'
        '}'
        '$dotfilesShellArgs = [Environment]::GetCommandLineArgs()'
        '$dotfilesBatch = $dotfilesShellArgs -match "^-(Command|c|File|f|EncodedCommand|e|ec|CommandWithArgs|cwa)$|\.ps1$"'
        '$dotfilesHumanInteractive = -not $dotfilesAgent -and'
        '    -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected -and'
        '    -not ($dotfilesShellArgs -match "^-NonI") -and'
        '    (-not $dotfilesBatch -or $dotfilesShellArgs -match "^-NoE")'
        # .chezmoidata.toml の agent_env の Windows 版。PATH に false / cat が無いため editor と pager は PowerShell で代替し、
        # 5.1 は空の環境変数を保持できないため pager は入力をそのまま出力するコマンドにする。
        # GIT_* と GH_PAGER は POSIX と同じ値でよい (Git for Windows は同梱の usr\bin を PATH に足し、git / gh は pager の cat を「pager なし」として扱う)
        '$dotfilesNoEditor = "powershell.exe -NoProfile -NonInteractive -Command exit 1"'
        '$dotfilesPassthroughPager = ''powershell.exe -NoProfile -NonInteractive -Command "[Console]::OpenStandardInput().CopyTo([Console]::OpenStandardOutput())"'''
        '$dotfilesAgentEnv = [ordered]@{'
        '    EDITOR              = $dotfilesNoEditor'
        '    VISUAL              = $dotfilesNoEditor'
        '    GIT_EDITOR          = "true"'
        '    GIT_SEQUENCE_EDITOR = "false"'
        '    PAGER               = $dotfilesPassthroughPager'
        '    MANPAGER            = $dotfilesPassthroughPager'
        '    AWS_PAGER           = $dotfilesPassthroughPager'
        '    GIT_PAGER           = "cat"'
        '    GH_PAGER            = "cat"'
        '    NO_COLOR            = "1"'
        '    GIT_TERMINAL_PROMPT = "0"'
        '    GH_PROMPT_DISABLED  = "1"'
        '    AWS_CLI_AUTO_PROMPT = "off"'
        '}'
        'if ($dotfilesAgent) {'
        '    foreach ($name in $dotfilesAgentEnv.Keys) { Set-Item "Env:$name" $dotfilesAgentEnv[$name] }'
        '} elseif ($env:DOTFILES_SHELL_MODE -eq "human") {'
        '    foreach ($name in $dotfilesAgentEnv.Keys) { Remove-Item "Env:$name" -ErrorAction SilentlyContinue }'
        '}'
        'if ($dotfilesHumanInteractive -and (Get-Command starship -ErrorAction SilentlyContinue)) {'
        '    Invoke-Expression (&starship init powershell)'
        '}'
    )
    # PSReadLine の Dracula 配色 (https://github.com/dracula/powershell の theme/dracula-prompt-configuration.ps1 の
    # PSReadLine 部分。プロンプトは starship が描くため posh-git の部分は取り込まない)
    dracula = @(
        'if ($dotfilesHumanInteractive -and (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue)) {'
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

function Set-ProfileManagedBlock([string]$ProfilePath, [string]$Name, [string[]]$Lines) {
    $begin = "# >>> chezmoi $Name (managed) >>>"
    $end   = "# <<< chezmoi $Name (managed) <<<"
    $block = (@($begin) + $Lines + @($end)) -join "`n"

    if (-not (Test-Path $ProfilePath)) {
        New-Item -ItemType File -Path $ProfilePath -Force | Out-Null
    }
    $current = Get-Content -Path $ProfilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $current) { $current = '' }

    $pattern = [regex]::Escape($begin) + '[\s\S]*?' + [regex]::Escape($end)
    if ($current -match $pattern) {
        # .NET regex の置換文字列で特別な意味を持つのは $ だけなので、$$ へエスケープして literal に置換する
        $updated = [regex]::Replace($current, $pattern, $block.Replace('$', '$$'))
    }
    else {
        $sep = if ($current.TrimEnd().Length -gt 0) { "`n`n" } else { '' }
        $updated = $current.TrimEnd() + $sep + $block + "`n"
    }
    # 5.1 の -Encoding utf8 は BOM を付けるため、.NET API で BOM 無し UTF-8 を書く。
    [System.IO.File]::WriteAllText($ProfilePath, $updated, [System.Text.UTF8Encoding]::new($false))
    Write-Step "Configured PowerShell profile -> $ProfilePath"
}

function Set-PowerShellProfile {
    # $PROFILE は 5.1 と pwsh でパスが異なるため、どちらを使っても効くよう両方に書く。
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $profilePaths = @(
        (Join-Path $documents 'WindowsPowerShell\Microsoft.PowerShell_profile.ps1') # Windows PowerShell 5.1
        (Join-Path $documents 'PowerShell\Microsoft.PowerShell_profile.ps1')        # PowerShell 7+ (pwsh)
    )
    foreach ($profilePath in $profilePaths) {
        foreach ($name in $ProfileBlocks.Keys) {
            Set-ProfileManagedBlock $profilePath $name $ProfileBlocks[$name]
        }
    }
}

function Set-WindowsTerminalDraculaFragment {
    # https://github.com/dracula/windows-terminal の dracula.json の写し (公式スクリプトは実行時にダウンロードするため使わない)。
    # fragment からは profiles.defaults を変えられないため、既定の配色は Set-WindowsTerminalDefaults が設定する
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
        # 5.1 の ConvertFrom-Json は JSONC の行コメントと末尾カンマを読めないため、除いてから解析する
        $clean = ($raw -split "`n" | Where-Object { $_ -notmatch '^\s*//' }) -join "`n"
        $clean = $clean -replace ',(\s*[}\]])', '$1'
        $cfg   = $clean | ConvertFrom-Json

        # 書き換えると JSONC のコメントが失われるため、設定済みなら書き換えない
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

        # 5.1 の -Encoding utf8 は BOM を付け、BOM 付き JSON を読めないパーサーがあるため .NET API で書く。
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
