function __git_all_repos -d 'List repository paths (ghq + chezmoi source dir)'
    ghq list --full-path
    # ghq root の外にある chezmoi のソースディレクトリを一覧に足す
    test -d $HOME/.local/share/chezmoi; and echo $HOME/.local/share/chezmoi
end
