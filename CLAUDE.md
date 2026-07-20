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
- `*.tmpl` → Go テンプレート (apply 時に展開。例: `dot_gitconfig.tmpl`, `dot_alias.tmpl`)
- `private_*` → パーミッション 600 で展開
- `modify_private_dot_claude.json` → `~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ
  置き換える chezmoi:modify-template (`.tmpl` を付けると二重テンプレート処理になるので付けない)。
  マシンローカルな状態 (`oauthAccount` / `projects` / `userID` / `machineID` /
  `officialMarketplaceAutoInstallAttempted` / `officialMarketplaceAutoInstalled`) のみ既存値を温存し、
  Claude Code が実行時に書き込むその他のランタイム状態 (カウンタ・キャッシュ等) は
  apply のたびにリセットされる。
  chezmoi 内部で実行されるため外部 interpreter 不要で Windows でも動く

## ディレクトリ構成

- `home/` — chezmoi source (展開対象の dotfiles 本体)
- `home/dot_claude/` — Claude Code のユーザースコープ設定 (`settings.json.tmpl`, `rules/`, `skills/`, `agents/`, `CLAUDE.md` 等)
- `install/` — OS 別セットアップスクリプト (`common/`, `macos/`, `debian/`, `ubuntu/`, `alpine/`, `windows/`)
- `settings/` — アプリ設定 (`common/`, `macos/`)
- `tests/` — bats テスト (`tests/files`, `tests/install`)
- `docker/` (`Dockerfile.debian` / `Dockerfile.alpine`) / `cloudbuild.yaml` — Ubuntu / Debian / Alpine 検証用イメージのビルド

## data の skip_* フラグ

ツール導入レベルは chezmoi data のフラグで制御する (プロンプトの詳細は README):
macOS / Linux は `skip_cli_tools` / `skip_gui_tools` (デフォルトはともに true = 最小構成。
`skip_cli_tools=true` のとき `skip_gui_tools` は質問されず true 固定)、
Windows は `skip_windows_extras`。
`.chezmoiignore` (コーディングエージェント設定の除外)・`dot_config/mise/config.toml.tmpl`・
`run_once_*` スクリプト・`data.apiKeys` の生成条件が横断的に参照する。
テンプレートで参照するときは、キー未定義の旧 config でも動くよう
`dig "skip_cli_tools" false .` のフォールバック形を使う (既定 false = 全部入り)。
例外: mise の言語ランタイム (go / java / node / pnpm) は dig 既定 true で、
`skip_cli_tools=false` を明示した環境でのみインストールする。

## コマンド (Makefile)

- `make apply` — `chezmoi apply --verbose` (実際に適用)
- `make dry_run` — `chezmoi apply --dry-run --verbose --force` (副作用なしの確認)
- `make pre-commit` — `prek run --all-files` (lint / format / shellcheck / hadolint / typos など。prek は mise で導入)
- `make test` — `bats -r tests/`
- `make build-ubuntu` など `build-*` — 検証用 Docker イメージのビルド (Ubuntu / Debian / Alpine の 7 バリアント)

## 検証

変更後は `make pre-commit` → `make test` → `make dry_run` が通ることを確認する。
このリポジトリの検証は上記の Make ターゲットで完結しており、`.claude/verify.sh` は用意しない
(lint / format / テストは pre-commit と bats が包含する)。
`.claude/` はローカル設定領域のためリポジトリ管理対象外。

**`chezmoi execute-template --init` の出力は必ずマスクして表示する**。
`home/.chezmoi.toml.tmpl` は fnox がシェル環境に注入した API キー (`GEMINI_API_KEY` 等) を
`data.apiKeys` に平文展開するため、生出力をそのまま表示するとシークレットが漏れる。
値を `sed -E 's/= ".+"/= "***"/'` 等でマスクするか、構造確認に必要なキー行だけを grep で抜き出す。

### 既知の偽失敗と切り分け

- Claude Code の sandbox 有効時は read deny (`~/.ssh`, `/**/.env*`) により `make test`
  (`tests/files/common.bats` の `~/.ssh/config` 存在チェック) や `chezmoi apply` / `diff` / `dry_run`
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
