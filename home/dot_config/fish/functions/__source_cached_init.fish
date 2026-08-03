function __source_cached_init
    # usage: __source_cached_init <cache-name> <cmd> [args...]
    # starship init / brew shellenv 等の「バイナリが同じなら出力も同じ」な初期化スクリプトを
    # ~/.cache/fish/init/ にキャッシュして source する。毎シェルの子プロセス起動 (10〜30ms/個) を
    # 初回とツール更新時だけに抑える。無効化判定は <cmd> バイナリの mtime がキャッシュより新しいか。
    # <cmd> は stat できる絶対パスを渡すこと (bare name だと判定が常に偽になり更新されなくなる)
    set -l cache_dir $HOME/.cache/fish/init
    set -l cache $cache_dir/$argv[1].fish
    set -l bin $argv[2]
    if not test -f $cache; or test $bin -nt $cache
        mkdir -p $cache_dir
        # 同時起動したシェル同士で書きかけを読まないよう pid 付き一時ファイル経由で置く
        set -l tmp $cache.$fish_pid.tmp
        if $argv[2..] >$tmp 2>/dev/null
            mv $tmp $cache
        else
            rm -f $tmp
            return 1
        end
    end
    source $cache
end
