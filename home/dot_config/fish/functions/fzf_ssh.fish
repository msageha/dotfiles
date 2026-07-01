function fzf_ssh -d "List ssh"
    set -l host (\
        grep -iE '^[[:space:]]*Host[[:space:]]+' $HOME/.ssh/config \
        | grep -v '[*?]' \
        | grep -v "git" \
        | awk '{ for (i=2; i<=NF; i++) print $i }' \
        | fzf --select-1
    )
    if test -n "$host"
        ssh $host
    end
end
