# ctrl+g: ghq + chezmoi source dir のリポジトリ検索
bind \cg __repo_search
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cg __repo_search
end
