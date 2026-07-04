#!/usr/bin/env pwsh
# winget (Windows Package Manager) のブートストラップ。
# Windows Server 2022 / Windows Sandbox など Microsoft Store が無い環境には winget が
# 同梱されないため、Microsoft 公式手順 (PSGallery の Microsoft.WinGet.Client モジュールの
# Repair-WinGetPackageManager) で導入する。後続の setup_powershell.ps1 (Starship) と
# apps.ps1 (GUI アプリ) が winget を前提にするので、それらより先に実行すること。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 はプログレスバー描画で処理が極端に遅くなるため無効化する
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

function Update-WinGetSessionPath {
    # winget.exe の実行エイリアスは %LOCALAPPDATA%\Microsoft\WindowsApps に置かれるが、
    # 登録直後だと現在セッションの PATH に反映されていないことがあるため追記する
    $windowsApps = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps'
    if (@($env:Path -split ';') -notcontains $windowsApps) {
        $env:Path = "$env:Path;$windowsApps"
    }
}

function Register-ExistingAppInstaller {
    # App Installer は配置済みだが、初回サインイン後の非同期な Store 登録がまだ
    # 済んでいないだけのケースがある。登録はネットワーク不要で数秒で終わるため先に試す
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
        Update-WinGetSessionPath
    }
    catch {
        # App Installer 自体が無い環境 (Windows Server 等) では失敗する。
        # その場合は呼び出し元が PSGallery 経由のブートストラップに進む
    }
}

function Install-WinGetViaPSGallery {
    Write-Step 'Installing winget via Microsoft.WinGet.Client (Repair-WinGetPackageManager)...'
    try {
        # Windows PowerShell 5.1 の既定では PSGallery への接続に TLS 1.2 が
        # 使われないことがあるため明示的に有効化する (現在セッションのみ)
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser

        # 管理者なら全ユーザーへ登録する (Windows Server では通常こちら)
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if ($isAdmin) {
            Repair-WinGetPackageManager -AllUsers | Out-Null
        }
        else {
            Repair-WinGetPackageManager | Out-Null
        }
        Update-WinGetSessionPath
    }
    catch {
        Write-Warn "winget のブートストラップに失敗しました: $($_.Exception.Message)"
    }
}

function Install-WinGet {
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step 'winget is already installed.'
        return
    }

    Register-ExistingAppInstaller
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step 'Registered existing App Installer (winget).'
        return
    }

    Install-WinGetViaPSGallery
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Step 'winget was installed successfully.'
    }
    else {
        # winget 依存のステップ (Starship / GUI アプリ) は各スクリプト側が
        # 警告してスキップするため、apply 全体はここで止めない
        Write-Warn 'winget を導入できませんでした。Windows Server 2019 以前は winget 非対応です。'
    }
}

Install-WinGet
