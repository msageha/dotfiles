function git_all_switch_main
    # Switch to 'main' (or 'master' as fallback) in all repositories
    for repo in (__git_all_repos)
        if git -C $repo show-ref --verify --quiet refs/heads/main
            echo "$repo: switching to 'main'"
            git -C $repo switch main
        else if git -C $repo show-ref --verify --quiet refs/heads/master
            echo "$repo: switching to 'master'"
            git -C $repo switch master
        else
            echo "$repo: neither 'main' nor 'master' found, skipping"
        end
    end
end
