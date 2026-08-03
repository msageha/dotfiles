function claude --wraps claude
    # GitHub MCP server (Claude Code の github plugin) が参照するトークンの遅延注入。
    # gh の OAuth トークンは回転しうるためファイルに置かず都度取得するが、
    # gh auth token は 1 回 ~170ms かかるためシェル起動時ではなく claude 起動時に払う。
    # gh 未導入・未ログイン時は設定しない
    if not set -q GITHUB_PERSONAL_ACCESS_TOKEN; and type -q gh
        set -l gh_token (gh auth token 2>/dev/null)
        if test -n "$gh_token"
            set -gx GITHUB_PERSONAL_ACCESS_TOKEN $gh_token
        end
    end
    command claude $argv
end
