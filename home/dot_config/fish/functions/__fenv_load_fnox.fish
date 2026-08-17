function __fenv_load_fnox
    set -l selected "$argv[1]"
    type -q fnox; or return 0

    if test "$selected" = default
        test -f fnox.toml; or return 0
    else
        test -f fnox.toml; or test -f fnox.$selected.toml; or return 0
    end

    set -l temp_dir (mktemp -d)
    if test -z "$temp_dir"
        echo "Failed to create temporary directory."
        return 1
    end

    set -l profile_args
    if test -f fnox.toml
        cp fnox.toml "$temp_dir/fnox.toml"
        if test "$selected" != default; and test -f fnox.$selected.toml
            cp fnox.$selected.toml "$temp_dir/fnox.$selected.toml"
            set profile_args -P "$selected"
        end
    else if test "$selected" != default; and test -f fnox.$selected.toml
        cp fnox.$selected.toml "$temp_dir/fnox.toml"
    end
    # fnox は fnox.local.toml もマージするため、存在すればコピーして本来のマージ結果に合わせる
    if test -f fnox.local.toml
        cp fnox.local.toml "$temp_dir/fnox.local.toml"
    end

    # 1Password の事前認証 (op signin 1 回) と失効時の中断は fnox wrapper
    # (config.fish) が担う。失効したまま本体を実行すると op が secret ごとに
    # 認証ダイアログを出すため、ここでフォールバック実行しない
    set -l fnox_output (fnox -c "$temp_dir/fnox.toml" $profile_args export -f env 2>/dev/null)
    set -l fnox_status $status
    rm -rf "$temp_dir"

    if test $fnox_status -ne 0
        echo "Failed to load fnox environment."
        return $fnox_status
    end

    for line in $fnox_output
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line"; or continue
        set -l key (string split -m1 '=' -- "$line")[1]
        set -l val (string split -m1 '=' -- "$line")[2]
        # KEY="value" / KEY='value' 形式で出力された場合に備えてクォートを除去する
        set val (string trim -c '"' -- $val)
        set val (string trim -c "'" -- $val)
        set -gx $key "$val"
    end
end
