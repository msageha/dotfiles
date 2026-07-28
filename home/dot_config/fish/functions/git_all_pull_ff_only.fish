function git_all_pull_ff_only
    # Run 'git pull --ff-only' in all repositories (8 repos in parallel)
    __git_all_repos | xargs -P 8 -I{} sh -c \
        'git -C "$1" pull --ff-only --quiet && echo "$1: pulled" || echo "$1: pull failed"' _ {}
end
