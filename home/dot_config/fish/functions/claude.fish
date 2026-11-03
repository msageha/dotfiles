function claude --wraps claude
    # GitHub MCP server (Claude Code の github plugin) が使うトークンを注入する。gh の OAuth トークンは
    # 回転しうるためファイルに置かず、gh auth token (~170ms) はシェル起動時ではなくここで払う
    if not set -q GITHUB_PERSONAL_ACCESS_TOKEN; and type -q gh
        set -l gh_token (gh auth token 2>/dev/null)
        if test -n "$gh_token"
            set -gx GITHUB_PERSONAL_ACCESS_TOKEN $gh_token
        end
    end
    command claude $argv
end
