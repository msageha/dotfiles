# Grok 固有の補足

- `~/.claude/rules/*.md` は Claude 互換モードで全件が常時読み込まれ、frontmatter の `paths` は効かない。編集対象のファイル種別に対応する rule だけを適用し、他の rule は無視する。
- `~/.claude/CLAUDE.md` (Claude Code 用の補足) も読み込まれる。冒頭の `@~/.config/agents/AGENTS.md` は Claude Code の import 記法で、指す内容は本書の前半と同じである。そこにある Claude Code 固有の機構 (Stop hook と `.claude/verify.sh`・`/create-verify`・Agent tool の `subagent_type`・sandbox の解除・github / nano-banana MCP) は Grok では働かないので、使わず提案もしない。codex CLI による相談・レビュー (CLAUDE.md の codex の項にある `codex exec` の呼び方) は shell からそのまま使える。
