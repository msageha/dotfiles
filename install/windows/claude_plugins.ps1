#!/usr/bin/env pwsh
# Claude Code plugin のインストール。install/common/claude_plugins.sh の Windows 版。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

# marketplace add / plugin install / update は導入済みでも成功するので、分岐せず毎回実行して最新にする
function Install-Plugin([string]$PluginId) {
    claude plugin install $PluginId
    if ($LASTEXITCODE -ne 0) { throw "claude plugin install failed ($PluginId): exit code $LASTEXITCODE" }
    claude plugin update $PluginId
    if ($LASTEXITCODE -ne 0) { throw "claude plugin update failed ($PluginId): exit code $LASTEXITCODE" }
}

function Main {
    # CLAUDE_MARKETPLACES (name=owner/repo の空白区切り) と CLAUDE_PLUGINS (有効な plugin id の空白区切り) は
    # run_once_before テンプレートが .chezmoidata.toml の claude.* から渡す。
    # PowerShell は空文字を代入した環境変数を削除するので、CLAUDE_PLUGINS が無いときは 0 件とする
    $marketplaces = @($env:CLAUDE_MARKETPLACES -split '\s+' | Where-Object { $_ })
    $plugins = @($env:CLAUDE_PLUGINS -split '\s+' | Where-Object { $_ })
    if (-not $marketplaces) {
        throw 'CLAUDE_MARKETPLACES is not set; it must be exported by the caller.'
    }
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warn 'claude が見つかりません。plugin のインストールをスキップします。'
        return
    }

    Write-Step '=== Installing Claude Code plugins ==='
    foreach ($marketplace in $marketplaces) {
        $name, $repo = $marketplace -split '=', 2
        claude plugin marketplace add $repo
        if ($LASTEXITCODE -ne 0) { throw "claude plugin marketplace add failed ($repo): exit code $LASTEXITCODE" }
        claude plugin marketplace update $name
        if ($LASTEXITCODE -ne 0) { throw "claude plugin marketplace update failed ($name): exit code $LASTEXITCODE" }
    }
    foreach ($plugin in $plugins) {
        Write-Step "Installing $plugin..."
        Install-Plugin $plugin
    }

    Write-Step '=== All Claude Code plugins installed! ==='
}

Main
