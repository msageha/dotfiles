#!/usr/bin/env pwsh
# winget (Windows Package Manager) のブートストラップ。
# Windows Server 2022 / Windows Sandbox など Microsoft Store が無い環境には winget が
# 同梱されないため、GitHub リリースの App Installer パッケージから導入する。後続の
# setup_powershell.ps1 (Starship) と apps.ps1 (GUI アプリ) が winget を前提にするので、
# それらより先に実行すること。
# Microsoft 公式手順の Repair-WinGetPackageManager (Microsoft.WinGet.Client) は
# Windows Server 2022 だと WinRT 相互運用層の初期化に失敗し
# "ManagementDeploymentCommand の型初期化子が例外をスロー" で落ちる既知問題があるため
# (microsoft/winget-cli#4502)、最終フォールバックとしてのみ使う。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 はプログレスバー描画で処理が極端に遅くなるため無効化する
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

function Test-WinGetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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
        # その場合は呼び出し元が GitHub リリースからの導入に進む
    }
}

function Install-WinGetFromGitHubRelease {
    # GitHub リリースから App Installer 本体・依存パッケージ (VCLibs / UI.Xaml)・
    # ライセンス XML を取得して導入する。Windows Server 2022 で実績のある方式
    # (Add-AppxPackage だけだと Server では "No applicable app licenses" になるため、
    # 管理者ではライセンス XML を添えて Add-AppxProvisionedPackage で機械全体に配置する)
    Write-Step 'Installing winget from the GitHub release of winget-cli...'

    $arch = switch ($env:PROCESSOR_ARCHITECTURE) {
        'ARM64' { 'arm64' }
        default { 'x64' }
    }

    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("winget-bootstrap-" + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $tmp | Out-Null
    try {
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -UseBasicParsing
        $assets = @{
            bundle  = ($release.assets | Where-Object { $_.name -like '*.msixbundle' } | Select-Object -First 1)
            deps    = ($release.assets | Where-Object { $_.name -eq 'DesktopAppInstaller_Dependencies.zip' } | Select-Object -First 1)
            license = ($release.assets | Where-Object { $_.name -like '*_License1.xml' } | Select-Object -First 1)
        }
        if (-not ($assets.bundle -and $assets.deps -and $assets.license)) {
            Write-Warn 'winget-cli リリースに想定するアセットが見つかりませんでした。'
            return
        }

        $bundlePath  = Join-Path $tmp $assets.bundle.name
        $depsZip     = Join-Path $tmp $assets.deps.name
        $licensePath = Join-Path $tmp $assets.license.name
        # -UseBasicParsing: 5.1 は IE エンジン未初期化のクリーン環境だとこれ無しで失敗する
        Invoke-WebRequest -Uri $assets.bundle.browser_download_url -OutFile $bundlePath -UseBasicParsing
        Invoke-WebRequest -Uri $assets.deps.browser_download_url -OutFile $depsZip -UseBasicParsing
        Invoke-WebRequest -Uri $assets.license.browser_download_url -OutFile $licensePath -UseBasicParsing

        Expand-Archive -Path $depsZip -DestinationPath (Join-Path $tmp 'deps') -Force
        $depPaths = @(Get-ChildItem -Path (Join-Path $tmp "deps\$arch") -Filter '*.appx' | ForEach-Object { $_.FullName })

        if (Test-IsAdmin) {
            Add-AppxProvisionedPackage -Online -PackagePath $bundlePath `
                -DependencyPackagePath $depPaths -LicensePath $licensePath | Out-Null
            # 配置 (provision) は次回サインイン時に登録される。現在のユーザーへ即時反映する
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        }
        else {
            # 非管理者はユーザー単位で導入する。Windows Server ではライセンス制約で
            # 失敗することがある (その場合は管理者 PowerShell で再実行する)
            foreach ($dep in $depPaths) {
                Add-AppxPackage -Path $dep
            }
            Add-AppxPackage -Path $bundlePath
        }
        Update-WinGetSessionPath
    }
    catch {
        Write-Warn "GitHub リリースからの winget 導入に失敗しました: $($_.Exception.Message)"
    }
    finally {
        Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Install-WinGetViaPSGallery {
    # Microsoft 公式手順のフォールバック。Windows Server 2022 では前述の既知問題で
    # 失敗するため、GitHub リリース方式が失敗した場合の最終手段としてのみ呼ぶ
    Write-Step 'Installing winget via Microsoft.WinGet.Client (Repair-WinGetPackageManager)...'
    try {
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope CurrentUser
        if (Test-IsAdmin) {
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
    if (Test-WinGetAvailable) {
        Write-Step 'winget is already installed.'
        return
    }

    Register-ExistingAppInstaller
    if (Test-WinGetAvailable) {
        Write-Step 'Registered existing App Installer (winget).'
        return
    }

    # Windows PowerShell 5.1 の既定では GitHub / PSGallery への接続に TLS 1.2 が
    # 使われないことがあるため明示的に有効化する (現在セッションのみ)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    Install-WinGetFromGitHubRelease
    if (Test-WinGetAvailable) {
        Write-Step 'winget was installed successfully.'
        return
    }

    Install-WinGetViaPSGallery
    if (Test-WinGetAvailable) {
        Write-Step 'winget was installed successfully.'
    }
    else {
        # winget 依存のステップ (Starship / GUI アプリ) は各スクリプト側が
        # 警告してスキップするため、apply 全体はここで止めない
        Write-Warn 'winget を導入できませんでした。Windows Server 2019 以前は winget 非対応です。'
    }
}

Install-WinGet
