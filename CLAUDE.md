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
  マシンローカルな状態 (`oauthAccount` / `projects` / `userID` / `machineID`) のみ既存値を温存し、
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

## コマンド (Makefile)

- `make apply` — `chezmoi apply --verbose` (実際に適用)
- `make dry_run` — `chezmoi apply --dry-run --verbose --force` (副作用なしの確認)
- `make pre-commit` — `prek run --all-files` (lint / format / shellcheck / hadolint / typos など。prek は mise で導入)
- `make test` — `bats -r tests/`
- `make build-ubuntu` など `build-*` — 検証用 Docker イメージのビルド (Ubuntu / Debian / Alpine の 7 バリアント)

## 検証

変更後は `make pre-commit` → `make test` → `make dry_run` が通ることを確認する。
`.claude/` はローカル設定領域のためリポジトリ管理対象外。各環境で `.claude/verify.sh`
(実行可能ファイル) を用意すると Stop hook から自動実行され、上記を順に走らせる
(ツールが PATH に無ければ該当ステップは warn してスキップ)。
