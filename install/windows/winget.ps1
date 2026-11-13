#!/usr/bin/env pwsh
# winget (Windows Package Manager) を導入する。winget を使う setup_powershell.ps1 と apps.ps1 より先に実行する。
# Microsoft Store が無い環境 (Windows Server 2022・Windows Sandbox 等) には winget が同梱されないため、GitHub リリースの App Installer から入れる。
# 公式手順の Repair-WinGetPackageManager は Windows Server 2022 で WinRT の初期化に失敗する (microsoft/winget-cli#4502) ため、最後の手段にする。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

function Test-WinGetAvailable {
    return [bool](Get-Command winget -ErrorAction SilentlyContinue)
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
    # App Installer は配置済みで、初回サインイン後の非同期な Store 登録が済んでいないだけのことがある。
    # 登録はネットワーク不要ですぐ終わるので先に試す
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
    }
    catch {
        # App Installer 自体が無い環境 (Windows Server 等) では失敗するが、呼び出し元が GitHub リリースからの導入に進むので何も出さない
        return
    }
    Update-WinGetSessionPath
}

function Install-WinGetFromGitHubRelease {
    # Windows Server では Add-AppxPackage だけだと "No applicable app licenses" になるため、
    # 管理者ならライセンス XML を添えて Add-AppxProvisionedPackage でマシン全体に配置する
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
        # 5.1 は IE エンジンが未初期化の環境では -UseBasicParsing が無いと失敗する
        Invoke-WebRequest -Uri $assets.bundle.browser_download_url -OutFile $bundlePath -UseBasicParsing
        Invoke-WebRequest -Uri $assets.deps.browser_download_url -OutFile $depsZip -UseBasicParsing
        Invoke-WebRequest -Uri $assets.license.browser_download_url -OutFile $licensePath -UseBasicParsing

        Expand-Archive -Path $depsZip -DestinationPath (Join-Path $tmp 'deps') -Force
        $depPaths = @(Get-ChildItem -Path (Join-Path $tmp "deps\$arch") -Filter '*.appx' | ForEach-Object { $_.FullName })

        if (Test-IsAdmin) {
            Add-AppxProvisionedPackage -Online -PackagePath $bundlePath `
                -DependencyPackagePath $depPaths -LicensePath $licensePath | Out-Null
            # provision したパッケージは次回のサインインで登録されるので、現在のユーザーにはここで登録する
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        }
        else {
            # Windows Server ではライセンスの制約で失敗することがある (その場合は管理者の PowerShell で再実行する)
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

    # Windows PowerShell 5.1 の既定では GitHub / PSGallery への接続に TLS 1.2 が使われないことがある
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
        # winget を使う後続のスクリプトは警告してスキップするため、apply 全体は止めない
        Write-Warn 'winget を導入できませんでした。Windows Server 2019 以前は winget 非対応です。'
    }
}

Install-WinGet
