# dotfiles (chezmoi source)

macOS / Ubuntu / Debian / Windows 向け dotfiles を [chezmoi](https://www.chezmoi.io/) で管理するリポジトリで、リポジトリ自体が chezmoi の source ディレクトリ。
セットアップ手順とディレクトリ構成は README.md にある。
共通の作業規約は `home/dot_config/agents/AGENTS.md` (適用先 `~/.config/agents/AGENTS.md`) にあり、本書にはこのリポジトリ固有の契約だけを書く。
`home/` 配下のパス (`dot_*`・`.chezmoi*`・`modify_*` 等) は `home/` を省いて書くことがある。

## source の編集

- `.chezmoiroot` = `home` のため、chezmoi の source root は `home/`。
  共通規約の「コード」節のとおり、`$HOME` 配下の dotfiles (例: `~/.claude/`・`~/.config/`・`~/.zprofile`) は `home/` 以下の source を編集して `chezmoi apply` で反映する。
  適用先を直接編集しても、次の apply で上書きされる。
- source はファイルを直接編集する。
  chezmoi の設定が `[git] autoCommit = true / autoPush = true` (`home/.chezmoi.toml.tmpl`) なので、`chezmoi add` / `chezmoi edit` など chezmoi コマンド経由で source を変えると commit + push まで自動で走る。
- ファイル名は chezmoi の source state 属性 (`dot_`・`private_`・`modify_`・`.tmpl` 等) に従う。このリポジトリ固有の扱いは次の 2 つ。
  - `modify_private_dot_claude.json` は、`~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ置き換える chezmoi:modify-template。
    `.tmpl` を付けると二重にテンプレート処理されるので付けない。
    マシンローカルな状態 (ログイン情報・`projects`・識別子等。キーはテンプレート内の list) だけ既存値を温存し、Claude Code が実行時に書くその他のランタイム状態 (カウンタ・キャッシュ等) は apply のたびにリセットされる。
    chezmoi 内部で実行されるため外部 interpreter が要らず、Windows でも動く。
  - `~/.claude/settings.json` は通常テンプレート (`dot_claude/private_settings.json.tmpl`) で全量管理する。
    外部ツール (ローカルデーモン等) が実行時に注入する hooks は apply のたびに消える。
    hooks 配列の部分マージは脆いため意図して全量管理にしており、温存が必要になったら modify-template 化を検討する。

## コードから読み取れない契約

- `install/` の OS 別スクリプトは、`.chezmoiscripts` の各テンプレートが include して 1 つの bash プロセスに順に連結する。
  共通 helper の `install/lib.sh` (Windows は `install/windows/lib.ps1`) は各テンプレートが先頭で 1 回 include し、各スクリプトは単体実行時だけ冒頭のガードで読み込む。
  - 各スクリプトは関数を定義し、末尾の `[[ ${BASH_SOURCE[0]} == $0 ]]` ガードから自分の entry (`main` 等) を呼んで終える。
    同名関数 (`main` / `update` 等) は後続スクリプトが再定義するだけで害は無いので、prefix で rename しない。
  - 後続スクリプトに波及するため、`lib.sh` の helper の再定義、他スクリプトの関数・top-level 変数への依存、`exit 0` による早期終了、`cd` / `export` / `set` の変更は書かない。
  - テンプレートからスクリプトへは環境変数で値を渡す。
    Claude plugin は `CLAUDE_MARKETPLACES` / `CLAUDE_PLUGINS`、CLI / GUI の導入レベルは `SKIP_CLI_TOOLS` (macOS / Debian) / `SKIP_GUI_TOOLS` (macOS)。
  - `lib.sh` は各テンプレートに展開されるため、変更するとこれを include する `run_once_*` / `run_onchange_*` が全て再実行される。
- `home/.chezmoidata.toml` はテンプレート共有データの単一ソースで、値を他のファイルに複製しない。
  - `github`: GitHub ユーザー名。`dot_config/gh/private_hosts.yml.tmpl` が読む。
  - `mcp`: MCP の版 pin。
  - `claude.marketplaces` / `claude.plugins`: Claude plugin の marketplace と、plugin 一覧 + 有効フラグ。
    install スクリプトは有効なものだけ導入し、settings.json の `extraKnownMarketplaces` / `enabledPlugins` もここから描画する。
  - `agents`: サブエージェントの description。
  - `codex.subagent_model`: Codex の custom agent が使う model。
  - `agent_env`: Agent の shell の環境変数。bash / zsh / fish の `agent-env` と Codex の `shell_environment_policy.set` が読む。
    PowerShell は値が異なるため `install/windows/setup_powershell.ps1` に別に持つ。
  - `ssh_keys`: 1Password から取得する SSH 鍵の一覧。`.chezmoiignore` の除外対象と、`private_dot_ssh/**/private_<name>.tmpl` / `<name>.pub.tmpl` の item 参照が読む。
- bash / zsh で共有する環境変数・PATH・ツール統合は `dot_config/shell/` (`env.sh`・`integrations.sh`) に書き、`dot_bash_profile` / `dot_zprofile` はそれを source する。
  Agent 用の環境変数を出す `dot_config/shell/agent-env.sh.tmpl` は、Claude Code の SessionStart hook も読む (README「Agent が使う shell」)。
- `tests/install` (install スクリプトの関数をスタブで検査) と `tests/docker` (`mise.toml` のバリアント表と CI matrix の一致) は、apply 済みの環境に依存しないので pre-push hook で回す。
  `tests/files` は apply 後の `$HOME` を検査し、`mise run test` で回す。
  skip_* による skip 判定は `tests/test_helper.bash` にある。
- 検証用 Docker イメージのバリアント表は `mise.toml` の `build-<tag>` タスクにあり、CI の matrix はこれを写す。
  chezmoi provisioning (導入 → apply → 掃除) は各 Dockerfile (`docker/Dockerfile.debian` / `docker/Dockerfile.alpine`) の最終 RUN にある。
  Ubuntu は `Dockerfile.debian` に `BASE_IMAGE=ubuntu:*` を渡して作る。

## data の skip_* フラグ

ツールの導入レベルは chezmoi data のフラグで制御する (プロンプトの詳細は README)。

- macOS / Linux は `skip_cli_tools` / `skip_gui_tools` (デフォルトはともに true = 最小構成。`skip_cli_tools=true` のとき `skip_gui_tools` は質問されず true 固定)、Windows は `skip_windows_extras`。
- `.chezmoiignore` (コーディングエージェント設定の除外)・`.chezmoiexternal.toml` (+ `.chezmoitemplates/external-fonts.toml`)・`dot_config/mise/config.toml.tmpl`・`run_once_*` / `run_onchange_*` スクリプト・`data.apiKeys` の生成条件・`tests/files/*.bats` の skip 判定が横断的に参照する。
- テンプレートで参照するときは、キー未定義の旧 config でも動くよう `dig "skip_cli_tools" false .` のフォールバック形を使う (既定 false = 全部入り)。
- 例外として次は dig の既定を true にし、`skip_cli_tools=false` を明示した環境でのみインストールする。
  `dot_config/mise/config.toml.tmpl` の言語ランタイム (go / java / node / pnpm)・LSP サーバー群、macOS 限定のクラウド / 開発 CLI 群 (awscli / aws-sso / flutter / gcloud / kubectl / stern / terraform / terragrunt)、node に依存する nanobanana MCP (`.chezmoiexternal.toml` / `run_onchange_after_95` / `.chezmoitemplates/claude.json`)。
- `apply_ssh_keys` は、`mise run apply-ssh-keys` が `--override-data` でその invocation だけ true にする data キー。
  `.chezmoi.toml.tmpl` には置かず config にも書かない (書くとそのマシンでは通常の `status` / `diff` でも 1Password から鍵を取得する)。
  参照は `dig "apply_ssh_keys" false .`。

## mise tasks

タスクは `mise.toml` の `[tasks]` にある。

- `mise run pre-commit` / `mise run pre-push` / `mise run test`: 検証 (下記「検証」)。
- `mise run apply` (`chezmoi apply --verbose`) / `mise run dry-run` (`chezmoi apply --dry-run --verbose --force`): どちらも `--verbose` 付きで、secret ファイルの diff を出しうる (下記「secret を出力しうるコマンド」)。
- `mise run apply-ssh-keys`: 1Password の SSH Key item から秘密鍵と公開鍵を取得し、`~/.ssh` 配下へ配置する。
- `mise run build-<tag> [--push]`: 検証用 Docker イメージのビルド (Ubuntu / Debian / Alpine の 7 バリアント)。
  各タスクは内部レシピ `docker-build` を呼び、`--push` は multi-arch build + push。
- `mise run decrypt-google-ime` / `mise run encrypt-google-ime`: Google IME 辞書の復号・再暗号化。
  辞書は age (単一共有鍵、`home/.chezmoi.toml.tmpl`) で暗号化した `settings/common/encrypted_google.ime.txt.age` で管理し、平文の `settings/common/google.ime.txt` は gitignore 済み。
  平文を編集したら encrypt タスクで再暗号化してから commit する。

## 検証

- 変更後は `mise run pre-commit` → `mise run pre-push` → `mise run test` を通す。
- prek の git hook は、commit 時に lint / format を、push 時にテンプレート全体の描画 (`chezmoi-dry-run` hook) と `tests/install` / `tests/docker` の bats を回す (`.pre-commit-config.yaml` の `default_stages` と `stages`)。
  `mise run pre-push` は同じ hook を作業ツリーに対して回す。
- テンプレートの描画確認は `chezmoi-dry-run` hook (`chezmoi apply --dry-run --force`) で行う。
  `--verbose` が無いので diff を出さない。
  `mise run dry-run` を使うなら、出力を捨てて exit code だけを見る (例: `mise run dry-run >/dev/null 2>&1`)。

### secret を出力しうるコマンド

secret の扱いは共通規約の「安全」節に従う。
このリポジトリで secret の実値を出力しうるコマンドは次のとおりで、実行前に出力を捨てるかマスクを組み込む。

- `chezmoi execute-template --init`: `home/.chezmoi.toml.tmpl` が fnox 注入の API キー (`GEMINI_API_KEY` 等) を `data.apiKeys` に平文展開する。
- `fnox exec -- printenv <KEY>` / `fnox exec -- env`: secret を復号した値を返す。
- `chezmoi apply --verbose` / `chezmoi diff` と、それを使う `mise run apply` / `mise run dry-run`: 対象範囲に secret ファイルが入ると、unified diff に実値がそのまま出る。
  secret ファイルは `.codex/.env`・`.codex/auth.json`・`~/.config/chezmoi/chezmoi.toml`・Takumi Guard token を埋め込む `~/.npmrc` / `~/.netrc`・`~/.config/pip/pip.conf`・`~/.config/uv/uv.toml` 等。
  secret ファイルが対象範囲に入るときは `chezmoi apply` に `--verbose` を付けず、`chezmoi diff` は target を絞るか出力をマスクする。
- `cat` / `git diff` で secret ファイルを直接読む。
- `--override-data '{"apply_ssh_keys": true}'` を付けた `chezmoi diff` / `chezmoi apply --verbose`: `.chezmoiignore` の除外が外れ、1Password から取得した SSH 秘密鍵が平文で出る。
  この data は `mise run apply-ssh-keys` の中でだけ渡し、検証コマンド (pre-push / test / dry-run) には渡さない。

値は `sed -E 's/=.*/=***/'` でマスクできる (引用符の有無や種類によらない)。それ以外はキー名だけを grep するか、`wc -c` 等で有無・長さだけを確かめる。

### 既知の偽失敗

- `.pre-commit-config.yaml` の dprint hook から `--allow-no-files` を外さない。
  prek は対象ファイルを複数バッチに分けて並列に `dprint fmt <subset>` を起動するため、あるバッチが `dprint.json` の `excludes` に全部マッチすると "No files found to format" (exit 14) で非決定的に失敗する。
  sandbox 起因の失敗と紛らわしいが別問題。

## LLM エージェント指示文の構成

指示文ファイルを編集するときは、先に `dot_claude/rules/agent-config.md` (編集の規範) を読む。
各ツールの settings・permission (Claude の settings*.json、Codex の config.toml / rules、Grok・Gemini の設定) を編集するときは `dot_claude/rules/claude-settings.md` を読む。
Claude Code ではこれが path-scoped rule として自動で読まれる。

- 共通規約は `dot_config/agents/AGENTS.md` の 1 箇所に書く。
  各ツールの adapter (下記) にはそのツール固有の機構だけを書き、共通ルールを複製しない。
  各 `*.tmpl` 先頭の来歴コメントは chezmoi テンプレートコメントなので描画されない。
- Claude Code: `dot_claude/CLAUDE.md` が `@~/.config/agents/AGENTS.md` で import する。
  `dot_claude/CLAUDE.md` の MCP 一覧には、ツール定義や server instructions に無い運用規範を持つサーバーだけを載せる (description は再掲しない)。
- Codex
  - `dot_codex/AGENTS.md.tmpl` が、共通 AGENTS.md と `.chezmoitemplates/codex/instructions.md` を連結する。
  - AGENTS.md は user role で注入されるため、Codex の base prompt (developer role) の既定動作 (質問形を実行の依頼とみなす、worktree や draft PR を自律的に作る等) を上書きできない。
    これと衝突する少数の契約だけを `.chezmoitemplates/codex/developer-instructions.md` に書き、`dot_codex/modify_private_config.toml` が top-level の `developer_instructions` に入れる。
  - custom agent は `dot_codex/agents/*.toml.tmpl`。model は `.chezmoidata.toml` の `[codex] subagent_model` を参照する。
    Codex は agent TOML の `sandbox_mode` / `mcp_servers` を無視して親の設定を継承するため、書かない。
    Codex の custom agent はブラウザ MCP を持てず (main config にも playwright / chrome-devtools を置かない)、CLI に内蔵ブラウザも無いので、browser_debugger は Codex には置かない。ブラウザ検証は Claude の browser-debugger で行う。
- Antigravity (Gemini)
  - 1 ファイルの上限 (下記「サイズ予算」) に収めるため、共通 AGENTS.md を `## git` 見出しの前後で分けて配る。
    前半は `dot_gemini/config/AGENTS.md.tmpl` → `~/.gemini/config/AGENTS.md`、後半と `.chezmoitemplates/gemini/instructions.md` は `dot_gemini/config/GEMINI.md.tmpl` → `~/.gemini/config/GEMINI.md`。
    どちらも frontmatter 無しの、常時有効な global rule になる。
  - 分割と上限の検査は `.chezmoitemplates/gemini/agents-md-part` が行う。
    見出しが見つからないときと、生成物が 24,000 bytes を超えたときは、テンプレートが fail して描画を止める。
    共通 AGENTS.md の `## git` 見出しを変えるときは、分割位置も合わせて直す。
  - Antigravity は `~/.claude/`・`~/.agents/`・CLAUDE.md を読まない。
- Grok
  - `dot_grok/AGENTS.md.tmpl` が、共通 AGENTS.md と `.chezmoitemplates/grok/instructions.md` を連結する。
  - Grok は `compat.claude` (`dot_grok/modify_private_config.toml`。`agents` cell が CLAUDE.md、`rules` / `skills` cell が各ディレクトリを制御する) により、`~/.claude/CLAUDE.md`・`~/.claude/rules` の全件 (`paths` を無視して常時)・`~/.claude/skills` を読む。`~/.claude/agents` は compat の設定にかかわらず読まれる。
    Grok は `@` import を展開しないため、CLAUDE.md 経由で AGENTS.md が二重に載ることはない。
  - `~/.grok/skills` のコピーは廃止し、`.chezmoiremove` で配布していた SKILL.md を適用先から消す。
    Grok は `~/.agents/skills` も読み、`~/.claude/skills` と同名の skill は `~/.agents/skills` 側を採る (中身は同じ include なので挙動は変わらない)。
- skills
  - 本体は `dot_claude/skills/<name>/SKILL.md`。
  - 共有の 9 本 (commit / deps / explain / improve-pr / pr / refactor / review / security / test) は、本体を include する wrapper で他のツールにも配る。
    Gemini は `dot_gemini/config/skills/<name>/SKILL.md.tmpl`、Codex は `dot_agents/skills/<name>/SKILL.md.tmpl` → `~/.agents/skills`。
    共有 skill の本文は他のツールからも読まれるので、Claude 固有の機構 (`$ARGUMENTS` の置換・Claude Code の tool 名) に依存させない。
  - commit / pr には `disable-model-invocation` を付けず、自然文の依頼でも起動する。
    skill を読み込んだことは git 操作の許可ではなく、操作してよいかは共通規約の「git」節 (ユーザーの明示指示) で決まる。
- サブエージェント
  - 本文は `.chezmoitemplates/agents/<name>.md`、description は `.chezmoidata.toml` の `[agents]` が単一ソース。
    Claude (`dot_claude/agents/*.md.tmpl`)・Codex (`dot_codex/agents/*.toml.tmpl`。`'''` リテラル内に展開)・Gemini (`dot_gemini/config/agents/*/agent.md.tmpl`) の各 wrapper が、include と `.agents.<name>` (キーは underscore。無いキーは描画時に fail する) で参照する。
  - browser-debugger は Claude だけに置く。
  - Codex / Gemini の code-reviewer・security-reviewer は、review / security skill の本文を frontmatter を剥いで追記する (`regexReplaceAll` は明示引数形で書く。パイプ形は空文字になる)。
    skill 本文に `'''` を含めると Codex の TOML が壊れる。
- `.chezmoitemplates/` 配下は chezmoi が起動時に全件 template として parse する。
  本文用のファイル (`agents/*.md`・`*/instructions.md` 等) に生の `{{` を書くと、include / includeTemplate のどちらで参照しても全 chezmoi コマンドが失敗するので、必要なら `{{ "{{" }}` でエスケープする。

### サイズ予算 (Antigravity)

- rule ファイル 1 つあたりの上限は 24,000 bytes で、include 展開後に計測され、超過分は行の境界で切り捨てられる ([公式 rules](https://antigravity.google/docs/rules))。
  単位は bytes なので、日本語 (UTF-8 で 1 文字 3 bytes) では約 8,000 文字になる。
  以前の 12,000 characters は legacy workflow ファイルの上限で、rules には当たらない。
- global と always_on の rule は、全体で 20,000 tokens の予算を共有する。このリポジトリで作業するときは直下の `AGENTS.md` も workspace の常時有効な rule としてこの予算に入り、3 つの中で最も大きいので、超過時は最初に pointer へ格下げされる。
  超過すると、大きいファイルから順に path と description だけの pointer に格下げされる。
- 共通 AGENTS.md か `.chezmoitemplates/gemini/instructions.md` を増やしたら、生成物の bytes を両方とも計測する。
  `wc -c` は LANG に依らず bytes を数える (`wc -m` は locale 依存)。

  ```sh
  chezmoi execute-template < home/dot_gemini/config/AGENTS.md.tmpl | wc -c
  chezmoi execute-template < home/dot_gemini/config/GEMINI.md.tmpl | wc -c
  ```
