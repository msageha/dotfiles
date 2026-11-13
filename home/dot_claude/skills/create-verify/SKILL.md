---
name: create-verify
description: Creates or updates .claude/verify.sh, the script Claude Code's Stop hook runs for self-verification, as a thin wrapper around the repository's existing checks. Use when the user runs /create-verify.
disable-model-invocation: true
allowed-tools: Read, Grep, Glob, Bash, Edit, Write
---

# .claude/verify.sh の作成 / 更新

この skill の起動を作成の依頼とみなし、確認を待たずに作成 / 更新まで進める。
ただし、プロジェクトの CLAUDE.md / AGENTS.md が verify.sh を用意しない方針を明記しているときは、その記述を示し、作成するか確認してから進める。

## Goal

リポジトリに既にある検証手段を呼ぶだけの薄い wrapper として `.claude/verify.sh` を作成 / 更新し、`bash .claude/verify.sh` 1 回でそれらが全部走るようにする。

## Acceptance criteria

- `.claude/verify.sh` が実行可能 (`chmod +x`) で、`set -euo pipefail` を含む。
- 呼び出すコマンドはすべてリポジトリに既に存在するもの。
- いずれかの検証が落ちたら exit code 非ゼロで終了する。
- 依存ツールが PATH に無い検証は warning を出してスキップする。必須の入力・設定が欠けたら明示的なエラーで止めるという AGENTS.md「コード」節の規範に対する意図的な例外で、Stop hook を環境差で壊さないため。
- 既に `.claude/verify.sh` があれば、全体を上書きせず、既存の呼び出しを基に検出結果との差分だけを反映する。既存の呼び出しを削除するときは理由を報告する。
- 検証手段が 1 つも見つからなければ何も書かず、その旨と、検証基盤 (テスト / lint / dry-run 等) を整えてから再実行するよう報告して終える。

## Constraints

- 新しい検証基盤を作らない。テストファイル、Makefile ターゲット、`package.json` script、pre-commit 設定などは追加せず、検出だけを行う。
- `verify.sh` に検証ロジック (複雑な分岐や lint の処理) を書かず、呼び出し先に任せる。
- 副作用の大きい操作 (deploy / push / migrate / 実機ビルド / 長時間 E2E) は、検出しても呼ばずに報告だけする (Stop hook はターンを終えるたびに走るため)。
- ファイルを書き換える検査 (formatter の書き換えモード、`--fix` 付きの lint、それらを hook に含む `pre-commit run --all-files` やタスク) は呼ばない。ターンのたびに作業ツリーが変わり、作業中の差分に意図しない変更が混ざるため。代わりに、書き換えが必要なときに非ゼロで終わる check のモード (`--check` 等) を呼び、そのモードが無いものは除外して報告する。
- `.claude/` ディレクトリが無ければ作成する。`.gitignore` の状態は変更しない (ユーザー判断に委ねる)。
- 引数は使用しない。
- secret を出力し得るコマンド (対象ファイルの diff を出す dry-run、環境変数を一覧で出すコマンド等。それらを内包するタスクも含む) は候補にしない。
- secret を要する検証は、リポジトリが定める secret の注入の経路 (それを通すタスク等) で呼び、`verify.sh` に secret の値や取得処理を書かない。

## 手順

### 1. 既存の `.claude/verify.sh` を確認

存在すれば内容を読み、現状の検証構成を把握する。プロジェクトの CLAUDE.md / AGENTS.md も読み、verify.sh を用意しない方針が明記されていないかを確かめる。

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
- フロントエンド E2E (Playwright / Puppeteer / Chrome DevTools):
  - 既にテストファイル (`*.spec.ts` 等) と設定が揃っている場合のみ採用する。

採用する候補と、Constraints により除外した候補 (理由付き) を一覧で示し、そのまま作成 / 更新に進む。

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

新規作成時はこの雛形に検出した呼び出しを埋めて書き、`chmod +x` を付ける。各ブロックは例と同じ「ツールがあれば実行し、無ければ warn でスキップ」の形にし、埋めた後はプレースホルダ行と例のコメント (`# --- ... ---`・`# 例:` 以下) を消す。

### 4. 完了報告

ユーザーへの最終報告には以下を含める:

- 採用した検証コマンドの一覧
- 除外した候補とその理由 (副作用 / ファイルの書き換え / secret の出力 / 重い / 未整備)
- 新規作成 or 更新の別
- 作成 / 更新後に自分で 1 回実行した `bash .claude/verify.sh` の結果 (exit code・所要時間)
- warn でスキップされた項目と理由。スキップがあれば exit 0 でも全検証が通ったとは書かず、実行して通った項目と分けて書く
