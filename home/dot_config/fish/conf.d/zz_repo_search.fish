# ctrl+g を chezmoi ソースを含むリポジトリ検索へ割り当て直す。
# decors/fish-ghq の conf.d/ghq_key_bindings.fish より後に読み込ませて上書きするため、
# ファイル名を z 始まりにしてソート順で後勝ちさせている。
bind \cg '__repo_search_with_chezmoi'
if bind -M insert >/dev/null 2>/dev/null
    bind -M insert \cg '__repo_search_with_chezmoi'
end
