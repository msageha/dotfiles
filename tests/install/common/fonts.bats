#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/fonts.sh"

function setup() {
    # shellcheck source=install/common/fonts.sh
    source "${SCRIPT_PATH}"
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
    setup_fonts_dir

    expected=14
    count=$(find $FONT_DIR -maxdepth 1 -type f -name "Source Code Pro*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}

@test "[common] fonts - install Source Han Pro fonts" {
    setup_fonts_dir

    expected=14
    count=$(find $FONT_DIR -maxdepth 1 -type f -name "SourceHanCodeJP*.otf" | wc -l | tr -d ' ')
    [ "$count" -eq "$expected" ]
}
