# 開発指針

## サブエージェントへの委譲

- カスタムエージェント (`~/.codex/agents/*.toml`、モデル・reasoning effort は固定済み): `code_reviewer` / `security_reviewer` (いずれも read-only) / `debugger` / `test_runner` / `source_grounded_researcher` / `browser_debugger`。役割は各 description。
- モデルを固定していない探索系サブエージェントには gpt-5.6-terra 級のモデルと低めの reasoning effort を指定し、レビュー・セキュリティなど誤りが高くつく作業には gpt-5.6-sol 級 + xhigh を使う。

## 言語・ツール別 rules

該当する種別のファイルを編集する前に `ls ~/.claude/rules/` で対応する rule を読んでから着手する。

## MCP サーバー

- **playwright / chrome-devtools** — main config には載せず `browser_debugger` サブエージェント専属にしてある。フロントエンド変更の実地検証 (「動くか」 = playwright) やブラウザのデバッグ・パフォーマンス分析 (「なぜ遅い / 壊れるか」 = chrome-devtools) が必要なときは `browser_debugger` に委譲する。
- **dart** (macOS のみ) — Dart / Flutter 開発全般 (解析・整形・テスト・pub・実行中アプリのデバッグ)。`dart` / `flutter` コマンドのシェル直叩きより MCP を優先する。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` 直叩きより優先する。
