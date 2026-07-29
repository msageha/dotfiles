#!/usr/bin/env pwsh
# Claude Code plugin のインストール。install/common/claude_plugins.sh の Windows 版。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }
function Write-Warn($msg) { Write-Host $msg -ForegroundColor Yellow }

# 公式 marketplace (claude-plugins-official) から plugin を取得する共通処理。
# add / install は導入済みでもエラーにならず冪等なため、分岐せず常に実行して最新化する。
# 5.1 はネイティブコマンドの失敗を throw しないため終了コードを明示的に確認する。
function Install-Plugin([string]$PluginId) {
    claude plugin install $PluginId
    if ($LASTEXITCODE -ne 0) { throw "claude plugin install failed ($PluginId): exit code $LASTEXITCODE" }
    claude plugin update $PluginId
    if ($LASTEXITCODE -ne 0) { throw "claude plugin update failed ($PluginId): exit code $LASTEXITCODE" }
}

# install/common/claude_plugins.sh の plugin 一覧と同期を保つこと
$Plugins = @(
    'cloudflare@claude-plugins-official'
    'github@claude-plugins-official'
    'agent-sdk-dev@claude-plugins-official'
    'plugin-dev@claude-plugins-official'
    'claude-md-management@claude-plugins-official'
    'skill-creator@claude-plugins-official'
    'sonatype-guide@claude-plugins-official'
    # LSP servers
    'pyright-lsp@claude-plugins-official'
    'gopls-lsp@claude-plugins-official'
    'clangd-lsp@claude-plugins-official'
    'swift-lsp@claude-plugins-official'
    'typescript-lsp@claude-plugins-official'
)

function Main {
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warn 'claude が見つかりません。plugin のインストールをスキップします。'
        return
    }

    Write-Step '=== Installing Claude Code plugins ==='
    claude plugin marketplace add anthropics/claude-plugins-official
    if ($LASTEXITCODE -ne 0) { throw "claude plugin marketplace add failed: exit code $LASTEXITCODE" }
    claude plugin marketplace update claude-plugins-official
    if ($LASTEXITCODE -ne 0) { throw "claude plugin marketplace update failed: exit code $LASTEXITCODE" }

    foreach ($plugin in $Plugins) {
        Write-Step "Installing $plugin..."
        Install-Plugin $plugin
    }

    Write-Step '=== All Claude Code plugins installed! ==='
}

Main
