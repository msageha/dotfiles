function __git_all_repos -d 'ghq 管理下のリポジトリと chezmoi の source のパスを一覧する'
    ghq list --full-path
    # ghq が失敗しても chezmoi の source は出し (リポジトリ検索の候補に残す)、失敗は status で返す
    set -l ghq_status $status
    # ghq root の外にある chezmoi のソースディレクトリを一覧に足す
    if test -d $HOME/.local/share/chezmoi
        echo $HOME/.local/share/chezmoi
    end
    return $ghq_status
end
