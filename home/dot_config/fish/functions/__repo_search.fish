function __repo_search -d 'Repository search (ghq + chezmoi source dir)'
    set -l selector
    [ -n "$GHQ_SELECTOR" ]; and set selector $GHQ_SELECTOR; or set selector fzf
    set -l selector_options
    [ -n "$GHQ_SELECTOR_OPTS" ]; and set selector_options $GHQ_SELECTOR_OPTS

    if not type -qf $selector
        printf "\nERROR: '$selector' not found.\n"
        return 1
    end

    set -l query (commandline -b)
    [ -n "$query" ]; and set flags --query="$query"; or set flags
    switch "$selector"
        case fzf fzf-tmux peco percol fzy sk
            __repo_list | "$selector" $selector_options $flags | read select
        case \*
            printf "\nERROR: selector '$selector' is not supported.\n"
    end
    [ -n "$select" ]; and cd "$select"
    commandline -f repaint
end
