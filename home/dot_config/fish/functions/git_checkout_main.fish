function git_checkout_main
    if git show-ref --verify --quiet refs/heads/main
        echo "Checking out to the 'main' branch."
        git checkout main
    else if git show-ref --verify --quiet refs/heads/master
        echo "Checking out to the 'master' branch."
        git checkout master
    else
        echo "Neither 'main' nor 'master' branch found."
        return 1
    end
end
