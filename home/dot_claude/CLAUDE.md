@~/.config/agents/AGENTS.md

## Operating principles

- プロジェクト直下に実行可能な `.claude/verify.sh` があれば Stop hook (Windows 以外) が自動実行するので、長期自律実行の完了条件にそのまま使う。無ければ既存の lint / test 手段を使い、新設が有用なら完了報告で `/create-verify` の実行を提案する。verify.sh の作成・修正の可否は AGENTS.md「検証と完了」のテスト・検証スクリプトの規約に従い、作成は `/create-verify` で行う。
- 長時間セッションでは早期の Read 結果がコンテキストから追い出されうる。Read ツールが「変更なし」として再読を拒否した場合は内容が消えているサインとみなし、`cat` 等 Bash 経由で確実に再読み込みする。
- 自前の sandbox を持つ子プロセス (codex CLI の `--sandbox` 等) を Claude の sandbox 内で起動すると、二重適用で `Operation not permitted` になり、Claude 側の sandbox 拒否としては報告されない。Claude の sandbox を有効にしていてこの症状が出たら、AGENTS.md「安全」のとおり sandbox を外して再実行し、外したことを報告に書く。

## Subagent への委譲

- カスタムエージェントの使い分け: 修正を続ける作業中の自分の変更のレビューは、独立 context の `code-reviewer` に委譲する。review skill は呼んだターンの残りで Edit / Write が外れる (disallowed-tools) ので、レビューで作業を終えるときだけ使う。セキュリティ観点が求められる変更では `security-reviewer` を併用し、別モデルの目は codex のレビュー (下の codex の項) で得る。
- モデルを固定していない汎用サブエージェント (general-purpose / Explore など) に探索を委譲するときは sonnet 級のモデルと低めの effort を指定し、レビュー・セキュリティなど誤りが高くつく作業には opus / fable 級のモデル + xhigh を使う。
- 独立性が要件のサブエージェント (ブラインド検証・N-way 投票など。規範は AGENTS.md「委譲」) は `subagent_type` を明示して spawn する (省略すると定義で固定したモデル・ツール制限が効かない)。親の会話全体を継承する `fork` 型は独立検証には使わない。

## MCP servers・plugins (autonomous use)

- **codex** (plugin + CLI。MCP ではない): 設計相談・セカンドオピニオン・コードと文書のレビュー。plugin の slash commands (`/codex:review` 等) は disable-model-invocation 指定によりユーザー専用のため、自律実行では Bash で `codex exec -s read-only --ignore-rules review` (コードレビュー。対象範囲・検証結果は PROMPT 本文で渡す。`--uncommitted` / `--base` は PROMPT と併用不可) / `codex exec -s read-only --ignore-rules` (自由形式の相談・文書レビュー) を使う。`~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので、skill の手順にあるものも含め read-only の `codex exec` には `--ignore-rules` を付ける (top-level の `codex review` はこの flag を受け付けない)。どちらも数分から 10 分超かかるので background で流し、待つ間は AGENTS.md「検証と完了」の型で進捗を報告する。
  - AGENTS.md の主担当としての独立した相談 (「事実と判断」) と提出前の独立レビュー (「検証と完了」) の別モデルには codex を使う。提案文書・戦略などコード以外の壁打ちにも使う。PROMPT の冒頭には、相談・レビューだけの依頼で結果を返せばよいことを書く (codex も同じ共通規約を読むので、書かないと自分を主担当とみなしうる)。
- **github** (plugin 由来): 認証は各シェルの `claude` ラッパー関数 (fish は `functions/claude.fish`、bash / zsh は `~/.config/shell/integrations.sh`) が起動時に `gh auth token` を `GITHUB_PERSONAL_ACCESS_TOKEN` へ注入して行う。接続に失敗したら `gh auth status` と、Claude を起動したシェルにその変数が入っているかを確認する。
- **playwright / chrome-devtools**: スナップショット・コンソールログ等のノイズの多い出力を伴う作業は、同じ MCP を持つ `browser-debugger` への委譲を優先する。
- **nano-banana**: 画像アセット (アイコン・素材画像等) の生成を求められたときに使う。
