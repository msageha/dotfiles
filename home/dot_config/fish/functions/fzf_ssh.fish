function fzf_ssh -d "List ssh"
    set -l configs
    for f in $HOME/.ssh/config $HOME/.ssh/config.local
        test -f $f; and set -a configs $f
    end
    test -z "$configs"; and return

    set -l host (\
        grep -hiE '^[[:space:]]*Host[[:space:]]+' $configs \
        | grep -v '[*?]' \
        | grep -v "git" \
        | awk '{ print $2 }' \
        | fzf --select-1
    )
    if test -n "$host"
        ssh $host
    end
end
