# bats の各ファイルが load する共通 helper。
# 適用済みの chezmoi data から skip_* フラグを読み、管理対象外の環境ではテストを skip する判定に使う

function cli_tools_skipped() {
    [ "$(chezmoi execute-template '{{ dig "skip_cli_tools" false . }}' 2>/dev/null)" = "true" ]
}

function gui_tools_skipped() {
    [ "$(chezmoi execute-template '{{ dig "skip_gui_tools" false . }}' 2>/dev/null)" = "true" ]
}
