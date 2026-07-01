function __repo_search_with_chezmoi -d 'Repository search (ghq + chezmoi source dir)'
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
            # ghq root の外にある chezmoi のソースディレクトリを一覧に足す
            begin
                ghq list --full-path
                test -d $HOME/.local/share/chezmoi; and echo $HOME/.local/share/chezmoi
            end | "$selector" $selector_options $flags | read select
        case \*
            printf "\nERROR: selector '$selector' is not supported.\n"
    end
    [ -n "$select" ]; and cd "$select"
    commandline -f repaint
end
