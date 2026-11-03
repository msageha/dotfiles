#!/usr/bin/env pwsh
# Windows 向けコーディングエージェント CLI のインストール。
# mac (install/macos/brew.sh) / debian (install/debian/coding_agent.sh) に相当する。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Get-Variable DotfilesLibLoaded -Scope Script -ErrorAction SilentlyContinue)) { . (Join-Path $PSScriptRoot 'lib.ps1') }

# Command は導入済み判定と `<Command> update` の両方に使う。
# antigravity-cli を antigravity で判定すると、agy だけ無い環境で `agy update` が失敗して後続ごと止まるため agy で判定する
$CodingAgents = @(
    @{ Name = 'antigravity-cli'; Command = 'agy'; Installer = 'https://antigravity.google/cli/install.ps1' }
    @{ Name = 'Claude Code'; Command = 'claude'; Installer = 'https://claude.ai/install.ps1' }
    @{ Name = 'Codex CLI'; Command = 'codex'; Installer = 'https://chatgpt.com/codex/install.ps1' }
)

function Invoke-RemoteInstaller([string]$Url) {
    # このスクリプトの Set-StrictMode / $ErrorActionPreference='Stop' は子スコープに継承され、
    # それを想定していない外部のインストーラを失敗させうるため、別プロセスで実行する。
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm $Url | iex"
    if ($LASTEXITCODE -ne 0) {
        throw "インストーラが失敗しました ($Url): exit code $LASTEXITCODE"
    }
}

function Install-CodingAgent($Agent) {
    Write-Step "Installing $($Agent.Name)..."
    if (-not (Get-Command $Agent.Command -ErrorAction SilentlyContinue)) {
        Invoke-RemoteInstaller $Agent.Installer
    }
    else {
        & $Agent.Command update
        if ($LASTEXITCODE -ne 0) { throw "$($Agent.Command) update failed: exit code $LASTEXITCODE" }
    }
}

function Main {
    Write-Step '=== Installing coding agents ==='
    foreach ($agent in $CodingAgents) {
        Install-CodingAgent $agent
    }
    Write-Step '=== All coding agents installed! ==='
}

Main
