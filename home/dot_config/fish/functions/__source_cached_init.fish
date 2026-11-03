function __source_cached_init
    # usage: __source_cached_init <cache-name> <cmd> [args...]
    # バイナリが同じなら出力も同じ初期化スクリプト (starship init / brew shellenv 等) をキャッシュして
    # source し、シェル起動ごとの子プロセス (10〜30ms/個) を省く。<cmd> の mtime がキャッシュより
    # 新しければ作り直すため、<cmd> は絶対パスで渡す (コマンド名だと判定が常に偽になる)。
    # 空出力は失敗扱いにする (brew shellenv は brew が PATH 先頭にあると何も出さず、
    # 空のキャッシュが残ると以後 HOMEBREW_* が設定されない)
    set -l cache_dir $HOME/.cache/fish/init
    set -l cache $cache_dir/$argv[1].fish
    set -l bin $argv[2]
    if not test -f $cache; or test $bin -nt $cache
        mkdir -p $cache_dir
        # 同時起動したシェル同士で書きかけを読まないよう pid 付き一時ファイル経由で置く
        set -l tmp $cache.$fish_pid.tmp
        if $argv[2..] >$tmp 2>/dev/null; and test -s $tmp
            mv $tmp $cache
        else
            rm -f $tmp
            return 1
        end
    end
    source $cache
end
