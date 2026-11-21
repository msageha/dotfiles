function git_all_switch_main
    set -l repos (__git_all_repos); or return
    set -l failed
    for repo in $repos
        if git -C $repo show-ref --verify --quiet refs/heads/main
            echo "$repo: switching to 'main'"
            git -C $repo switch main; or set -a failed $repo
        else if git -C $repo show-ref --verify --quiet refs/heads/master
            echo "$repo: switching to 'master'"
            git -C $repo switch master; or set -a failed $repo
        else
            echo "$repo: neither 'main' nor 'master' found, skipping"
        end
    end
    if test (count $failed) -gt 0
        echo "Failed to switch: $failed" >&2
        return 1
    end
end
