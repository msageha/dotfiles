function __git_main_branch -d 'Print main or master, whichever exists in the repository (usage: __git_main_branch <repo>)'
    for branch in main master
        if git -C $argv[1] show-ref --verify --quiet refs/heads/$branch
            echo $branch
            return 0
        end
    end
    return 1
end
