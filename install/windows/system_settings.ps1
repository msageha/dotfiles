#!/usr/bin/env pwsh
# Windows のシステム設定 (エクスプローラー・壁紙)。
# mac (install/macos/system_settings.sh) / ubuntu (install/ubuntu/system_settings.sh) に相当する。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Windows PowerShell 5.1 の Invoke-WebRequest はプログレスバー描画で
# ダウンロードが極端に遅くなるため無効化する
$ProgressPreference = 'SilentlyContinue'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

function Set-ExplorerSettings {
    Write-Step 'エクスプローラーの設定を行っています...'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    New-ItemProperty -Path $advanced -Name 'Hidden' -Value 1 -PropertyType DWord -Force | Out-Null        # 隠しファイルを表示
    New-ItemProperty -Path $advanced -Name 'HideFileExt' -Value 0 -PropertyType DWord -Force | Out-Null   # ファイルの拡張子を表示
    New-ItemProperty -Path $advanced -Name 'ShowStatusBar' -Value 1 -PropertyType DWord -Force | Out-Null # ステータスバーを表示
    New-ItemProperty -Path $advanced -Name 'LaunchTo' -Value 1 -PropertyType DWord -Force | Out-Null      # 起動時にクイックアクセスではなく PC を表示
}

function Set-WallpaperSettings {
    Write-Step '壁紙の設定を行っています...'
    $picturesDir = Join-Path $env:USERPROFILE 'Pictures'
    New-Item -ItemType Directory -Force -Path $picturesDir | Out-Null
    $wallpaperPath = Join-Path $picturesDir 'wallpaper.png'

    # 取得失敗時に壊れた本文を壁紙にしないよう、失敗したらここで打ち切ってスキップする
    try {
        # -UseBasicParsing: 5.1 は IE エンジン未初期化のクリーン環境だと
        # これ無しで失敗する (pwsh では既定動作なので無害)
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/dracula/wallpaper/master/first-collection/windows.png' -OutFile $wallpaperPath -UseBasicParsing
    }
    catch {
        Write-Warn "壁紙のダウンロードに失敗しました。スキップします: $($_.Exception.Message)"
        return
    }

    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $wallpaperPath
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name WallpaperStyle -Value '10' # 10 = Fill
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name TileWallpaper -Value '0'

    # レジストリの更新だけでは反映されないため SystemParametersInfo で即時反映させる。
    # 同一セッションで複数回読み込まれても再定義エラーにならないよう -ErrorAction で無視する。
    Add-Type -ErrorAction SilentlyContinue @'
using System;
using System.Runtime.InteropServices;
public class ChezmoiWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
    # SPI_SETDESKWALLPAPER = 0x14, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE = 3
    [ChezmoiWallpaper]::SystemParametersInfo(0x14, 0, $wallpaperPath, 3) | Out-Null
}

function Set-TaskbarSettings {
    Write-Step 'タスクバー・システムトレイの設定を行っています...'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $search = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    $feeds = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds'

    New-ItemProperty -Path $search -Name 'SearchboxTaskbarMode' -Value 0 -PropertyType DWord -Force | Out-Null # 検索ボックスを非表示

    New-ItemProperty -Path $advanced -Name 'TaskbarDa' -Value 0 -PropertyType DWord -Force | Out-Null # ウィジェットを非表示 (Windows 11)
    New-Item -Path $feeds -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $feeds -Name 'ShellFeedsTaskbarViewMode' -Value 2 -PropertyType DWord -Force | Out-Null # ニュースと関心事項を非表示 (Windows 10)

    New-ItemProperty -Path $advanced -Name 'TaskbarMn' -Value 0 -PropertyType DWord -Force | Out-Null         # Chat アイコンを非表示
    New-ItemProperty -Path $advanced -Name 'ShowCopilotButton' -Value 0 -PropertyType DWord -Force | Out-Null # Copilot アイコンを非表示

    New-ItemProperty -Path $advanced -Name 'IsBatteryPercentageEnabled' -Value 1 -PropertyType DWord -Force | Out-Null # バッテリー残量%を表示
    New-ItemProperty -Path $advanced -Name 'ShowSecondsInSystemClock' -Value 1 -PropertyType DWord -Force | Out-Null   # 時計に秒を表示
}

