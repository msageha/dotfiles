function git_all_pull_ff_only
    __git_all_repos | xargs -P 8 -I{} sh -c \
        'if git -C "$1" pull --ff-only --quiet; then echo "$1: pulled"; else echo "$1: pull failed"; exit 1; fi' _ {}
end
