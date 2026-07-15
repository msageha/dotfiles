# 開発指針

## 自律実行と検証

- 実行指示を受けたタスクは、そのターン内で end-to-end に完遂する。
- 完了報告の前に、関連ファイルの変更をした場合は、リポジトリ標準の lint / test / build を自分で実行し、結果を報告に添える。
- 検証が期待どおりに通らなくても、パッチ全体を安易に巻き戻して終わらない。原因の仮説を複数 (目安 3 つ) 立てて順に検証し、各試行の後に関連テストを回す。それでも解決しない場合に限り変更を巻き戻し、得られた知見と次に試すべき実験を要約して報告する。
- 難しそうに見えるタスクを「不可能」と早期に結論づけない。スコープ内で bounded な前進を続け、不確実性は不確実と明記する。

## サブエージェントへの委譲

- 探索・テスト実行・ログ解析・大量ファイルのスキャンなど、ノイズの多い中間出力を伴う作業は main thread で行わずサブエージェントに委譲し、要約だけを受け取る (main thread の context 汚染・劣化を防ぐ)。
- 委譲時は、作業の分割方法・全員の完了を待つか・返すべき要約の形式をプロンプトで明示する。
- カスタムエージェント : `code_reviewer` / `security_reviewer` (誤りが高くつくレビュー用) / `debugger` (具体的な失敗の根本原因分析)、`test_runner` (検証コマンド実行) / `source_grounded_researcher` (調査) / `browser_debugger` (playwright / chrome-devtools MCP を内包)。
- モデルを固定していない探索系サブエージェントには gpt-5.6-terra 級のモデルと低めの reasoning effort を指定し、レビュー・セキュリティなど誤りが高くつく作業には sol・high を使う。

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
- **playwright / chrome-devtools** — main config には載せず `browser_debugger` サブエージェント専属にしてある。フロントエンド変更の実地検証 (「動くか」= playwright) やブラウザのデバッグ・パフォーマンス分析 (「なぜ遅い / 壊れるか」= chrome-devtools) が必要なときは `browser_debugger` に委譲する。
- **dart** — Dart / Flutter 開発全般 (解析・整形・テスト・pub・実行中アプリのデバッグ)。`dart` / `flutter` コマンドのシェル直叩きより MCP を優先すること。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` 直叩きより優先すること。
