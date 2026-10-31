# Antigravity 固有の補足

## 言語・ツール別 rules

該当する種別のファイルを編集する前に `ls ~/.claude/rules/` で対応する rule を読んでから着手する。

## MCP サーバー

- **playwright** — フロントエンド変更の実地検証 (「動くか」) に使う。
- **chrome-devtools** — ブラウザのデバッグとパフォーマンス分析 (「なぜ遅い / 壊れるか」) に使う。
- **dart** (macOS のみ) — Dart / Flutter 開発全般。`dart` / `flutter` の直叩きより優先する。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` の直叩きより優先する。
