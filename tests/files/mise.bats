#!/usr/bin/env bats

@test "[files] mise - installed" {
    command -v mise
}

@test "[files] mise - every tool in the deployed config is installed" {
    # 期待ツールは展開済み mise 設定の [tools] から動的取得し、config との乖離を防ぐ
    local config="$HOME/.config/mise/config.toml"
    [ -f "$config" ] || skip "mise config not found: $config"

    local tools=()
    while IFS= read -r tool; do
        tools+=("$tool")
    # クォート付きキー ("ubi:owner/repo" 等の backend 指定) も拾う
    done < <(sed -n '/^\[tools\]/,/^\[/p' "$config" | sed -n 's|^"\{0,1\}\([A-Za-z0-9_.:/-]\{1,\}\)"\{0,1\} *=.*|\1|p')
    [ "${#tools[@]}" -gt 0 ]

    # CI は bats に隔離用 MISE_CONFIG_DIR (repo の mise.toml のみ) を渡すため、期待値と同じ
    # user config が効く状態 ($HOME で、隔離を外して) で一覧を取る
    local installed
    installed="$(cd "$HOME" && env -u MISE_CONFIG_DIR mise list --current 2>/dev/null)"
    for tool in "${tools[@]}"; do
        echo "Checking ${tool}"
        echo "${installed}" | grep -q "^${tool} "
    done
}
