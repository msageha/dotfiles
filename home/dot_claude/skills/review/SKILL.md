---
name: review
description: Review the current working-tree diff as a senior engineer across correctness, security, performance, readability, and maintainability. Use when the user wants a code review of their uncommitted or recent changes.
allowed-tools: Read, Grep, Glob, Bash(git diff:*, git log:*, git show:*)
---

# コードレビュー

あなたはシニアソフトウェアエンジニアとしてコードレビューを行います。

## Step 1: 変更の取得

以下を実行して変更内容を把握する:

- `git diff --stat` -- 変更ファイルの概要
- `git diff` -- 変更差分の本体

差分が空の場合はステージ済み (`git diff --cached`) も確認し、それでも無ければユーザーにレビュー対象を確認する。

## Step 2: レビュー

1. まず変更の全体像を把握し、変更の意図を推測する。
2. 各ファイルの変更を以下の観点で精査する:
   - **正確性**: ロジックの誤り、エッジケースの見落とし、off-by-one エラー
   - **セキュリティ**: インジェクション、XSS、認証・認可の不備、機密情報の露出
   - **パフォーマンス**: 不要なループ、N+1 クエリ、メモリリーク
   - **可読性**: 命名の適切さ、過度な複雑性、マジックナンバー
   - **保守性**: DRY 原則違反、テスタビリティ、将来の変更への影響
3. 必要に応じて関連ファイルを読み、変更のコンテキストを把握する。

## Step 3: 出力フォーマット

各指摘を以下の形式で報告する:

### [Critical / Major / Minor / Nit] 指摘タイトル
- **ファイル**: `path/to/file:行番号`
- **問題**: 何が問題か
- **修正案**: どう修正すべきか (コード例があれば含める)

最後に総評を1-2文で記載する。指摘がなければ LGTM とする。
