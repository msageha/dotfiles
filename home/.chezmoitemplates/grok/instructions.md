# 開発指針

## 言語・ツール別 rules

`~/.claude/rules/*.md` (言語・ツール別規約) は Claude 互換モードにより全件が常時読み込まれている。編集対象のファイル種別に対応する rule だけを適用し、他の rule は無視する。

`~/.claude/CLAUDE.md` も同じ互換モードで読み込まれるが、そこに書かれた Claude Code 固有の機構 (Stop hook と `.claude/verify.sh`・`/create-verify`・codex / github / nano-banana MCP・sandbox の解除・Agent tool の `subagent_type` 等) は Grok に無い。無い機構は使わず提案もせず、既存の lint / test と本書の Subagents / Skills を使う。CLAUDE.md 冒頭の `@~/.config/agents/AGENTS.md` は Claude Code の import 記法で、指している先の内容は本書の「開発指針」より前と同一である。

## MCP サーバー

- **playwright** — フロントエンド変更の実地検証 (「動くか」) に使う。
- **chrome-devtools** — ブラウザのデバッグとパフォーマンス分析 (「なぜ遅い / 壊れるか」) に使う。
- **dart** (macOS のみ) — Dart / Flutter 開発全般 (解析・整形・テスト・pub・実行中アプリのデバッグ)。`dart` / `flutter` コマンドのシェル直叩きより MCP を優先する。
- **xcode** (macOS のみ) — Xcode プロジェクトのビルド・テスト・デバッグ。`xcodebuild` 直叩きより優先する。

## Subagents

定義は `~/.claude/agents/` から読み込まれる (Claude Code 互換): code-reviewer / security-reviewer / debugger / test-runner / source-grounded-researcher / browser-debugger。役割は各 description。独立した検証・調査はタスク文脈に合致する subagent へ委譲してよい。

## Skills

`~/.grok/skills/` に定義済み (commit / deps / explain / pr / refactor / review / security / test)。
