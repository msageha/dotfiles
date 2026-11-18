function claude-private --wraps claude --description 'Claude Code を個人アカウントで起動する'
    # ログインは CLAUDE_CONFIG_DIR ごとに保存されるので、claude と再ログインなしで使い分けられる。
    # 設定・skill 等は ~/.claude への symlink で共有する。
    # CODEX_HOME も渡すのは、session の中から呼ぶ codex も個人アカウントで動かすため
    set -lx CLAUDE_CONFIG_DIR ~/.claude-private
    set -lx CODEX_HOME ~/.codex-private
    claude $argv
end
