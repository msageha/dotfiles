function git_all_switch_main
    for repo in (__repo_list)
        set -l branch (__git_main_branch $repo)
        if test -n "$branch"
            echo "$repo: switching to '$branch'"
            git -C $repo switch $branch
        else
            echo "$repo: neither 'main' nor 'master' found, skipping"
        end
    end
end
