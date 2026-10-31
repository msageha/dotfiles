# Codex 固有の補足

## サブエージェント

- custom agent (`~/.codex/agents/*.toml`) の使い分け: 自分の変更のレビューは `code_reviewer`、セキュリティ観点が要る変更は `security_reviewer` を併用、具体的な失敗の根本原因の調査と最小修正は `debugger`、出典付きの調査は `source_grounded_researcher`、出力を隔離したいテスト・lint の実行と要約は `test_runner`。モデルは {{ .codex.subagent_model }} に固定してある。
- Codex は agent ごとの sandbox を強制せず、子は親の sandbox を継承する。reviewer・researcher・test_runner がファイルを変更しないのは指示による取り決めで、sandbox で隔離したいレビューは Codex の外 (ユーザーのシェル等) から `codex exec -s read-only --ignore-rules` で行う (`~/.codex/rules/` の allow に一致するコマンドは sandbox の外で実行されるので `--ignore-rules` で外す。Codex の中から起動すると sandbox が二重にかかって失敗しうる)。
- 独立レビュー (code_reviewer / security_reviewer) は `fork_turns="none"` で spawn し、必要な事実は message で渡す。既定の全履歴 fork は生成側の推論を引き継ぐので独立にならない。
- 組み込みの agent (explorer / worker / default) に探索を任せるときは低めの reasoning effort を、レビュー・セキュリティなど誤りが高くつく作業には {{ .codex.subagent_model }} と xhigh を指定する。

## 言語・ツール別 rules

該当する種別のファイルを編集する前に `ls ~/.claude/rules/` で対応する rule を読んでから着手する。

## MCP サーバーとブラウザ

- playwright / chrome-devtools MCP は Codex に置いていない。実ブラウザでの確認は、使えるブラウザ・画面操作の tool (computer use の `cua_repl` 等) があればそれで行い、無ければプロジェクトの E2E を shell で回す。どちらもできないときだけ未検証と報告する。
- **dart** (macOS のみ) — Dart / Flutter 開発全般 (解析・整形・テスト・pub・実行中アプリのデバッグ)。`dart` / `flutter` コマンドのシェル直叩きより MCP を優先する。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` 直叩きより優先する。
