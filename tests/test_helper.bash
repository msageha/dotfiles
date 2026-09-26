# bats の各ファイルが load する共通 helper。

# repo root を source に指定して template を評価する (.chezmoiroot が効くので home/ が source になる)。
# CI の runner には既定の ~/.local/share/chezmoi が無く、--source 無しでは .chezmoidata.toml が読めない
function chezmoi_template() {
    chezmoi --source "$PWD" execute-template "$1" 2>/dev/null
}

# 適用済みの chezmoi data から skip_* フラグを読み、管理対象外の環境ではテストを skip する判定に使う
function cli_tools_skipped() {
    [ "$(chezmoi_template '{{ dig "skip_cli_tools" false . }}')" = "true" ]
}

function gui_tools_skipped() {
    [ "$(chezmoi_template '{{ dig "skip_gui_tools" false . }}')" = "true" ]
}
