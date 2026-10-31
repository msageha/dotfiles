---
name: create-verify
description: Analyzes a repository's existing verification mechanisms and creates or updates a thin .claude/verify.sh wrapper that the Stop hook runs for self-verification. Use when the user runs /create-verify to set up or refresh the project's verify.sh.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# .claude/verify.sh の作成 / 更新

リポジトリに既に存在する検証手段を呼び出すだけの薄い wrapper として `.claude/verify.sh` を作成 / 更新する。この skill の起動自体を作成の依頼とみなし、候補の一覧を示したうえで確認を待たずに作成 / 更新まで進める (例外は、プロジェクトの CLAUDE.md / AGENTS.md が verify.sh を用意しない方針を明記している場合。Constraints 参照)。

## Goal

リポジトリに既に存在する検証手段を集約し、`bash .claude/verify.sh` 一発で全部走るようにする。

## Acceptance criteria

- `.claude/verify.sh` が実行可能 (`chmod +x`) で、`set -euo pipefail` を含む。
- 呼び出すコマンドはすべてリポジトリに既に存在するもの。
- いずれかの検証が落ちたら exit code 非ゼロで終了する。
- 依存ツールが PATH に無い場合は warning を出してスキップする (verify.sh 自体は壊れない)。AGENTS.md の「コード」節 (暗黙のデフォルト・フォールバックでごまかさず停止する) の意図的な例外で、Stop hook を環境差で壊さないための設計。
- 既に `.claude/verify.sh` がある場合は、既存の呼び出しを尊重し、検出結果との差分だけを Edit で反映する (上書きで既存ロジックを壊さない)。既存の呼び出しを削除するときは理由を報告する。
- 検証手段が 1 つも見つからない場合は何も書かず、その旨と「検証基盤 (テスト / lint / dry-run 等) を整備した後に再度実行する」案内を報告して終了する。

## Constraints

- 新しい検証基盤を作らない。テストファイル、Makefile ターゲット、`package.json` script、pre-commit 設定などは追加せず、検出だけを行う。
- wrapper は薄く保つ。検証ロジック本体は呼び出し先に委ね、`verify.sh` 内で複雑な分岐や lint ロジックを書かない。
- 副作用の大きい操作 (deploy / push / migrate / 実機ビルド / 長時間 E2E) は Stop hook で走らせない (Stop hook はターンを終えるたびに走るため)。検出しても呼び出さず、報告にとどめる。
- `.claude/` ディレクトリが無ければ作成する。`.gitignore` の状態は変更しない (ユーザー判断に委ねる)。
- 引数は使用しない。
- プロジェクトの CLAUDE.md / AGENTS.md が verify.sh を用意しない方針を明記している場合だけ、その記述を示して作成するか確認を取ってから進める。
- secret を出力し得るコマンド (`chezmoi apply --dry-run --verbose`、`fnox exec -- env` 等。それらを内包する mise / make タスクも含む) は候補にしない。

## 手順

### 1. 既存の `.claude/verify.sh` を確認

存在すれば内容を読み、現状の検証構成を把握する。

### 2. リポジトリの検証手段を検出

以下を順に調査し、該当するものだけを採用する:

- タスクランナー / Makefile:
  - `Makefile` → `make test`, `make lint`, `make check`, `make verify`, `make pre-commit`, `make dry_run` など verify 系ターゲット
  - `Taskfile.yml`, `Justfile`, `mise.toml` の tasks
- 言語別テストランナー / lint (該当言語のマニフェストがある場合のみ):
  - `package.json` の `scripts` (test / lint / typecheck / check)
  - `pyproject.toml` (`pytest`, `ruff`, `mypy`, `pyright`)
  - `go.mod` (`go test ./...`, `go vet ./...`)
  - `Cargo.toml` (`cargo test`, `cargo clippy`, `cargo fmt --check`)
  - `pubspec.yaml` (`flutter test` / `dart test`, `dart analyze`)
- 横断的な lint:
  - `.pre-commit-config.yaml` → `pre-commit run --all-files` (または `--from-ref`)
  - `shellcheck` 対象の `.sh` がある場合
- chezmoi リポジトリ特有:
  - ルートに `.chezmoiroot` または `home/`, `dot_*` があれば `chezmoi apply --dry-run` を候補にする
- フロントエンド E2E (Playwright / Puppeteer / Chrome DevTools):
  - 既にテストファイル (`*.spec.ts` 等) と設定が揃っている場合のみ採用する。

採用する候補と、長時間 / 副作用ありで除外した候補 (理由付き) を一覧で示し、そのまま作成 / 更新に進む。

### 3. wrapper テンプレート (新規作成時の雛形)

```bash
#!/usr/bin/env bash
# Claude Code の Stop hook から実行される。リポジトリ既存の検証手段を呼ぶだけの wrapper で、検証ロジックはここに書かない。
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

新規作成時はこの雛形を Write し、`chmod +x` で実行権限を付与する。呼び出し行は検出結果に応じて埋める。各ブロックは「ツール存在チェック → 実行 or warn でスキップ」の対称な形を保つ。埋めた後はテンプレートのプレースホルダ行と例コメント (`# --- ... ---`、`# 例:` 以下) を削除する。

### 4. 完了報告

ユーザーへの最終報告には以下を含める:

- 採用した検証コマンドの一覧
- 除外した候補とその理由 (副作用 / 重い / 未整備)
- 新規作成 or 更新の別
- 作成 / 更新後に自分で 1 回実行した `bash .claude/verify.sh` の結果 (exit code・所要時間)
- warn でスキップされた項目と理由。スキップがあれば exit 0 でも全検証が通ったとは書かず、実行して通った項目と分けて書く
