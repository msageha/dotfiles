# Agent が使う shell

bash / zsh / fish / PowerShell は、起動時に AI coding agent か人間かを判定して初期化を切り替える。権限や secret を隔離するものではない。

- Agent: `AI_AGENT` / `CLAUDECODE` / `CODEX_CI` / `CODEX_SANDBOX` / `GEMINI_CLI` / `CURSOR_AGENT` / `ANTIGRAVITY_AGENT` のどれかがあるか、`GROK_AGENT=1` のとき。`.chezmoidata.toml` の `agent_env` を export して、editor・pager・各 CLI の対話 prompt を止める (`GIT_EDITOR` だけは `true` にし、`git rebase --continue` などを既定のメッセージで進める)。
- 人間: Agent でなく、stdin / stdout が TTY の対話 shell (PowerShell は `-NonInteractive` とスクリプト実行を除く)。prompt・補完・alias・theme と fnox / direnv の hook を初期化する。

どちらでもない非対話 shell には何も足さない。VS Code などは TTY なしのログイン shell から環境を取り込んで統合ターミナルへ引き継ぐので、そこで Agent 用の値を入れると人間のターミナルに残るため。
PATH はどの shell でも設定し、project の環境は `mise exec --` / `fnox exec --` / `direnv exec .` で明示的に渡す。

- 判定に使う環境変数は子プロセスに継承されるので、Agent が起動した tmux server の pane も Agent 扱いになる。`DOTFILES_SHELL_MODE=human` / `agent` で判定を上書きでき (`human` は継承した `agent_env` も消す)、`tmux new-window -e DOTFILES_SHELL_MODE=human` のように範囲を絞って使う。
- Claude Code と Codex は、session の開始時に読んだ shell の状態を各コマンドで使い回す。Claude Code はこのとき export を落とすので、macOS / Linux では `SessionStart` hook が各コマンドの前に `~/.config/shell/agent-env.sh` を読ませる (native Windows には hook が無い)。Codex は `shell_environment_policy.set` で `agent_env` を渡す。
- mise は、人間の対話 shell では `mise activate`、それ以外では `mise activate --shims` を使う。親の shell で mise が activate 済みなら、mise の仕様で `--shims` は何もせず、親の PATH がそのまま使われる。
- Windows の PATH には `false` / `cat` が無いので、PowerShell 用の `agent_env` は `install/windows/setup_powershell.ps1` に持つ。
