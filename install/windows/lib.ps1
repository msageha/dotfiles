#!/usr/bin/env pwsh
# install/windows/*.ps1 が共有する helper (install/lib.sh の Windows 版)。
# .chezmoi.toml.tmpl の [interpreters.ps1] が実行ホストを Windows PowerShell 5.1 に固定しているため、pwsh 専用の演算子・cmdlet は使わない。
# 5.1 はネイティブコマンド (winget / claude 等) の失敗を throw しないため、呼び出し後に $LASTEXITCODE を確かめる。

# Windows PowerShell 5.1 は Invoke-WebRequest / Expand-Archive のプログレスバーの描画で極端に遅くなる
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# StrictMode ではキーや値が無いときの $null へのプロパティ参照が throw するため、取得の失敗を未設定 ($null) として返す
function Get-RegistryValueOrNull([string]$Path, [string]$Name) {
    try {
        return Get-ItemPropertyValue -Path $Path -Name $Name -ErrorAction Stop
    }
    catch {
        return $null
    }
}

$script:DotfilesLibLoaded = $true
