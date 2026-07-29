#!/usr/bin/env bash
# prek (pre-commit) の local hook: PSScriptAnalyzer で PowerShell スクリプトを lint する。
# pwsh または PSScriptAnalyzer モジュールが無い環境 (未導入の macOS / Linux) では
# スキップ理由を表示して成功扱いにする (CI の GitHub ubuntu runner には両方入っている)。
set -euo pipefail

if ! command -v pwsh &>/dev/null; then
    echo "pwsh が見つからないため PSScriptAnalyzer をスキップします" >&2
    exit 0
fi
if ! pwsh -NoProfile -Command 'if (Get-Module -ListAvailable PSScriptAnalyzer) { exit 0 }; exit 1' &>/dev/null; then
    echo "PSScriptAnalyzer モジュールが見つからないためスキップします (Install-Module PSScriptAnalyzer で導入可能)" >&2
    exit 0
fi

status=0
for file in "$@"; do
    # ファイルパスはコマンド文字列へ埋め込まず環境変数で渡す (空白・クォート対策)
    if ! PSSA_TARGET="$file" pwsh -NoProfile -Command '
        $findings = Invoke-ScriptAnalyzer -Path $env:PSSA_TARGET -Severity Warning, Error
        if ($findings) {
            $findings | Format-Table -AutoSize | Out-String | Write-Host
            exit 1
        }
    '; then
        echo "PSScriptAnalyzer: findings in ${file}" >&2
        status=1
    fi
done
exit $status
