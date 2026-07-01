---
name: create-verify
description: Analyze a repository's existing verification mechanisms and create or update a thin .claude/verify.sh wrapper that the Stop hook runs for self-verification. Use when the user wants to set up or refresh the project's verify.sh.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# .claude/verify.sh の作成 / 更新

リポジトリに既存する検証手段を呼び出すだけの薄い wrapper として `.claude/verify.sh` を作成 / 更新する。`.claude/verify.sh` は Claude Code の Stop hook (`~/.claude/settings.json` 経由) から自動実行され、セッション終了時の自己検証に使われる。

## Goal

リポジトリに既に存在する検証手段を集約し、`bash .claude/verify.sh` 一発で全部走るようにする。

## Acceptance criteria

- `.claude/verify.sh` が実行可能 (`chmod +x`) で、`set -euo pipefail` を含む。
- 呼び出されるコマンドは **すべてリポジトリに既存** している (新規にテスト基盤や Makefile ターゲットを生やさない)。
- いずれかの検証が落ちたら exit code 非ゼロで終了する。
- 依存ツールが PATH に無い場合は明示的に warning を出してスキップする (verify.sh 自体は壊れない)。
- 既に `.claude/verify.sh` が存在する場合は、検出した検証手段との差分を反映して **更新** する (上書きで既存ロジックを破壊しない)。
- 検証手段が見つからない場合は **何も書かずユーザーに報告して終了** する。

## Constraints

- **新しい検証基盤を勝手に作らない**。テストファイル、Makefile ターゲット、`package.json` script、pre-commit 設定などを新規追加してはならない。検出のみ行う。
- wrapper は薄く保つ。検証ロジック本体は呼び出し先に委ねる。`verify.sh` 内で複雑な分岐や lint ロジックを書かない。
- 副作用の大きい操作 (deploy / push / migrate / 実機ビルド / 長時間 E2E) は **Stop hook で走らせない**。検出しても呼び出さず、報告にとどめる。
- `.claude/` ディレクトリが無ければ作成する。`.gitignore` の状態は変更しない (ユーザー判断に委ねる)。
- 引数は使用しない。

## 手順

### 1. 既存の `.claude/verify.sh` を確認

- 存在すれば内容を読み、現状の検証構成を把握する。
- 既存ロジックを尊重し、追加 / 更新分のみを反映する方針にする。

### 2. リポジトリの検証手段を検出

以下を順に調査する。**該当するものだけ** を採用する:

- **タスクランナー / Makefile**:
  - `Makefile` → `make test`, `make lint`, `make check`, `make verify`, `make pre-commit`, `make dry_run` など verify 系ターゲット
  - `Taskfile.yml`, `Justfile`, `mise.toml` の tasks
- **言語別テストランナー / lint** (該当言語のマニフェストがある場合のみ):
  - `package.json` の `scripts` (test / lint / typecheck / check)
  - `pyproject.toml` (`pytest`, `ruff`, `mypy`, `pyright`)
  - `go.mod` (`go test ./...`, `go vet ./...`)
  - `Cargo.toml` (`cargo test`, `cargo clippy`, `cargo fmt --check`)
  - `pubspec.yaml` (`flutter test` / `dart test`, `dart analyze`)
- **横断的な lint**:
  - `.pre-commit-config.yaml` → `pre-commit run --all-files` (または `--from-ref`)
  - `shellcheck` 対象の `.sh` がある場合
- **chezmoi リポジトリ特有**:
  - ルートに `.chezmoiroot` または `home/`, `dot_*` があれば `chezmoi apply --dry-run` を候補にする
- **フロントエンド E2E** (Playwright / Puppeteer / Chrome DevTools):
  - 既にテストファイル (`*.spec.ts` 等) と設定が揃っている場合のみ採用。新規セットアップはしない。

検出した検証手段をリストアップし、ユーザーに **採用候補として一覧表示** する。長時間 / 副作用ありで除外したものも理由付きで明記する。

### 3. 分岐

- **検証手段が 1 つも無い場合**: ユーザーにその旨を報告し、`.claude/verify.sh` は **作成しない**。「適切な検証基盤 (テスト / lint / dry-run 等) を整備した後に再度実行してください」と案内して終了。
- **既に `.claude/verify.sh` がある場合**: Edit で差分のみ反映する。既存の呼び出しを削除する場合は理由をユーザーに報告する。
- **新規作成の場合**: 下記テンプレートを基に Write し、`chmod +x` で実行権限を付与する。

### 4. wrapper テンプレート (新規作成時の雛形)

```bash
#!/usr/bin/env bash
# Claude Code Stop hook verifier.
# Calls existing verification mechanisms in this repo.
set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

have() { command -v "$1" >/dev/null 2>&1; }
run()  { echo "==> $*"; "$@"; }
warn() { echo "verify.sh: $*" >&2; }

# --- 検出された検証手段をここに列挙する ---
# 例:
# if have make && grep -q '^test:' Makefile; then
#   run make test
# else
#   warn "skip: make test (unavailable)"
# fi
```

呼び出し行は検出結果に応じて埋める。各ブロックは「ツール存在チェック → 実行 or warn でスキップ」の対称な形を保つ。

### 5. 完了報告

ユーザーへの最終報告には以下を含める:

- 採用した検証コマンドの一覧
- 除外した候補とその理由 (副作用 / 重い / 未整備)
- 新規作成 or 更新の別
- `bash .claude/verify.sh` をユーザーが手動で 1 回試すよう促す
