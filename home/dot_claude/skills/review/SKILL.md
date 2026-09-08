---
name: review
description: Review the current working-tree diff, or a PR given by number / URL, as a senior engineer across correctness, security, performance, readability, maintainability, and whether the change should be made at all. Use when the user wants a code review of their uncommitted or recent changes or of a PR.
allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(gh pr diff:*), Bash(gh pr view:*)
disallowed-tools: Edit, Write, NotebookEdit
---

# コードレビュー

作業ツリーの差分を対象としてコードレビューを行う。

## Step 1: 変更の取得

以下を実行して変更内容を把握する:

- `git status --short` -- untracked の新規ファイルも対象に含める
- `git diff --stat` -- 変更ファイルの概要
- `git diff` -- 変更差分の本体

レビュー対象が PR 番号 / URL で指定されたときは、代わりに `gh pr diff <pr>` と `gh pr view <pr>` で差分と説明を取得する。

差分が空の場合はステージ済み (`git diff --cached`)、それも空なら base ブランチとの差分 (`git diff origin/<base>...HEAD`。base は呼び出し元の指定、無ければ `origin/HEAD`) を対象にする。いずれも無ければレビュー対象を確認事項として呼び出し元に返す。

## Step 2: レビュー

1. まず変更の全体像を把握し、変更の意図を推測する。
2. 各ファイルの変更を以下の観点で精査する:
   - **正確性**: ロジックの誤り、エッジケースの見落とし、off-by-one エラー
   - **セキュリティ**: インジェクション、XSS、認証・認可の不備、機密情報の露出
   - **パフォーマンス**: 不要なループ、N+1 クエリ、メモリリーク
   - **可読性**: 命名の適切さ、過度な複雑性、マジックナンバー
   - **保守性**: 現に 2 箇所以上へ現れた同一ロジックの重複 (責務を利用側に閉じるための類似関数の重複は指摘しない)、テスタビリティ
   - **設計・必要性**: 過剰設計 (現に要求されていない抽象・汎用化・互換レイヤー)、現実に起こり得ない事象への防護コード・validation、存在意義を一文で説明できない class や抽象、デッドコード、テストを通すためだけの本番コード、責務の誤配置
   - **方針**: 変更を入れること自体が妥当か。変更前の実装と比較し、入れない・既存の仕組みに委ねる選択肢や、柔軟性・性能・運用の劣化を判定する
   - **回帰**: 変更前と比べて劣化した点 (性能・出力品質・ツールの本質的な機能・read-only や tool 制限等の既存規約)。以前の方が良かった箇所は取り込み候補として個別に挙げる
   - **コメント・説明**: コードを読めば分かる自明なコメント、実装と一致しない docstring / description
   - **指示への忠実さ** (依頼文が示されたとき): 指示通りか、対応漏れ・スコープ外の変更が無いか
3. 必要に応じて関連ファイルを読み、変更のコンテキストを把握する。
4. PR 本文や報告のテスト結果 (件数・カバレッジ) は自分で実行して照合できた場合だけ確認済みとし、テストが無い変更箇所はカバレッジの穴として所見に挙げる。

## Step 3: 出力フォーマット

各指摘に通番を付け、以下の形式で報告する:

### N. [Critical / Major / Minor / Nit] 指摘タイトル
- **ファイル**: `path/to/file:行番号`
- **確度**: High / Medium / Low と検証方法 (実行して確認 / 読解のみ)
- **問題**: 何が問題か
- **修正案**: どう修正すべきか (コード例があれば含める)

最後に、確認して問題なしと判断した観点を列挙し、総評を 1-2 文で記載する。指摘がなければ、確認した範囲と安全と判断した根拠を述べる。
