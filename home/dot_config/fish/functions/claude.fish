function claude --wraps claude
    # Claude Code の github plugin (GitHub MCP server) が読む GITHUB_PERSONAL_ACCESS_TOKEN を gh のトークンから入れる。
    # gh のアカウントの切り替えに追従するよう、ファイルにもこのシェルにも残さず、起動のたびに claude のプロセスにだけ渡す
    # (gh auth token はシェル起動を遅くしないよう、シェルの初期化ではなくここで呼ぶ)
    if not set -q GITHUB_PERSONAL_ACCESS_TOKEN; and type -q gh
        set -l gh_token (gh auth token 2>/dev/null)
        if test -n "$gh_token"
            set -fx GITHUB_PERSONAL_ACCESS_TOKEN $gh_token
        end
    end
    command claude $argv
end
