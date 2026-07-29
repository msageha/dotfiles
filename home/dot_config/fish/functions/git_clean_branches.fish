function git_clean_branches
    set -l current_branch (git symbolic-ref --short HEAD 2>/dev/null)

    # detached HEAD では symbolic-ref が空文字を返すため、未クォートの比較で
    # test の引数エラーになる。空の場合は全ブランチ削除の判定ができないため中断する
    if test -z "$current_branch"
        echo "Detached HEAD: current branch cannot be determined. Aborting."
        return 1
    end

    set -l protected_branches master main

    # 削除対象を先に列挙し、確認を取ってから削除する
    # (-D は未マージブランチも消すため、black-box に即実行しない)
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
