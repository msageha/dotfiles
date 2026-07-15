---
name: security
description: "Security review: detect vulnerabilities (injection, auth/authz, data protection, dependency, infra) in code and report them with CWE and severity. Use when the user wants a security review or vulnerability scan of a file, directory, or the whole project."
allowed-tools: Read, Grep, Glob, Bash(git log:*, git diff:*)
argument-hint: [file-or-directory]
---

# セキュリティレビュー

`$ARGUMENTS` を対象としてセキュリティレビューを行う。引数が未指定の場合はプロジェクト全体を対象とする。

## 検査項目

### インジェクション
- SQL インジェクション (パラメータ化されていないクエリ)
- コマンドインジェクション (ユーザー入力のシェル実行)
- XSS (未サニタイズの出力、dangerouslySetInnerHTML 等)
- パストラバーサル (未検証のファイルパス操作)
- テンプレートインジェクション

### 認証・認可
- ハードコードされた認証情報や API キー
- 不適切なセッション管理
- 認可チェックの欠落 (IDOR)
- 安全でないトークン生成・検証

### データ保護
- 機密情報の平文保存やログ出力
- 不適切な暗号化 (弱いアルゴリズム、固定 IV/salt)
- CORS の過剰な許可
- セキュリティヘッダーの欠落

### 依存関係とインフラ
- 既知の脆弱性を含む依存パッケージ
- 安全でないデシリアライゼーション
- デバッグモードや verbose エラーの本番環境露出
- 安全でないデフォルト設定

### その他
- レースコンディション / TOCTOU
- 整数オーバーフロー
- リソース枯渇 (ReDoS、無制限アップロード等)

## 出力フォーマット

各脆弱性を以下の形式で報告する:

### [Critical / High / Medium / Low] 脆弱性タイトル
- **CWE**: 該当する CWE 番号 (判明する場合)
- **ファイル**: `path/to/file:行番号`
- **説明**: 何が脆弱で、どう悪用されうるか
- **修正方法**: 具体的な修正コードまたは修正手順

最後にリスクの総合評価を記載する。脆弱性が検出されなかった場合もその旨を明記する。
