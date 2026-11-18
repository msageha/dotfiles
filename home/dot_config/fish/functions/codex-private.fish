function codex-private --wraps codex --description 'Codex を個人アカウントで起動する'
    # ログインは CODEX_HOME ごとに保存されるので、codex と再ログインなしで使い分けられる。
    # 指示文・custom agent・rules は ~/.codex への symlink で共有する。
    # CLAUDE_CONFIG_DIR も渡すのは、session の中から呼ぶ claude も個人アカウントで動かすため
    set -lx CODEX_HOME ~/.codex-private
    set -lx CLAUDE_CONFIG_DIR ~/.claude-private
    codex $argv
end
