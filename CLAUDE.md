# dotfiles (chezmoi source)

macOS / Ubuntu / Debian / Windows 向け dotfiles を [chezmoi](https://www.chezmoi.io/) で管理するリポジトリ。
このリポジトリ自体が chezmoi の source ディレクトリ。

## 最重要: source を編集する

`.chezmoiroot` = `home` のため、chezmoi の source root は `home/`。
ホーム配下の dotfiles (例: `~/.claude/`, `~/.config/`, `~/.zprofile`) を変更したいときは、
**適用先 (`$HOME` 配下) を直接編集せず、必ず `home/` 以下の source を編集して `chezmoi apply` で反映する**。
適用先を直接いじると次回 apply で上書きされる。

## chezmoi 命名規約 (home/ 配下)

- `dot_foo` → `~/.foo`
- `dot_config/` → `~/.config/`
- `*.tmpl` → Go テンプレート (apply 時に展開。例: `dot_config/git/config.tmpl`, `dot_alias.tmpl`)
- `private_*` → パーミッション 600 で展開
- `modify_private_dot_claude.json` → `~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ
  置き換える chezmoi:modify-template (`.tmpl` を付けると二重テンプレート処理になるので付けない)。
  マシンローカルな状態 (`oauthAccount` / `projects` / `userID` / `machineID` /
  `officialMarketplaceAutoInstallAttempted` / `officialMarketplaceAutoInstalled`) のみ既存値を温存し、
  Claude Code が実行時に書き込むその他のランタイム状態 (カウンタ・キャッシュ等) は
  apply のたびにリセットされる。
  chezmoi 内部で実行されるため外部 interpreter 不要で Windows でも動く
- `~/.claude/settings.json` は通常テンプレート (`dot_claude/private_settings.json.tmpl`) で全量管理する。
  外部ツール (ローカルデーモン等) がランタイム注入する hooks は apply のたびに消える (意図的な裁定。
  hooks 配列の部分マージは脆いため、温存が必要になったら modify-template 化を検討する)

## ディレクトリ構成

- `home/` — chezmoi source (展開対象の dotfiles 本体)
- `home/dot_claude/` — Claude Code のユーザースコープ設定 (`private_settings.json.tmpl`, `rules/`, `skills/`, `agents/`, `CLAUDE.md` 等)
- `home/dot_config/shell/` — bash / zsh 共有の `env.sh` (環境変数・PATH) と `integrations.sh` (ツールのシェル統合)。`dot_bash_profile` / `dot_zprofile` はこれを source する薄い入口
- `home/.chezmoidata.toml` — テンプレート共有データ。MCP の版 pin (`mcp`)、Claude plugin の marketplace (`claude.marketplaces`) と plugin 一覧 + 有効フラグ (`claude.plugins`。install スクリプトは有効なものだけ導入し、settings.json の extraKnownMarketplaces / enabledPlugins はここから描画する単一ソース)、サブエージェントの description (`agents`)
- `install/` — OS 別セットアップスクリプト (`common/`, `macos/`, `debian/`, `ubuntu/`, `alpine/`, `windows/`)。`lib.sh` (bash) / `windows/lib.ps1` が共通 helper で、`.chezmoiscripts` の各テンプレートが先頭で 1 回 include し、各スクリプトは単体実行時だけ冒頭のガードで読み込む。include したスクリプトは 1 つの bash プロセスに順に連結されるため、各スクリプトは関数を定義したうえで末尾の `[[ ${BASH_SOURCE[0]} == $0 ]]` ガードから自分の entry (`main` 等) を呼び終える構造にする。同名関数 (`main` / `update` 等) は後続スクリプトが再定義するだけで害は無く、prefix での rename はしない。一方、`lib.sh` の helper の再定義、他スクリプトの関数・top-level 変数への依存、`exit 0` による早期終了、`cd` / `export` / `set` の変更は後続スクリプトに波及するため書かない。Claude plugin は `CLAUDE_MARKETPLACES` / `CLAUDE_PLUGINS` 環境変数、CLI / GUI 導入レベルは `SKIP_CLI_TOOLS` (macOS / Debian) / `SKIP_GUI_TOOLS` (macOS) としてテンプレートが export する契約。`lib.sh` は各テンプレートに展開されるため、その変更はこれを include する `run_once_*` / `run_onchange_*` を全て再実行させる
- `settings/` — アプリ設定 (`common/`, `macos/`)
- `tests/` — bats テスト (`tests/files` = apply 後の `$HOME` を検査、`tests/install` = install スクリプトの関数をスタブで検査 (apply 済みの環境に依存しないため pre-push hook で回す)、`tests/docker` = `mise.toml` のバリアント表と CI matrix の一致)。skip_* による skip 判定は `tests/test_helper.bash`
- `docker/` (`Dockerfile.debian` / `Dockerfile.alpine`) — Ubuntu / Debian / Alpine 検証用イメージの定義 (Ubuntu は `Dockerfile.debian` に `BASE_IMAGE=ubuntu:*` を渡して生成)。バリアント表は `mise.toml` の `build-<tag>` タスク、chezmoi provisioning (導入 → apply → 掃除) は各 Dockerfile の最終 RUN

## LLM エージェント指示文の構成

- 共通規約は `home/dot_config/agents/AGENTS.md` 1 箇所に書く。Claude Code は `dot_claude/CLAUDE.md` が `@~/.config/agents/AGENTS.md` で import し、
  Codex / Antigravity (Gemini) / Grok は各 `AGENTS.md.tmpl` が AGENTS.md + `.chezmoitemplates/<tool>/instructions.md` を連結して生成する。
  各 `AGENTS.md.tmpl` 先頭の来歴コメントは chezmoi テンプレートコメントなので描画されない。
  CLAUDE.md と各 instructions.md にはそのツール固有の機構だけを書き、共通ルールを複製しない
  (Grok は `compat.claude` で `~/.claude/CLAUDE.md` と全 rules も常時読み込む。Grok は `@` import を展開しないため、
  CLAUDE.md 経由で AGENTS.md が二重に載ることはない)。
- サイズ予算: Antigravity は rules ファイルを 12,000 文字 (公式ドキュメントの単位は characters) で切るため、
  `~/.gemini/config/AGENTS.md` の生成物 (AGENTS.md + gemini/instructions.md) を 11,700 文字以下に収める。
  AGENTS.md か gemini/instructions.md を増やしたら
  `chezmoi execute-template < home/dot_gemini/config/AGENTS.md.tmpl | python3 -c 'import sys; print(len(sys.stdin.read()))'`
  で生成物そのものを再計測する (`wc -m` は LANG=C だとバイト数になる)。
- サブエージェント定義の本文は `home/.chezmoitemplates/agents/<name>.md`、description は `home/.chezmoidata.toml` の `[agents]` が単一ソースで、Claude (`dot_claude/agents/*.md.tmpl`)・
  Codex (`dot_codex/agents/*.toml.tmpl`、`'''` リテラル内に展開)・Gemini (`dot_gemini/config/agents/*/agent.md.tmpl`) の各 wrapper が include / `.agents.<name>` (キーは underscore。無いキーは描画時に fail する) で参照する。
  Codex / Gemini の code-reviewer・security-reviewer は review / security skill 本文を frontmatter を剥いで追記する
  (`regexReplaceAll` は明示引数形。パイプ形は空文字になる)。skill 本文に `'''` を含めると Codex の TOML が壊れる。
  `.chezmoitemplates/` 配下は chezmoi が起動時に全件 template として parse するため、agents/*.md 本文に生の `{{` を書くと
  全 chezmoi コマンドが失敗する (include / includeTemplate のどちらで参照しても同じ)。必要なら `{{ "{{" }}` でエスケープする。
- `dot_claude/CLAUDE.md` の MCP 一覧は、ツール定義や server instructions に無い運用規範を持つサーバーだけを載せる (description の再掲はしない)。
- 指示文ファイルを編集するときの規範は `dot_claude/rules/agent-config.md` (path-scoped rule) にある。

## data の skip_* フラグ

ツール導入レベルは chezmoi data のフラグで制御する (プロンプトの詳細は README):
macOS / Linux は `skip_cli_tools` / `skip_gui_tools` (デフォルトはともに true = 最小構成。
`skip_cli_tools=true` のとき `skip_gui_tools` は質問されず true 固定)、
Windows は `skip_windows_extras`。
`.chezmoiignore` (コーディングエージェント設定の除外)・`.chezmoiexternal.toml` (+ `.chezmoitemplates/external-fonts.toml`)・
`dot_config/mise/config.toml.tmpl`・`run_once_*` / `run_onchange_*` スクリプト・`data.apiKeys` の生成条件・`tests/files/*.bats` の skip 判定が横断的に参照する。
テンプレートで参照するときは、キー未定義の旧 config でも動くよう
`dig "skip_cli_tools" false .` のフォールバック形を使う (既定 false = 全部入り)。
例外: `dot_config/mise/config.toml.tmpl` の言語ランタイム (go / java / node / pnpm)・LSP サーバー群と、
macOS 限定のクラウド / 開発 CLI 群 (awscli / aws-sso / flutter / gcloud / kubectl / stern /
terraform / terragrunt)、および node に依存する nanobanana MCP (`.chezmoiexternal.toml` / `run_onchange_after_95` /
`.chezmoitemplates/claude.json`) は dig 既定 true で、`skip_cli_tools=false` を明示した環境でのみインストールする。

## コマンド (mise tasks)

タスクは `mise.toml` の `[tasks]` で定義する。

- `mise run apply` — `chezmoi apply --verbose` (実際に適用)
- `mise run dry-run` — `chezmoi apply --dry-run --verbose --force` (副作用なしの確認)
- `mise run pre-commit` — `prek run --all-files` (lint / format / shellcheck / hadolint / typos など。prek は mise で導入)
- `mise run pre-push` — `prek run --all-files --hook-stage pre-push` (テンプレート描画 dry-run + `tests/install` / `tests/docker` の bats)
- `mise run test` — `bats -r tests/`
- `mise run build-<tag> [--push]` — 検証用 Docker イメージのビルド (Ubuntu / Debian / Alpine の 7 バリアント。バリアント表はこのタスク群)。各タスクは内部レシピ `docker-build` を呼び、`--push` は multi-arch build + push
- `mise run decrypt-google-ime` / `encrypt-google-ime` — Google IME 辞書の復号・再暗号化。
  リポジトリは age 暗号化 (単一共有鍵、`home/.chezmoi.toml.tmpl`) を使い、辞書は
  `settings/common/encrypted_google.ime.txt.age` で管理。平文 `google.ime.txt` は gitignore 済みで、
  編集後は encrypt タスクで再暗号化してからコミットする。

## 検証

変更後は `mise run pre-commit` → `mise run pre-push` → `mise run test` → `mise run dry-run` が通ることを確認する。
prek の git hook が commit 時に lint / format、push 時にテンプレート描画の dry-run と `tests/install` / `tests/docker` の bats を回す
(`.pre-commit-config.yaml` の `default_stages` と `stages`)。このリポジトリの検証はこれらで完結しており、`.claude/verify.sh` は用意しない。
`.claude/` はローカル設定領域のためリポジトリ管理対象外。

**secret を含み得る出力は実行前に必ずマスクする。「まず生で試して後でマスクする」は不可。**
このリポジトリで実際に secret 実値を出力しうるコマンド:

- `chezmoi execute-template --init` — `home/.chezmoi.toml.tmpl` が fnox 注入の API キー
  (`GEMINI_API_KEY` 等) を `data.apiKeys` に平文展開する。
- `fnox exec -- printenv <KEY>` / `fnox exec -- env` — secret を実際に復号した値を返す。
- `chezmoi apply --verbose` / `chezmoi diff` — 対象範囲に `.codex/.env`・`.codex/auth.json` や
  `~/.config/chezmoi/chezmoi.toml` 等の secret ファイルが含まれると、unified diff に実値がそのまま出る。
- `cat` / `git diff` で secret ファイルを直接読む。

値を `sed -E 's/= ".+"/= "***"/'` 等でマスクするか、キー名のみ grep で抜き出すか、`wc -c` 等で
有無・長さだけを確認する。secret ファイルが対象範囲に入るスコープで `chezmoi apply` / `diff` を
使うときは `--verbose` を付けない。fnox・1Password 経由の実行でも「ツールを使っている = 注意している」
にはならず、同じ確認を省略しない。

### 既知の偽失敗と切り分け

- Claude Code の sandbox 有効時は read deny (`~/.ssh`, `/**/.env*`) により `mise run test`
  (`tests/files/common.bats` の `~/.ssh/config` 存在チェック) や `chezmoi apply` / `diff` / `dry-run`
  (`~/.codex/.env` の lstat) が偽失敗する。write deny により `~/Library/Caches/mise|dprint` への
  書き込みも "Operation not permitted" になる。コード起因と決めつけず、sandbox を外して
  再実行して切り分ける。
- `.pre-commit-config.yaml` の dprint hook から `--allow-no-files` を外さない。prek は対象ファイルを
  複数バッチに分割して並列に `dprint fmt <subset>` を起動するため、あるバッチが dprint.json の
  `excludes` に全部マッチすると "No files found to format" (exit 14) で非決定的に失敗する
  (sandbox 起因の失敗と紛らわしいが別問題)。

### git 運用の注意

chezmoi 設定は `[git] autoCommit = true / autoPush = true` (`home/.chezmoi.toml.tmpl`) のため、
`chezmoi add` / `chezmoi edit` など chezmoi コマンド経由で source を変更すると自動で
commit + push まで走る。意図しない push を避けるため、source はファイルを直接編集する。
