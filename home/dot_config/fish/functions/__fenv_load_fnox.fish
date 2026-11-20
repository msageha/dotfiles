function __fenv_load_fnox
    set -l selected "$argv[1]"
    type -q fnox; or return 0

    if test "$selected" = default
        test -f fnox.toml; or return 0
    else
        test -f fnox.toml; or test -f fnox.$selected.toml; or return 0
    end

    # 設定の探索 (親ディレクトリ・fnox.local.toml・fnox.<profile>.toml の merge) は fnox に任せる。-c で設定を渡すと、隣の
    # fnox.local.toml と profile のファイルを読まない。
    # 1Password の signin と失効時の中断は fnox wrapper (config.fish) が担う。command fnox で迂回すると、失効時に op が secret ごとに認証ダイアログを出す。
    # wrapper も選んだ profile の設定を見て signin するよう、profile は -P ではなく FNOX_PROFILE で渡す
    set -lx FNOX_PROFILE $selected
    set -l fnox_output (fnox export -f env 2>/dev/null)
    set -l fnox_status $status
    if test $fnox_status -ne 0
        echo "Failed to load fnox environment."
        return $fnox_status
    end

    # env 形式は 1 secret 1 行で、値を quote しない・'…' (中に escape 無し)・"…" (\" \\ \n 等の escape 付き) のどれかで書く。
    # "…" の中身は fish の unquote した escape と同じ規則で読めるが、そのまま渡すと ' を quote の開始とみなすので、先に \' にする
    for line in $fnox_output
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- "$line"; or continue
        set -l kv (string split -m1 '=' -- "$line")
        set -l val $kv[2]
        if string match -qr '^".*"$' -- $val
            set val (printf %s (string sub -s 2 -e -1 -- $val) | string replace -a "'" "\\'" | string unescape | string collect -N)
        else if string match -qr "^'.*'\$" -- $val
            set val (string sub -s 2 -e -1 -- $val)
        end
        set -gx $kv[1] "$val"
    end
end
