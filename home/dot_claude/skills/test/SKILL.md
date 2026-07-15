---
name: test
description: "Test runner: detect the project's test runner, execute the suite (or a matching subset), and on failure analyze the root cause and fix it. Use when the user wants to run tests or get a failing test suite green."
allowed-tools: Read, Grep, Glob, Bash, Edit
argument-hint: [test-pattern-or-file]
---

# テスト実行と修正

テストの実行と結果対応を行う。

## 手順

### 1. テスト環境の検出
プロジェクトの構成ファイルからテストフレームワークとランナーを特定する:
- package.json → Jest / Vitest / Mocha
- pyproject.toml / setup.cfg → pytest
- go.mod → go test
- pubspec.yaml → flutter test / dart test
- Cargo.toml → cargo test
- Makefile / Taskfile → カスタムターゲット

### 2. テストの実行
- 引数が指定されている場合: `$ARGUMENTS` にマッチするテストを実行
- 引数がない場合: テストスイート全体を実行
- 出力をそのまま表示する

### 3. 結果の対応

**Goal**: テストスイートが緑になっている状態にする

**Acceptance criteria**:
- すべてのテストがパスしている
- 修正によって他のテストが破壊されていない
- 最終レポートに「失敗の根本原因」「適用した修正」「再実行結果」が含まれている

**Constraints**:
- テスト失敗時は根本原因 (テスト側の問題か実装側の問題か) を特定してから修正に入る
- 以下のケースに該当する場合のみ、修正を適用する前にユーザーに確認する:
  - 仕様変更を伴う修正 (公開 API のシグネチャ変更、外部から観測できる挙動の変更)
  - データ構造やマイグレーションの破壊的変更
  - テスト自体の削除・スキップ
- 上記以外の修正 (実装バグ修正、誤ったアサーションの修正など) は委譲範囲とみなし、修正→再実行→成功確認まで一括で実施してから結果を報告する

**手順**:
- **全テスト成功**: テスト件数とカバレッジ (取得可能な場合) を報告して完了
- **テスト失敗**:
  1. 失敗したテストと対応するソースコードを読み込む
  2. 失敗の根本原因を特定する
  3. Constraints の確認対象に該当しなければ修正を適用し、再実行して成功を確認する
  4. 該当する場合は計画 (対象・修正案・リスク) を提示してユーザー承認を取る
