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

function __git_all_repos -d 'List repository paths (ghq + chezmoi source dir)'
    ghq list --full-path
    # ghq root の外にある chezmoi のソースディレクトリを一覧に足す
    test -d $HOME/.local/share/chezmoi; and echo $HOME/.local/share/chezmoi
end

function git_all_pull_ff_only
    # Run 'git pull --ff-only' in all repositories (8 repos in parallel)
    __git_all_repos | xargs -P 8 -I{} sh -c \
        'git -C "$1" pull --ff-only --quiet && echo "$1: pulled" || echo "$1: pull failed"' _ {}
end

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

function git_all_fetch
    # Fetch in all repositories (8 repos in parallel)
    __git_all_repos | xargs -P 8 -I{} sh -c \
        'git -C "$1" fetch --quiet && echo "$1: fetched" || echo "$1: fetch failed"' _ {}
end
