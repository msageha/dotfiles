# ctrl+g を chezmoi source も含むリポジトリ検索に割り当てる。decors/fish-ghq の
# conf.d/ghq_key_bindings.fish の bind を上書きするため、ファイル名を z 始まりにして後に読ませる
bind \cg __repo_search_with_chezmoi
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cg __repo_search_with_chezmoi
end
