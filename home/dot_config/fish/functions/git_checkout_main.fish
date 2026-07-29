function git_checkout_main
    set branch_main (git branch --list main)

    if test -n "$branch_main"
        echo "Checking out to the 'main' branch."
        git checkout main
        return 0
    end

    set branch_master (git branch --list master)

    if test -n "$branch_master"
        echo "Checking out to the 'master' branch."
        git checkout master
        return 0
    end

    echo "Neither 'main' nor 'master' branch found."
    return 1
end
