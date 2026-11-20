function __fenv_load_fnox
    set -l selected "$argv[1]"
    type -q fnox; or return 0

    # fenv の候補には mise だけの環境の名前も入るので、fnox.<名前>.toml が無ければ default の profile を読む
    set -l fnox_profile default
    if test -f fnox.$selected.toml
        set fnox_profile $selected
    else if not test -f fnox.toml
        return 0
    end
    if not type -q jq
        echo "fenv: jq not found" >&2
        return 1
    end

    # 設定の探索 (親ディレクトリ・fnox.local.toml・fnox.<profile>.toml の merge) は fnox に任せる。-c で設定を渡すと、隣の
    # fnox.local.toml と profile のファイルを読まない。
    # 1Password の signin と失効時の中断は fnox wrapper (config.fish) が担う。command fnox で迂回すると、失効時に op が secret ごとに認証ダイアログを出す。
    # wrapper も選んだ profile の設定を見て signin するよう、profile は -P ではなく FNOX_PROFILE で渡す
    set -lx FNOX_PROFILE $fnox_profile
    set -l fnox_json (fnox export -f json 2>/dev/null)
    set -l fnox_status $status
    if test $fnox_status -ne 0
        echo "Failed to load fnox environment."
        return $fnox_status
    end

    # env 形式は値によって quote の規則が変わり、複数行の値は行をまたぐので、JSON から key と value を NUL 区切りで取り出す
    set -l pairs (printf '%s\n' $fnox_json | jq -j '.secrets | to_entries[] | .key, "\u0000", .value, "\u0000"' | string split0)
    if test $pipestatus[2] -ne 0
        echo "Failed to parse fnox output." >&2
        return 1
    end
    while set -q pairs[2]
        set -gx $pairs[1] $pairs[2]
        set -e pairs[1..2]
    end
end
