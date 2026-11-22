#!/usr/bin/env pwsh
# winget (Windows Package Manager) を使える状態にする。winget を使う setup_powershell.ps1 と apps.ps1 より先に実行する。
# winget は Windows 10 / 11 の App Installer に同梱されるので、登録が済んでいないときだけ登録する。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

function Install-WinGet {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step 'winget is already installed.'
        return
    }

    # App Installer は配置済みで、初回サインイン後の非同期な Store 登録が済んでいないだけのことがある。
    # 登録できなければ、後続の導入を飛ばしたまま run_once が実行済みにならないよう、スクリプトを失敗させて次の apply で再実行させる
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    }
    catch {
        throw "winget を使えません。Microsoft Store から App Installer を入れてから chezmoi apply を再実行してください: $($_.Exception.Message)"
    }
    # winget.exe の実行エイリアスは %LOCALAPPDATA%\Microsoft\WindowsApps に置かれるが、
    # 登録直後だと現在セッションの PATH に反映されていないことがあるため追記する
    $windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if (@($env:Path -split ';') -notcontains $windowsApps) {
        $env:Path = "$env:Path;$windowsApps"
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'App Installer を登録しましたが winget が見つかりません。設定の「アプリ実行エイリアス」で winget を有効にしてから chezmoi apply を再実行してください。'
    }
    Write-Step 'Registered existing App Installer (winget).'
}

Install-WinGet
