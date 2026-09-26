function fzf_ssh -d "Select an ssh host from ~/.ssh/config* and connect"
    type -q fzf; or begin; echo "fzf_ssh: fzf not found" >&2; return 1; end

    set -l configs
    for f in $HOME/.ssh/config $HOME/.ssh/config.local
        test -f $f; and set -a configs $f
    end
    test -z "$configs"; and return

    # git 系ホスト (Host git / github.com / gitlab.* 等) は ssh 接続対象から除外する。
    # -w で単語境界を要求し、"digital" のような git を部分文字列に含むだけの
    # 無関係なホスト名まで除外してしまわないようにする
    set -l host (\
        grep -hiE '^[[:space:]]*Host[[:space:]]+' $configs \
        | grep -v '[*?]' \
        | grep -vwE 'git(hub|lab)?' \
        | awk '{ print $2 }' \
        | fzf --select-1
    )
    if test -n "$host"
        ssh $host
    end
end
