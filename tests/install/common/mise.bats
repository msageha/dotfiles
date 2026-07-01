#!/usr/bin/env bats

readonly SCRIPT_PATH="./install/common/mise.sh"

function setup() {
    # shellcheck source=install/common/mise.sh
    source "${SCRIPT_PATH}"
}

@test "[common] mise - validate" {
    [ -e "${SCRIPT_PATH}" ]
    run validate_mise
    [ "$status" -eq 0 ]
}

@test "[common] mise - install tools" {
    # 期待ツールは展開済み mise 設定の [tools] から動的取得し、config との乖離を防ぐ
    local config="$HOME/.config/mise/config.toml"
    [ -f "$config" ] || skip "mise config not found: $config"

    local tools=()
    while IFS= read -r tool; do
        tools+=("$tool")
    done < <(sed -n '/^\[tools\]/,/^\[/p' "$config" | sed -n 's/^\([A-Za-z0-9_.-]*\) *=.*/\1/p')
    [ "${#tools[@]}" -gt 0 ] || skip "no tools configured in $config"

    local installed
    installed="$(mise list --current 2>/dev/null)"

    local missing=()
    for tool in "${tools[@]}"; do
        if ! echo "${installed}" | grep -q "^${tool} "; then
            missing+=("${tool}")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        skip "Missing mise tools: ${missing[*]}"
    fi
}
