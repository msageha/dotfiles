#!/usr/bin/env pwsh
# install/windows/*.ps1 が共有する helper (install/lib.sh の Windows 版)。
# chezmoi の run_once_before_02_windows.ps1.tmpl が先頭で 1 回 include し、
# スクリプトを単体で実行するときは各スクリプト冒頭のガードがこのファイルを dot-source する。
# chezmoi の config (.chezmoi.toml.tmpl の [interpreters.ps1]) が実行ホストを Windows 標準搭載の
# Windows PowerShell 5.1 に固定しているため、5.1 互換の構文のみを使うこと (pwsh 専用の演算子・cmdlet は使わない)。
# 5.1 はネイティブコマンド (winget / claude 等の exe) の失敗を throw しないため、
# 呼び出し後は $LASTEXITCODE を明示的に確認する。

# Windows PowerShell 5.1 は Invoke-WebRequest / Expand-Archive のプログレスバー描画で
# 処理が極端に遅くなるため無効化する
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# StrictMode ではキー/値が無いときの $null へのプロパティ参照が throw するため、
# Get-ItemPropertyValue の失敗を「未設定 ($null)」として扱う
function Get-RegistryValueOrNull([string]$Path, [string]$Name) {
    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

$script:DotfilesLibLoaded = $true
