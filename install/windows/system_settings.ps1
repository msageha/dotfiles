#!/usr/bin/env pwsh
# Windows のシステム設定 (エクスプローラー・壁紙)。
# mac (install/macos/system_settings.sh) / ubuntu (install/ubuntu/system_settings.sh) に相当する。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

$ExplorerAdvancedKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
$SearchKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'

function Set-RegistryDword([string]$Path, [string]$Name, [int]$Value) {
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
}

# UAC 昇格した別プロセスの powershell で $Command を実行し、完了を待って成否を返す。
# Start-Process -Wait は子の非 0 終了では throw しないため、終了コードも見る
function Invoke-ElevatedPowerShell([string]$Command, [string]$Subject) {
    Write-Step "${Subject}には管理者権限が必要なため、UAC 昇格して実行します..."
    try {
        $process = Start-Process -FilePath 'powershell' -ArgumentList @('-NoProfile', '-Command', $Command) -Verb RunAs -Wait -PassThru
    }
    catch {
        Write-Warn "${Subject}に失敗しました (UAC がキャンセルされた可能性があります): $($_.Exception.Message)"
        return $false
    }
    if ($process.ExitCode -ne 0) {
        Write-Warn "${Subject}に失敗しました (昇格先の終了コード $($process.ExitCode))。"
        return $false
    }
    return $true
}

function Set-ExplorerSettings {
    Write-Step 'エクスプローラーの設定を行っています...'
    Set-RegistryDword $ExplorerAdvancedKey 'Hidden' 1        # 隠しファイルを表示
    Set-RegistryDword $ExplorerAdvancedKey 'HideFileExt' 0   # ファイルの拡張子を表示
    Set-RegistryDword $ExplorerAdvancedKey 'ShowStatusBar' 1 # ステータスバーを表示
    Set-RegistryDword $ExplorerAdvancedKey 'LaunchTo' 1      # 起動時にクイックアクセスではなく PC を表示
}

function Set-ContextMenuSettings {
    Write-Step '右クリックメニューを従来表示 (Windows 10 形式) に設定しています...'
    # この CLSID の InprocServer32 を空の既定値で登録すると Windows 11 が簡略メニューを
    # ロードできなくなり、常に従来のフルメニューが表示される。Windows 10 では参照されない
    # キーのため無害。反映は Main 末尾の Restart-Explorer で行われる。
    $key = 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name '(Default)' -Value ''
}

