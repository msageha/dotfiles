#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/fonts.sh"

function setup() {
    # shellcheck source=install/common/fonts.sh
    source "${SCRIPT_PATH}"
}

# GUI ツールを省く環境 (skip_gui_tools=true) ではフォントは導入されない
# (run_once_after_91_common.sh.tmpl のガードと同条件)。導入済みを前提とする
# テストは、install スクリプトと同じ chezmoi の skip_gui_tools 値でスキップする。
function gui_tools_skipped() {
    [ "$(chezmoi execute-template '{{ dig "skip_gui_tools" false . }}' 2>/dev/null)" = "true" ]
}

@test "[common] fonts - validate" {
    [ -e "${SCRIPT_PATH}" ]
    run validation
    [ "$status" -eq 0 ]
}

@test "[common] fonts - setup fonts directory" {
    setup_fonts_dir
    [ "$?" -eq 0 ]
    [ -d "$FONT_DIR" ]
}

@test "[common] fonts - install Source Code Pro fonts" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    setup_fonts_dir

    expected=14
    count=$(find $FONT_DIR -maxdepth 1 -type f -name "Source Code Pro*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}

@test "[common] fonts - install Source Han Pro fonts" {
    if gui_tools_skipped; then
        skip "skip_gui_tools=true: fonts are not installed"
    fi
    setup_fonts_dir

    expected=14
    count=$(find $FONT_DIR -maxdepth 1 -type f -name "SourceHanCodeJP*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}
