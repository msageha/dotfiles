---
name: test
description: "Runs the project's tests and fixes failures at their root cause until they pass. Use when the user asks to make tests pass or fix them (「通して」「直して」「green にして」), or to verify your own change. For a request only to run tests and report (「テスト回して」「結果見せて」), use the test-runner agent where available; without it, this skill runs the tests and reports without editing files."
argument-hint: "[test-pattern-or-file]"
---

# テスト実行と修正

テストを実行し、依頼が修正まで求めるとき (または自分の変更の検証として実行しているとき) だけ失敗を直す。実行だけの依頼ではファイルを変更しない (判定は手順 3)。

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
- 引数 (`$ARGUMENTS`。空または置換されない場合は依頼文) でテスト名・パターン・ファイルが指定されていればそれに合うテストを、無ければスイート全体を実行する
- 結果は件数 (passed / failed / skipped) と失敗したテスト名・該当ログの抜粋で示し、全文が必要なら一時ディレクトリ (`$TMPDIR` 等) に保存してパスを示す

### 3. モード判定
- 依頼が実行だけ (「テスト回して」「結果見せて」等) なら、結果と失敗の根本原因の仮説・修正案を報告して止まり、ファイルを変更しない。
- 修正まで求められた場合 (「通して」「直して」「green にして」、テストが通るところまで任された委譲)、または自分の変更の検証として実行している場合は次の「結果の対応」へ進む。

### 4. 結果の対応

Goal: 対象範囲のテストが通り、ベースライン (base ブランチ / 直近 green) に無かった失敗が残っていない状態にする

Acceptance criteria:
- 新規失敗がゼロ (ベースラインで既に落ちていた失敗は分けて報告し、依頼範囲に含まれるか不明なら修正前に確認する)
- 修正によって他のテストが破壊されていない
- 最終レポートに「失敗の根本原因」「適用した修正」「再実行結果 (コマンドと件数)」「pre-existing 失敗の一覧」が含まれている

Constraints:
- 失敗したテストと対応するソースを読み、根本原因 (テスト側か実装側か) を特定してから修正に入る
- 次の修正は、適用の前に計画 (対象・修正案・リスク) を示してユーザーの承認を取る (subagent として呼ばれた場合は報告して止まる):
  - 外から観測できる仕様の変更 (公開 API のシグネチャ・外部から観測できる挙動)
  - データ構造やマイグレーションの破壊的変更のうち、AGENTS.md「コード」が確認を求めるもの
  - テスト自体の削除・スキップ (自分の変更で検査として意味を失ったテストの削除は除く。AGENTS.md「検証と完了」)
  - 依頼が「テストを直して」とテスト側に限定されているときの実装側の修正 (項目ごとに報告して許可を得る)
- それ以外の修正 (実装のバグ、誤った assertion など) は委譲の範囲とみなし、修正・再実行・成功の確認まで続けてから結果を報告する
- 新しいテストはユーザーの指示があるときだけ足す

全テストが通ったら、件数とカバレッジ (取得できれば) を報告して完了する。
