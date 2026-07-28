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
