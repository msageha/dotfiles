#!/usr/bin/env bats

@test "[files] fish - fisher installed by run_once_after_91_common" {
    command -v fish >/dev/null 2>&1 || skip "fish not installed"
    run fish -c "type -q fisher; and fisher --version"
    [ "$status" -eq 0 ]
}

@test "[files] fish - functions dir has no stale files outside chezmoi and fisher" {
    command -v fish >/dev/null 2>&1 || skip "fish not installed"
    # chezmoi 管理外かつ fisher 管理でもない functions/*.fish は、source から消えたのに
    # .chezmoiremove に載っていない残骸。fish はコマンド名と同名の functions/<name>.fish を
    # 呼び出し時に autoload するため、旧ファイルに残った同名関数が現行の定義を上書きする
    local fisher_files
    # fisher は ~/ 始まりで記録するので、chezmoi unmanaged の既定 (home 相対) に揃える。
    # 記録が無い (fisher 未導入) ときは string match の不一致で fish が exit 1 になるため、空集合として扱う
    fisher_files="$(fish -c 'for v in (set -Un | string match "_fisher_*_files"); string replace -r "^~/" "" -- $$v; end; true' 2>/dev/null)"
    run chezmoi --source "$PWD" unmanaged "$HOME/.config/fish/functions"
    [ "$status" -eq 0 ]
    local stale=()
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        grep -qxF "$f" <<<"$fisher_files" || stale+=("$f")
    done <<<"$output"
    [ "${#stale[@]}" -eq 0 ] || { printf 'stale: %s\n' "${stale[@]}"; false; }
}
