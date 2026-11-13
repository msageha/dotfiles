# Agent が使う shell

bash / zsh / fish / PowerShell は、起動時に AI coding agent から起動されたか人間が使っているかを判定し、初期化の内容を切り替える。
agent の実行が editor・pager・対話 prompt の入力待ちで止まらないようにするためのもので、権限や secret を隔離するものではない。

- agent: 各 agent が子プロセスに付ける `AI_AGENT` / `CLAUDECODE` / `CODEX_CI` / `CODEX_SANDBOX` / `GEMINI_CLI` / `CURSOR_AGENT` / `ANTIGRAVITY_AGENT` のいずれかがあるか、`GROK_AGENT=1` のとき。
  `.chezmoidata.toml` の `agent_env` を export して、editor・pager・各 CLI の対話 prompt を止める。
  `GIT_EDITOR` だけは `true` にして、`git rebase --continue` などが既定のメッセージで進むようにする。
- 人間: agent ではなく、stdin と stdout が TTY の対話 shell のとき (PowerShell は `-NonInteractive` とスクリプト実行を除く)。
  prompt・補完・alias・theme と、fnox / direnv の hook を初期化する。
- どちらでもない非対話 shell: 何も足さない。
  VS Code などは TTY の無いログイン shell から環境を取り込んで統合ターミナルに引き継ぐので、ここで agent 用の値を入れると人間が使うターミナルに残るため。

PATH はどの場合も設定する。
人間の shell 以外では hook が project の環境を読み込まないので、`mise exec --` / `fnox exec --` / `direnv exec .` で明示的に渡す。

- 判定に使う環境変数は子プロセスに継承されるので、agent が起動した tmux server の pane も agent と判定される。
  `DOTFILES_SHELL_MODE=human` / `agent` で判定を上書きでき (`human` は継承した `agent_env` の値も消す)、`tmux new-window -e DOTFILES_SHELL_MODE=human` のように範囲を絞って使う。
- Claude Code と Codex は、session の開始時に読み込んだ shell の状態を各コマンドで使い回す。
  Claude Code はこのとき export された変数を引き継がないので、macOS / Linux では `SessionStart` hook が各コマンドの前に `~/.config/shell/agent-env.sh` を読み込ませる (native Windows ではこの hook を設定しない)。
  Codex には `shell_environment_policy.set` で `agent_env` を渡す。
- mise は、人間の shell では `mise activate`、それ以外では `mise activate --shims` で有効にする。
  親の shell で mise が activate 済みなら、mise の仕様で `--shims` は何もせず、親の PATH がそのまま使われる。
- Windows の PATH には `false` / `cat` が無いので、PowerShell 用の `agent_env` は `install/windows/setup_powershell.ps1` に別に持つ。
