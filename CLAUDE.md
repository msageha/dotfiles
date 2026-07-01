# dotfiles (chezmoi source)

macOS / Ubuntu 向け dotfiles を [chezmoi](https://www.chezmoi.io/) で管理するリポジトリ。
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
- `modify_*` → 既存ファイルを書き換えるスクリプト。`modify_dot_claude.json.tmpl` は
  `~/.claude.json` の `mcpServers` だけを chezmoi 管理し、ランタイム状態 (カウンタ・キャッシュ等) は温存する

## ディレクトリ構成

- `home/` — chezmoi source (展開対象の dotfiles 本体)
- `home/dot_claude/` — Claude Code のユーザースコープ設定 (`settings.json.tmpl`, `rules/`, `skills/`, `CLAUDE.md`)
- `install/` — OS 別セットアップスクリプト (`common/`, `macos/`, `ubuntu/`)
- `settings/` — アプリ設定 (`vscode/`, `jetbrains/`, `macos/`, `common/`)
- `bin/` — 補助スクリプト
- `tests/` — bats テスト (`tests/files`, `tests/install`)
- `docker/Dockerfile.debian` / `cloudbuild.yaml` — Ubuntu 検証用イメージのビルド

## コマンド (Makefile)

- `make apply` — `chezmoi apply --verbose` (実際に適用)
- `make dry_run` — `chezmoi apply --dry-run --verbose --force` (副作用なしの確認)
- `make pre-commit` — `uvx pre-commit run --all-files` (lint / format / shellcheck / hadolint / typos など)
- `make test` — `bats -r tests/`
- `make build_image` — Ubuntu 検証用 Docker イメージのビルド

## 検証

変更後は `make pre-commit` → `make test` → `make dry_run` が通ることを確認する。
`.claude/` はローカル設定領域のためリポジトリ管理対象外。各環境で `.claude/verify.sh`
(実行可能ファイル) を用意すると Stop hook から自動実行され、上記を順に走らせる
(ツールが PATH に無ければ該当ステップは warn してスキップ)。
