function git_checkout_main
    set -l branch (__git_main_branch .)
    if test -z "$branch"
        echo "Neither 'main' nor 'master' branch found."
        return 1
    end
    echo "Checking out to the '$branch' branch."
    git checkout $branch
end
