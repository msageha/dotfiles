function git_clean_branches
    # 現在のブランチ名を取得
    set current_branch (git symbolic-ref --short HEAD)

    # 削除しないブランチ名（master, main）をリストに追加
    set protected_branches master main

    # master, main 以外のすべてのローカルブランチを削除
    for branch in (git branch --format="%(refname:short)")
        if not contains $branch $protected_branches
            if test $branch != $current_branch
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

function git_checkout_main
    # Check if the 'main' branch exists
    set branch_main (git branch --list main)

    # If 'main' exists, checkout to 'main'
    if test -n "$branch_main"
        echo "Checking out to the 'main' branch."
        git checkout main
        return 0
    end

    # Check if the 'master' branch exists
    set branch_master (git branch --list master)

    # If 'master' exists, checkout to 'master'
    if test -n "$branch_master"
        echo "Checking out to the 'master' branch."
        git checkout master
        return 0
    end

    # If neither 'main' nor 'master' exist, print a warning message
    echo "Neither 'main' nor 'master' branch found."
    return 1
end

function ghq_all_update
    ghq list | ghq get --update --parallel
end
