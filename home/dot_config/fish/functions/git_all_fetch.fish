function git_all_fetch
    set -l repos (__git_all_repos); or return
    string join0 -- $repos | xargs -0 -P 8 -I{} sh -c \
        'if git -C "$1" fetch --quiet; then echo "$1: fetched"; else echo "$1: fetch failed"; exit 1; fi' _ {}
end
