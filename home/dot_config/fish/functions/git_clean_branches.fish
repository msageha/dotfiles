function git_clean_branches
    set -l current_branch (git symbolic-ref --short HEAD 2>/dev/null)

    # detached HEAD では現在のブランチが分からず削除対象から外せないため中断する
    if test -z "$current_branch"
        echo "Detached HEAD: current branch cannot be determined. Aborting."
        return 1
    end

    set -l protected_branches master main

    # -D は未マージのブランチも消すため、対象を列挙して確認を取ってから消す
    set -l targets
    for branch in (git branch --format="%(refname:short)")
        if contains $branch $protected_branches
            echo "Protected branch: $branch"
        else if test "$branch" = "$current_branch"
            echo "Skipping current branch: $branch"
        else
            set -a targets $branch
        end
    end

    if test (count $targets) -eq 0
        echo "No branches to delete."
        return 0
    end

    printf 'Will force-delete (-D): %s\n' $targets
    read -l -P "Delete "(count $targets)" branches (including unmerged)? [y/N] " ans
    string match -qi y -- $ans; or return 1

    for branch in $targets
        git branch -D $branch
        echo "Deleted branch: $branch"
    end
end
