function git_clean_branches
    # 現在のブランチ名を取得
    set current_branch (git symbolic-ref --short HEAD 2>/dev/null)

    # detached HEAD では symbolic-ref が空文字を返すため、未クォートの比較で
    # test の引数エラーになる。空の場合は全ブランチ削除の判定ができないため中断する
    if test -z "$current_branch"
        echo "Detached HEAD: current branch cannot be determined. Aborting."
        return 1
    end

    # 削除しないブランチ名（master, main）をリストに追加
    set protected_branches master main

    # master, main 以外のすべてのローカルブランチを削除
    for branch in (git branch --format="%(refname:short)")
        if not contains $branch $protected_branches
            if test "$branch" != "$current_branch"
                git branch -D $branch
                echo "Deleted branch: $branch"
            else
                echo "Skipping current branch: $branch"
            end
        else
            echo "Protected branch: $branch"
        end
    end
end
