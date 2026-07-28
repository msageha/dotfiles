function git_all_fetch
    # Fetch in all repositories (8 repos in parallel)
    __git_all_repos | xargs -P 8 -I{} sh -c \
        'git -C "$1" fetch --quiet && echo "$1: fetched" || echo "$1: fetch failed"' _ {}
end
