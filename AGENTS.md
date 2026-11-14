# dotfiles (chezmoi source)

dotfiles を [chezmoi](https://www.chezmoi.io/) で管理するリポジトリで、リポジトリ自体が chezmoi の source ディレクトリ。
セットアップ手順とディレクトリ構成は README.md にある。
共通の作業規約は `home/dot_config/agents/AGENTS.md` (適用先 `~/.config/agents/AGENTS.md`) にあり、本書にはこのリポジトリ固有の契約だけを書く。
`home/` 配下のパス (`dot_*`・`.chezmoi*`・`modify_*` 等) は `home/` を省いて書くことがある。

## source の編集

- `.chezmoiroot` = `home` のため、chezmoi の source root は `home/`。
  共通規約の「コード」節のとおり、`$HOME` 配下の dotfiles (例: `~/.claude/`・`~/.config/`・`~/.zprofile`) は `home/` 以下の source を編集して `chezmoi apply` で反映する。
  適用先を直接編集しても、次の apply で上書きされる。
- 共通規約の「git」節に従って worktree で source を編集したときは、反映と `tests/files` の検査を、その worktree を source にして自分の変更が及ぶ target に絞って行う (`chezmoi apply --source <worktree> <target>…`)。
  `mise run apply` などのタスクと、`--source` を付けない chezmoi コマンドは、この checkout (既定の source) を使う。
- source はファイルを直接編集する。
  chezmoi の設定が `[git] autoCommit = true / autoPush = true` (`home/.chezmoi.toml.tmpl`) なので、`chezmoi add` / `chezmoi edit` など chezmoi コマンド経由で source を変えると commit + push まで自動で走る。
- ファイル名は chezmoi の source state 属性 (`dot_`・`private_`・`modify_`・`.tmpl` 等) に従う。このリポジトリ固有の扱いは次の 2 つ。
  - `modify_private_dot_claude.json` は、`~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ置き換える chezmoi:modify-template。
    `.tmpl` を付けると二重にテンプレート処理されるので付けない。
    マシンローカルな状態 (ログイン情報・`projects`・識別子等。キーはテンプレート内の list) だけ既存値を温存し、Claude Code が実行時に書くその他のランタイム状態 (カウンタ・キャッシュ等) は apply のたびにリセットされる。
  - `~/.claude/settings.json` は通常テンプレート (`dot_claude/private_settings.json.tmpl`) で全量管理する。
    外部ツール (ローカルデーモン等) が実行時に注入する hooks は apply のたびに消える。
    hooks 配列の部分マージは脆いため、意図して全量管理にしている。
- `.chezmoitemplates/` 配下は chezmoi が起動時に全件 template として parse する。
  本文用のファイル (`agents/*.md`・`*/instructions.md` 等) に生の `{{` を書くと、include / includeTemplate のどちらで参照しても全 chezmoi コマンドが失敗するので、必要なら `{{ "{{" }}` でエスケープする。
- `.gitattributes` が無く Windows の checkout は CRLF になる (CI の `chezmoi-windows` も同じ)。
  include した本文を分割・正規表現で処理するテンプレートは、`replace "\r\n" "\n"` で改行をそろえるか、パターンを `\r?\n` で書く。

## コードから読み取れない契約

- 対象は macOS / Ubuntu / Debian / Windows の amd64 と arm64。POSIX 側 (`install/{common,macos,debian,ubuntu,alpine}/`・bash / zsh / fish の設定) と Windows 側 (`install/windows/`・PowerShell の設定) は対になる実装なので、片方に入れた対策は他方にも入れる。
- `install/` の OS 別スクリプトは、`.chezmoiscripts` の各テンプレートが include して 1 つの bash プロセスに順に連結する。
  共通 helper の `install/lib.sh` (Windows は `install/windows/lib.ps1`) は各テンプレートが先頭で 1 回 include し、各スクリプトは単体実行時だけ冒頭のガードで読み込む。
  - 各スクリプトは関数を定義し、末尾の `[[ ${BASH_SOURCE[0]} == $0 ]]` ガードから自分の entry (`main` 等) を呼んで終える。
    同名関数 (`main` / `update` 等) は後続スクリプトが再定義するだけで害は無いので、prefix で rename しない。
  - 後続スクリプトに波及するため、`lib.sh` の helper の再定義、他スクリプトの関数・top-level 変数への依存、`exit 0` による早期終了、`cd` / `export` / `set` の変更は書かない。
  - テンプレートからスクリプトへは環境変数で値を渡す。
  - `lib.sh` は各テンプレートに展開されるため、変更するとこれを include する `run_once_*` / `run_onchange_*` が全て再実行される。
- `home/.chezmoidata.toml` はテンプレート共有データの単一ソースで、値を他のファイルに複製しない。各キーの用途と読み手は同ファイルのコメントにある。
- bash / zsh で共有する環境変数・PATH・ツール統合は `dot_config/shell/` (`env.sh`・`integrations.sh`) に書く。
  Agent 用の環境変数を出す `dot_config/shell/agent-env.sh.tmpl` は、Claude Code の SessionStart hook も読む (`docs/agent-shell.md`)。
- `tests/install` (install スクリプトの関数をスタブで検査) と `tests/docker` (`mise.toml` のバリアント表と CI matrix の一致) は、apply 済みの環境に依存しないので pre-push hook で回す。
  `tests/files` は apply 後の `$HOME` を検査するので、`mise run test` (`bats -r tests/`。3 つ全てを回す) でだけ回る。

## chezmoi data のフラグ

ツールの導入レベルは chezmoi data のフラグで制御する (プロンプトの詳細は README)。

- macOS / Linux は `skip_cli_tools` / `skip_gui_tools` / `skip_secrets`、Windows は `skip_windows_extras`。
- テンプレートで参照するときは、キー未定義の旧 config でも動くよう `dig "skip_cli_tools" false .` のフォールバック形を使う (既定 false = 全部入り)。
- 例外として、言語ランタイム・LSP サーバー、macOS 限定のクラウド / 開発 CLI、node に依存する nanobanana MCP は dig の既定を true にし、`skip_cli_tools=false` を明示した環境でのみインストールする。
- `skip_secrets` は `install/common/secrets.sh` (`chezmoi init --apply` の後に単体で実行し、1Password から age 秘密鍵・API キー・SSH 秘密鍵を取得して適用する) だけが読む。キー未定義の旧 config で 1Password を呼ばないよう、既定を true にする。
- `apply_ssh_keys` は、`mise run apply-ssh-keys` と `install/common/secrets.sh` が `--override-data` でその invocation だけ true にする data キー。
  `.chezmoi.toml.tmpl` には置かず config にも書かない (書くとそのマシンでは通常の `status` / `diff` でも 1Password から鍵を取得する)。
  参照は `dig "apply_ssh_keys" false .`。

## mise tasks

- 平文の IME 辞書 (`settings/common/google.ime.txt`、gitignore 済み) を編集したら、`mise run encrypt-google-ime` で再暗号化してから commit する。

## 検証

- 変更後は `mise run pre-commit` → `mise run pre-push` → `mise run test` を通す。
- prek の git hook は、commit 時に lint / format を、push 時にテンプレート全体の描画 (`chezmoi-dry-run` hook) と `tests/install` / `tests/docker` の bats を回す (`.pre-commit-config.yaml` の `default_stages` と `stages`)。
  `mise run pre-push` は同じ hook を作業ツリーに対して回す。
- テンプレートの描画確認は `chezmoi-dry-run` hook (既定の source ではなく、push しようとしている checkout を描画する) で行う。
  この hook は diff を出さないので、差分の範囲は `chezmoi status` (内容を出さず、status と path だけを出す) で確かめる。

### secret を出力しうるコマンド

secret の扱いは共通規約の「安全」節に従う。
このリポジトリで secret の実値を出力しうるコマンドは次のとおりで、実行前に出力を捨てるかマスクを組み込む。

- `chezmoi execute-template --init`: `home/.chezmoi.toml.tmpl` が fnox 注入の API キー (`GEMINI_API_KEY` 等) を `data.apiKeys` に平文展開する。
- `fnox exec -- printenv <KEY>` / `fnox exec -- env`: secret を復号した値を返す。
- `chezmoi apply --verbose` / `chezmoi diff` と、それを使う `mise run apply` / `mise run dry-run`: 対象範囲に secret ファイルが入ると、unified diff に実値がそのまま出る (`mise run dry-run` は出力を捨てて exit code だけを見る)。
  secret ファイルは `.codex/.env`・`.codex/auth.json`・`~/.config/chezmoi/chezmoi.toml`・Takumi Guard token を埋め込む `~/.npmrc` / `~/.netrc`・`~/.config/pip/pip.conf`・`~/.config/uv/uv.toml` 等。
  secret ファイルが対象範囲に入るときは `chezmoi apply` に `--verbose` を付けず、`chezmoi diff` は target を絞るか出力をマスクする。
- `cat` / `git diff` で secret ファイルを直接読む。
- `--override-data '{"apply_ssh_keys": true}'` を付けた `chezmoi diff` / `chezmoi apply --verbose`: `.chezmoiignore` の除外が外れ、1Password から取得した SSH 秘密鍵が平文で出る。検証コマンド (pre-push / test / dry-run) には渡さない。

`KEY=value` 形式の行は `sed -E 's/=.*/=***/'` でマスクできる (引用符の有無や種類によらない)。JSON・`.netrc`・鍵・値だけの出力 (`printenv <KEY>` 等) には効かないので、出力を捨てるか、キー名だけを grep するか、`wc -c` 等で有無・長さだけを確かめる。

### 既知の偽失敗

- sandbox が作業ディレクトリの外への書き込みを拒否する環境 (Claude Code の sandbox・Codex の `workspace-write`) では、mise・dprint 等のキャッシュ (`~/Library/Caches/`・`~/.cache/`) への書き込みが "Operation not permitted" で落ちる。
  コード起因と決めつけず、sandbox を外して再実行して切り分ける。

## LLM エージェント指示文

LLM エージェントの指示文 (共通規約・各ツールの AGENTS.md / CLAUDE.md / GEMINI.md と補足・rules・skills・サブエージェント) と各ツールの設定を編集・レビューする前に、`docs/agent-instructions.md` (各ツールへの配り方・コードから読み取れない契約・サイズ予算) と `dot_claude/rules/agent-config.md` (編集の規範) を読む。
source は `dot_config/agents/`・`dot_claude/`・`dot_codex/`・`dot_gemini/`・`dot_grok/`・`dot_agents/`・`.chezmoitemplates/{agents,codex,gemini,grok}/`・`.chezmoidata.toml` の `[agents]` / `[codex]` にある。
