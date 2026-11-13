function fzf_ssh -d "~/.ssh/config と ~/.ssh/config.local のホストを選んで ssh する"
    if not type -q fzf
        echo "fzf_ssh: fzf not found" >&2
        return 1
    end

    set -l configs
    for f in $HOME/.ssh/config $HOME/.ssh/config.local
        test -f $f; and set -a configs $f
    end
    test -z "$configs"; and return

    # git 系ホスト (git / github.com / gitlab.* 等) を除く。-w で "digital" のように git を含むだけのホストは残す
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