function Set-WallpaperSettings {
    Write-Step '壁紙の設定を行っています...'
    $picturesDir = Join-Path $env:USERPROFILE 'Pictures'
    New-Item -ItemType Directory -Force -Path $picturesDir | Out-Null
    $wallpaperPath = Join-Path $picturesDir 'wallpaper.png'

    # 取得失敗時に壊れた本文を壁紙にしないよう、失敗したらここで打ち切ってスキップする
    try {
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

# UCPD.sys (User Choice Protection Driver) は保護対象の値名への書き込みをカーネルの
# レジストリコールバックで傍受し、呼び出し元が deny-list (reg.exe / powershell.exe 等) の
# 場合に ACCESS_DENIED を返す。TaskbarDa と ShellFeedsTaskbarViewMode がこれに該当し、
# Microsoft 署名バイナリ (設定アプリ) 以外からは変更できないため、拒否は警告にして続行する。
# 拒否以外の失敗は握りつぶさず再スローする。
function Set-UcpdProtectedDword($path, $name, $value) {
    try {
        Set-RegistryDword $path $name $value
    }
    catch {
        # $ErrorActionPreference = 'Stop' 経由で終了エラー化された場合に例外が
        # 包まれることがあるため、例外チェーンと FullyQualifiedErrorId の両方で判定する
        $unauthorized = $false
        for ($ex = $_.Exception; $null -ne $ex; $ex = $ex.InnerException) {
            if ($ex -is [System.UnauthorizedAccessException]) {
                $unauthorized = $true
                break
            }
        }
        if (-not $unauthorized -and $_.FullyQualifiedErrorId -notlike 'System.UnauthorizedAccessException*') {
            throw
        }
        Write-Warn "$name の書き込みが拒否されたためスキップします (UCPD.sys による保護。変更するには設定アプリから操作してください)。"
    }
}

function Set-TaskbarSettings {
    Write-Step 'タスクバー・システムトレイの設定を行っています...'
    $feeds = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Feeds'

    Set-RegistryDword $SearchKey 'SearchboxTaskbarMode' 0 # 検索ボックスを非表示

    Set-UcpdProtectedDword $ExplorerAdvancedKey 'TaskbarDa' 0 # ウィジェットを非表示 (Windows 11)
    New-Item -Path $feeds -Force -ErrorAction SilentlyContinue | Out-Null
    Set-UcpdProtectedDword $feeds 'ShellFeedsTaskbarViewMode' 2 # ニュースと関心事項を非表示 (Windows 10)

    Set-RegistryDword $ExplorerAdvancedKey 'TaskbarMn' 0         # Chat アイコンを非表示
    Set-RegistryDword $ExplorerAdvancedKey 'ShowCopilotButton' 0 # Copilot アイコンを非表示

    Set-RegistryDword $ExplorerAdvancedKey 'IsBatteryPercentageEnabled' 1 # バッテリー残量%を表示
    Set-RegistryDword $ExplorerAdvancedKey 'ShowSecondsInSystemClock' 1   # 時計に秒を表示
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

function Set-ClipboardSettings {
    Write-Step 'クリップボード履歴を有効化しています...'
    $clipboard = 'HKCU:\Software\Microsoft\Clipboard'
    New-Item -Path $clipboard -Force -ErrorAction SilentlyContinue | Out-Null
    Set-RegistryDword $clipboard 'EnableClipboardHistory' 1 # Win+V の履歴を有効化
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
    if ((Get-RegistryValueOrNull $path 'AllowDevelopmentWithoutDevLicense') -eq 1) {
        Write-Step '開発者モードは既に有効なため、スキップします。'
        return
    }

    if (Test-IsAdmin) {
        Write-Step '開発者モードを有効化しています...'
        New-Item -Path $path -Force | Out-Null
        Set-RegistryDword $path 'AllowDevelopmentWithoutDevLicense' 1
        return
    }

    $command = "New-Item -Path '$path' -Force | Out-Null; New-ItemProperty -Path '$path' -Name AllowDevelopmentWithoutDevLicense -Value 1 -PropertyType DWord -Force | Out-Null"
    if (Invoke-ElevatedPowerShell $command '開発者モードの有効化') {
        Write-Step '開発者モードを有効化しました。'
    }
}

function Disable-BitLockerProtection {
    # Get-BitLockerVolume は管理者権限が必要なため、未昇格でも読み取れるシェルプロパティで
    # 先にシステムドライブの状態を判定し、無効化が必要なときだけ UAC 昇格する
    # (Enable-DeveloperMode と同様、毎回ダイアログが出るのを避けるため)。
    try {
        $shell = New-Object -ComObject Shell.Application
        $protection = $shell.NameSpace("$env:SystemDrive\").Self.ExtendedProperty('System.Volume.BitLockerProtection')
    }
    catch {
        Write-Warn "BitLocker の状態を取得できませんでした。スキップします: $($_.Exception.Message)"
        return
    }
    # System.Volume.BitLockerProtection: 1=有効 3=暗号化中 5=一時停止 6=ロック中 / 2=無効 4=復号中 / 0 or null=非対応
    if ($null -eq $protection -or $protection -in @(0, 2, 4)) {
        Write-Step 'BitLocker は既に無効のため、スキップします。'
        return
    }

    # Disable-BitLocker は復号をバックグラウンドで開始して即座に戻るため、-Wait しても apply は長時間ブロックされない
    if (Test-IsAdmin) {
        if (-not (Get-Command Disable-BitLocker -ErrorAction SilentlyContinue)) {
            Write-Warn 'Disable-BitLocker が見つかりません (Home エディション等)。設定アプリの「デバイスの暗号化」から手動で無効化してください。'
            return
        }
        Write-Step 'BitLocker を無効化しています...'
        Get-BitLockerVolume | Where-Object { $_.VolumeStatus -ne 'FullyDecrypted' } | Disable-BitLocker | Out-Null
        Write-Step 'BitLocker の無効化を開始しました (復号はバックグラウンドで継続されます)。'
        return
    }

    $command = 'Get-BitLockerVolume | Where-Object { $_.VolumeStatus -ne ''FullyDecrypted'' } | Disable-BitLocker | Out-Null'
    if (Invoke-ElevatedPowerShell $command 'BitLocker の無効化') {
        Write-Step 'BitLocker の無効化を開始しました (復号はバックグラウンドで継続されます)。'
    }
}

function Set-StartMenuSettings {
    Write-Step 'スタートメニューの設定を行っています...'
    $start = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'

    Set-RegistryDword $SearchKey 'BingSearchEnabled' 0                    # 検索での Web 結果を無効化
    Set-RegistryDword $ExplorerAdvancedKey 'Start_IrisRecommendations' 0 # 「おすすめ」表示を無効化
    New-Item -Path $start -Force -ErrorAction SilentlyContinue | Out-Null
    Set-RegistryDword $start 'ShowRecentList' 0                          # 最近追加したアプリの表示を無効化
}

function Restart-Explorer {
    Write-Step 'エクスプローラーを再起動しています...'
    # explorer はシェルとして登録されているため kill 後に自動で再起動する。
    # 明示的に Start-Process すると余計なファイルウィンドウが開くため行わない。
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
}

function Main {
    # GUI/デスクトップの見た目設定のため CI ではスキップする (mac の system_settings.sh と同様)
    if ($env:CI) {
        Write-Step 'CI 環境のためシステム設定をスキップします。'
        return
    }
    Set-ExplorerSettings
    Set-ContextMenuSettings
    Set-WallpaperSettings
    Set-TaskbarSettings
    Set-PowerSettings
    Set-ClipboardSettings
    Set-KeyboardSettings
    Enable-DeveloperMode
    Disable-BitLockerProtection
    Set-StartMenuSettings
    Restart-Explorer
}

Main
