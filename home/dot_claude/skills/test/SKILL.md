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
- 結果は件数 (passed / failed / skipped) と失敗したテスト名・該当ログの抜粋で示し、全文が必要なら一時ディレクトリ (`$TMPDIR` 等) に保存してパスを示す

### 3. モード判定
- 依頼が実行だけ (「テスト回して」「結果見せて」等) なら、結果と失敗の根本原因の仮説・修正案を報告して止まり、ファイルを変更しない。
- 修正まで求められた場合 (「通して」「直して」「green にして」、Goal 形式の委譲)、または自分の変更の検証として実行している場合は次の「結果の対応」へ進む。

### 4. 結果の対応

**Goal**: 対象範囲のテストが通り、ベースライン (base ブランチ / 直近 green) に無かった失敗が残っていない状態にする

**Acceptance criteria**:
- 新規失敗がゼロ (ベースラインで既に落ちていた失敗は分けて報告し、依頼範囲に含まれるか不明なら修正前に確認する)
- 修正によって他のテストが破壊されていない
- 最終レポートに「失敗の根本原因」「適用した修正」「再実行結果 (コマンドと件数)」「pre-existing 失敗の一覧」が含まれている

**Constraints**:
- テスト失敗時は根本原因 (テスト側の問題か実装側の問題か) を特定してから修正に入る
- 以下のケースに該当する場合のみ、修正を適用する前に確認を取る (subagent として呼ばれた場合は報告して止まる):
  - 仕様変更を伴う修正 (公開 API のシグネチャ変更、外部から観測できる挙動の変更)
  - データ構造やマイグレーションの破壊的変更
  - テスト自体の削除・スキップ
  - 依頼が「テストを直して」とテスト側に限定されているときの実装側の修正 (項目ごとに報告し、許可を得てから適用する)
- 上記以外の修正 (実装バグ修正、誤ったアサーションの修正など) は委譲範囲とみなし、修正→再実行→成功確認まで一括で実施してから結果を報告する
- 新しいテストの追加はユーザーの指示があるときのみ

**手順**:
- **全テスト成功**: テスト件数とカバレッジ (取得可能な場合) を報告して完了
- **テスト失敗**:
  1. 失敗したテストと対応するソースコードを読み込む
  2. 失敗の根本原因を特定する
  3. Constraints の確認対象に該当しなければ修正を適用し、再実行して成功を確認する
  4. 該当する場合は計画 (対象・修正案・リスク) を提示してユーザー承認を取る