function Set-PowerSettings {
    Write-Step '電源設定 (画面オフ・スリープ) を行っています...'
    if (-not (Get-Command powercfg -ErrorAction SilentlyContinue)) {
        Write-Warn 'powercfg が見つかりません。電源設定をスキップします。'
        return
    }
    # 画面オフ 5 分・スリープ 15 分 (AC 電源/バッテリー共通)。値は分単位。
    powercfg /change monitor-timeout-ac 5
    powercfg /change monitor-timeout-dc 5
    powercfg /change standby-timeout-ac 15
    powercfg /change standby-timeout-dc 15
}

function Set-KeyboardSettings {
    Write-Step 'キーボードの設定を行っています...'
    $keyboard = 'HKCU:\Control Panel\Keyboard'
    New-ItemProperty -Path $keyboard -Name 'KeyboardDelay' -Value '0' -PropertyType String -Force | Out-Null  # リピート開始までの時間を最短に
    New-ItemProperty -Path $keyboard -Name 'KeyboardSpeed' -Value '31' -PropertyType String -Force | Out-Null # リピート速度を最速に
}

function Enable-DeveloperMode {
    # シンボリックリンク作成等に管理者権限が不要になるなど dotfiles/chezmoi の運用と相性が良い。
    # HKLM への書き込みが必要なため、既に有効なら何もせず、未昇格なら UAC 昇格して 1 回だけ設定する
    # (毎回 UAC ダイアログが出ると煩わしいため、まず現在値を読み取って判定する)。
    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock'
    $current = (Get-ItemProperty -Path $path -Name 'AllowDevelopmentWithoutDevLicense' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
    if ($current -eq 1) {
        Write-Step '開発者モードは既に有効なため、スキップします。'
        return
    }

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($isAdmin) {
        Write-Step '開発者モードを有効化しています...'
        New-Item -Path $path -Force | Out-Null
        New-ItemProperty -Path $path -Name 'AllowDevelopmentWithoutDevLicense' -Value 1 -PropertyType DWord -Force | Out-Null
        return
    }

    Write-Step '開発者モードの有効化には管理者権限が必要なため、UAC 昇格して設定します...'
    try {
        $command = "New-Item -Path '$path' -Force | Out-Null; New-ItemProperty -Path '$path' -Name AllowDevelopmentWithoutDevLicense -Value 1 -PropertyType DWord -Force | Out-Null"
        Start-Process -FilePath 'powershell' -ArgumentList @('-NoProfile', '-Command', $command) -Verb RunAs -Wait
        Write-Step '開発者モードを有効化しました。'
    }
    catch {
        Write-Warn "開発者モードの有効化に失敗しました (UAC がキャンセルされた可能性があります): $($_.Exception.Message)"
    }
}

function Set-StartMenuSettings {
    Write-Step 'スタートメニューの設定を行っています...'
    $search = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
    $advanced = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    $start = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'

    New-ItemProperty -Path $search -Name 'BingSearchEnabled' -Value 0 -PropertyType DWord -Force | Out-Null           # 検索での Web 結果を無効化
    New-ItemProperty -Path $advanced -Name 'Start_IrisRecommendations' -Value 0 -PropertyType DWord -Force | Out-Null # 「おすすめ」表示を無効化
    New-Item -Path $start -Force -ErrorAction SilentlyContinue | Out-Null
    New-ItemProperty -Path $start -Name 'ShowRecentList' -Value 0 -PropertyType DWord -Force | Out-Null               # 最近追加したアプリの表示を無効化
}

function Restart-Explorer {
    Write-Step 'エクスプローラーを再起動しています...'
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer.exe
}

function Main {
    # GUI/デスクトップの見た目設定のため CI ではスキップする (mac の system_settings.sh と同様)
    if ($env:CI) {
        Write-Step 'CI 環境のためシステム設定をスキップします。'
        return
    }
    Set-ExplorerSettings
    Set-WallpaperSettings
    Set-TaskbarSettings
    Set-PowerSettings
    Set-KeyboardSettings
    Enable-DeveloperMode
    Set-StartMenuSettings
    Restart-Explorer
}

Main
