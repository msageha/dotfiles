#!/usr/bin/env pwsh
# Windows 向けコーディングエージェント CLI のインストール。
# mac (install/macos/brew.sh) / debian (install/debian/coding_agent.sh) に相当する。
# Windows PowerShell 5.1 互換の構文のみを使うこと (pwsh は前提にしない)。
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step($msg) { Write-Host $msg -ForegroundColor Blue }

function Invoke-RemoteInstaller([string]$Url) {
    # このスクリプトの Set-StrictMode / $ErrorActionPreference='Stop' は子スコープに
    # 継承され、strict-clean とは限らないサードパーティのインストーラを誤爆させうるため、
    # 別プロセスで実行して隔離する (debian 版の `curl | bash` と同等)。
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm $Url | iex"
    if ($LASTEXITCODE -ne 0) {
        throw "インストーラが失敗しました ($Url): exit code $LASTEXITCODE"
    }
}

function Install-AntigravityCli {
    Write-Step 'Installing antigravity-cli...'
    # update に使う agy を probe する (antigravity を probe すると、agy だけ無い環境で
    # $ErrorActionPreference='Stop' により後続のインストールごと中断してしまう)
    if (-not (Get-Command agy -ErrorAction SilentlyContinue)) {
        Invoke-RemoteInstaller 'https://antigravity.google/cli/install.ps1'
    }
    else {
        # 5.1 はネイティブコマンドの失敗を throw しないため終了コードを明示的に確認する
        agy update
        if ($LASTEXITCODE -ne 0) { throw "agy update failed: exit code $LASTEXITCODE" }
    }
}

function Install-ClaudeCode {
    Write-Step 'Installing Claude Code...'
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Invoke-RemoteInstaller 'https://claude.ai/install.ps1'
    }
    else {
        claude update
        if ($LASTEXITCODE -ne 0) { throw "claude update failed: exit code $LASTEXITCODE" }
    }
}

function Install-Codex {
    Write-Step 'Installing Codex CLI...'
    if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
        Invoke-RemoteInstaller 'https://chatgpt.com/codex/install.ps1'
    }
    else {
        codex update
        if ($LASTEXITCODE -ne 0) { throw "codex update failed: exit code $LASTEXITCODE" }
    }
}

function Main {
    Write-Step '=== Installing coding agents ==='
    Install-AntigravityCli
    Install-ClaudeCode
    Install-Codex
    Write-Step '=== All coding agents installed! ==='
}

Main
