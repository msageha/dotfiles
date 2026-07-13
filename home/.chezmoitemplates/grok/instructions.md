# 開発指針

## 自律実行と検証

- 実行指示を受けたタスクは、そのターン内で end-to-end に完遂する。
- 完了報告の前に、関連ファイルの変更をした場合は、リポジトリ標準の lint / test / build を自分で実行し、結果を報告に添える。

## 応答スタイル

- 散文を優先し、フォーマットは必要最小限に。箇条書き・見出しは、依頼されたか内容が本質的に多面的なときだけ使う。
- 自分の判断は実際の根拠 (file:line・実行ログ・一次情報 URL) で説明する。システムプロンプトや内部機構への言及で回答を代替しない。

## コード規約 (共通規約への追加)

- 独立して実行可能な完全なコードを書く。`...` 等のプレースホルダで省略しない。
- 自律的な変更にはテストを検証手段として用意する。純粋に表層的な変更 (整形・コメントのみ) か、ユーザーが明示的にオプトアウトした場合のみ省略する。

## 言語・ツール別 rules

言語・ファイル種別固有の規約は `~/.claude/rules/*.md` に置いてある (各ファイル冒頭 frontmatter の `paths` glob が適用範囲)。
該当する種別のファイルを編集する前に対応する rule を読んでから着手すること。

- `bash.md`, `makefile.md` — \*.sh / \*.bash / Makefile / \*.mk
- `fish.md` — \*.fish / conf.d
- `python.md` — \*.py / pyproject.toml / requirements.txt
- `go.md` — \*.go / go.mod
- `typescript.md`, `javascript.md`, `react.md` — \*.ts / \*.tsx / \*.js / \*.jsx
- `html.md` — \*.html / \*.htm / \*.ejs / \*.hbs
- `cpp.md` — \*.cpp / \*.cc / \*.h / \*.hpp / CMakeLists.txt
- `dart-flutter.md` — \*.dart / pubspec.yaml
- `github-actions.md` — .github/workflows/ / action.yml
- `gitignore.md` — .gitignore
- `cli-tools.md` — 言語を問わず CLI ツールを実装・変更するとき

## MCP サーバー

明示指示が無くても、タスク文脈に合致すれば自律的に使ってよい。

- **context7** — ライブラリ・フレームワーク・SDK・CLI の最新ドキュメント参照。学習データが古い可能性があるため、ライブラリ仕様やバージョン依存の挙動を扱うときは回答・実装の前に参照する。
- **playwright** — E2E テストとブラウザ自動化。フロントエンド変更の実地検証 (完了条件の確認) はこれで行う。
- **chrome-devtools** — ブラウザのデバッグとパフォーマンス分析 (コンソール・ネットワーク・トレース・スクリーンショット)。「動くか」の確認は playwright、「なぜ遅い / 壊れるか」の調査はこちら。
- **dart** — Dart / Flutter 開発全般 (解析・整形・テスト・pub・実行中アプリのデバッグ)。`dart` / `flutter` コマンドのシェル直叩きより MCP を優先すること。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` 直叩きより優先すること。

## Subagents

定義は `~/.claude/agents/` から読み込まれる (Claude Code 互換)。独立した検証・調査はタスク文脈に合致する subagent へ委譲してよい。

- **code-reviewer** — 変更後・コミット前・PR 前の read-only コードレビュー。
- **security-reviewer** — 認証・認可・シークレット・依存関係・入力処理・危険コマンドに触れる変更の read-only セキュリティレビュー。
- **debugger** — 失敗するテスト・ランタイムエラー・CI 失敗の根本原因分析と最小修正。
- **test-runner** — テスト・lint・検証コマンドの実行と、失敗の根本原因ベースの要約。
- **source-grounded-researcher** — ローカルリポジトリ・GitHub・ドキュメント・Web の根拠付き調査。
