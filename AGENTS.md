# dotfiles (chezmoi source)

dotfiles を [chezmoi](https://www.chezmoi.io/) で管理するリポジトリで、リポジトリ自体が chezmoi の source ディレクトリ。
セットアップ手順とディレクトリ構成は README.md にある。
共通の作業規約は `home/dot_config/agents/AGENTS.md` (適用先 `~/.config/agents/AGENTS.md`) にあり、本書にはこのリポジトリ固有の契約だけを書く。
`home/` 配下のパス (`dot_*`・`.chezmoi*`・`modify_*` 等) は `home/` を省いて書くことがある。

## source の編集

- `.chezmoiroot` = `home` のため、chezmoi の source root は `home/`。
- 共通規約の「git」節に従って worktree で source を編集したときは、反映と `tests/files` の検査を、その worktree を source にして自分の変更が及ぶ target に絞って行う。
  `chezmoi status --source <worktree> --path-style absolute` で target を見て、`chezmoi apply --source <worktree> <target>…` で反映し、その target を検査する `tests/files/<name>.bats` を `bats` で回す。`$PWD` を source とみなすテストがあるので、`bats` は worktree の root で実行する。
  `mise run apply-ssh-keys` などのタスクと、`--source` を付けない chezmoi コマンドは、この checkout (既定の source) を使う。
- source はファイルを直接編集する。
  chezmoi の設定が `[git] autoCommit = true / autoPush = true` (`home/.chezmoi.toml.tmpl`) なので、`chezmoi add` / `chezmoi edit` など chezmoi コマンド経由で source を変えると commit + push まで自動で走る。

## コードから読み取れない契約

- 対象は macOS の arm64 (Homebrew の installer が Intel Mac を受け付けない) と、Ubuntu (26.04 以降) / Debian (trixie 以降) / Windows の amd64 と arm64 (macOS と Linux は、OS が入れる vim が XDG の場所の vimrc を読む 9.1.0327 以降である版)。POSIX 側 (`install/{common,macos,debian,ubuntu,alpine}/`・bash / zsh / fish の設定) と Windows 側 (`install/windows/`・PowerShell の設定) は対になる実装なので、片方に入れた対策は他方にも入れる。
- `install/` の OS 別スクリプトは、`.chezmoiscripts` の各テンプレートが include して 1 つのプロセス (POSIX は bash、Windows は PowerShell) に順に連結する。
  共通 helper の `install/lib.sh` (Windows は `install/windows/lib.ps1`) は各テンプレートが先頭で 1 回 include し (変更すると、include する `run_once_*` / `run_onchange_*` が次の apply で全て再実行される)、各スクリプトは単体実行時だけ冒頭のガードで読み込む。
  - 各スクリプトは関数を定義し、末尾で自分の entry を呼んで終える (POSIX は `[[ ${BASH_SOURCE[0]} == $0 ]]` ガードから `main` 等を、Windows はガード無しで `Main` 等を呼ぶ)。
    同名関数 (`main` / `update` 等) は後続スクリプトが再定義するだけで害は無いので、prefix で rename しない。
  - 後続スクリプトに波及するため、`lib.sh` の helper の再定義、他スクリプトの関数・top-level 変数への依存、`exit 0` による早期終了、`cd` / `export` / `set` の変更は書かない (後続へ引き渡すための変更は除く。例: `winget.ps1` は、後続が `winget` を見つけられるよう `$env:Path` に足す)。
  - テンプレートからスクリプトへは環境変数で値を渡す。
  - パスは `XDG_*` を使わず `$HOME` 基準で書く (`$HOME/.config` 等)。chezmoi は `XDG_*` によらず固定のパスに配置し、`tests/install` は `HOME` だけを一時ディレクトリに差し替えるため。
- `home/.chezmoidata.toml` はテンプレート共有データの単一ソースで、値を他のファイルに複製しない。各キーの用途と読み手は同ファイルのコメントにある。
- bash / zsh で共有する環境変数・PATH・ツール統合は `dot_config/shell/` (`env.sh`・`integrations.sh`) に書く。
  Agent 用の環境変数を出す `dot_config/shell/agent-env.sh.tmpl` は、Claude Code の SessionStart hook も読む (`docs/agent-shell.md`)。
- `tests/install` (install スクリプトの関数をスタブで検査) と `tests/docker` (`mise.toml` のバリアント表と CI matrix の一致) は、apply 済みの環境に依存しないので pre-push hook で回す。
  `tests/files` は apply 後の `$HOME` を検査するので、`mise run test` (`bats -r tests/`。3 つ全てを回す) でだけ回る。

## chezmoi data のフラグ

ツールの導入レベルは chezmoi data のフラグで制御する (プロンプトの詳細は README)。

- macOS / Linux は `skip_cli_tools` / `skip_gui_tools` / `skip_secrets`、Windows は `skip_windows_extras`。
- テンプレートで参照するときは、キーが未定義の config (そのフラグを持たない OS・旧 config) でも描画できるよう `dig "skip_cli_tools" false .` のフォールバック形を使う (既定 false = 全部入り)。
- 例外として、言語ランタイム・LSP サーバー、macOS 限定のクラウド / 開発 CLI、node に依存する nanobanana MCP は dig の既定を true にし、`skip_cli_tools=false` を明示した環境でのみインストールする。
- `skip_secrets` は `install/common/secrets.sh` (`chezmoi init --apply` の後に単体で実行し、1Password から age 秘密鍵・API キー・SSH 秘密鍵を取得して適用する) だけが読む。キー未定義の旧 config で 1Password を呼ばないよう、既定を true にする。
- `apply_ssh_keys` は、`mise run apply-ssh-keys` と `install/common/secrets.sh` が `--override-data` でその invocation だけ true にする data キー。
  `.chezmoi.toml.tmpl` には置かず config にも書かない (書くとそのマシンでは通常の `status` / `diff` でも 1Password から鍵を取得する)。
  参照は `dig "apply_ssh_keys" false .`。

## mise tasks

- 平文の IME 辞書 (`settings/common/google.ime.txt`、gitignore 済み) を編集したら、commit の前に `mise run encrypt-google-ime` で再暗号化する。

## 検証

- 変更後は `mise run pre-commit` → `mise run pre-push` → `mise run test` を通す。worktree で編集したときは、`mise run test` の代わりに「source の編集」の手順で対象の `tests/files` を回す。
- prek の git hook は、commit 時に lint / format を、push 時にテンプレート全体の描画 (`chezmoi-dry-run` hook) と `tests/install` / `tests/docker` の bats を回す (`.pre-commit-config.yaml` の `default_stages` と `stages`)。
  `mise run pre-push` は同じ hook を作業ツリーに対して回す。
- テンプレートの描画確認は `chezmoi-dry-run` hook (既定の source ではなく、push しようとしている checkout を描画する) で行う。
  この hook は diff を出さないので、差分の範囲は `chezmoi status` (内容を出さず、status と path だけを出す) で確かめる。
- sandbox が作業ディレクトリの外への書き込みを拒否する環境 (Claude Code の sandbox・Codex の `workspace-write`) では、mise・dprint 等のキャッシュ (macOS は `~/Library/Caches/`。Codex では `~/.cache/` も) への書き込みが "Operation not permitted" で落ちる (コード起因ではない)。

### secret を出力しうるコマンド

secret の扱いは共通規約の「安全」節に従う。
このリポジトリで secret の実値を出力しうるコマンドは次のとおりで、実行前に出力を捨てるかマスクを組み込む。

- `chezmoi execute-template --init`: `home/.chezmoi.toml.tmpl` が fnox 注入の API キー (`GEMINI_API_KEY` 等) を `data.apiKeys` に平文展開する。
- `chezmoi data` / `chezmoi cat-config` / `chezmoi dump-config`: config に書かれた `data.apiKeys` を平文で出す。フラグの値は `chezmoi execute-template '{{ dig "skip_cli_tools" false . }}'` のようにキーを指定して読む。
- `fnox exec -- printenv <KEY>` / `fnox exec -- env`: secret を復号した値を返す。
- `pip config list` / `pip config debug`: `~/.config/pip/pip.conf` の token 入り index-url をそのまま出す。
- `chezmoi apply --verbose` / `chezmoi diff`: 対象範囲に secret ファイルが入ると、unified diff に実値がそのまま出る。
  secret ファイルは `~/.codex/.env`・`~/.config/chezmoi/chezmoi.toml` と、`data.apiKeys` を埋め込む template の適用先 (`~/.claude/settings.json`・`~/.claude.json`・`~/.claude-private/.claude.json`・`~/.gemini/settings.json`・`~/.gemini/config/mcp_config.json`・`~/.npmrc`・`~/.netrc`・`~/.config/pip/pip.conf`・`~/.config/uv/uv.toml`) 等。
  secret ファイルが対象範囲に入るときは `chezmoi apply` に `--verbose` を付けず、`chezmoi diff` は target を絞るか出力をマスクする。
- `cat` / `git diff` で secret ファイルを直接読む。
- `--override-data '{"apply_ssh_keys": true}'` を付けた `chezmoi diff` / `chezmoi apply --verbose`: `.chezmoiignore` の除外が外れ、1Password から取得した SSH 秘密鍵が平文で出る。検証コマンド (pre-push / test) には渡さない。

共通規約の `sed` によるマスクは、JSON・`.netrc`・鍵・値だけの出力 (`printenv <KEY>` 等) には効かないので、これらは出力を捨てるか、キー名だけを grep するか、有無・長さだけを確かめる。

## LLM エージェント指示文

LLM エージェントの指示文 (共通規約・各ツールの AGENTS.md / CLAUDE.md / GEMINI.md と補足・rules・skills・サブエージェント) と各ツールの設定を編集・レビューする前に、`docs/agent-instructions.md` (各ツールへの配り方・コードから読み取れない契約・サイズ予算) と `dot_claude/rules/agent-config.md` (編集の規範) を読む。
source は `dot_config/agents/`・`dot_claude/`・`dot_codex/`・`dot_gemini/`・`dot_grok/`・`dot_agents/`・`modify_private_dot_claude.json`・`.chezmoitemplates/{agents,codex,gemini,grok}/`・`.chezmoitemplates/claude.json`・`.chezmoidata.toml` の `[agents]` / `[codex]` にある。
