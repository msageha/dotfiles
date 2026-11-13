# Grok 固有の補足

- project 直下の `CLAUDE.md` は読み込まれる。その `@<path>` 行は Claude Code の import 記法で Grok は展開しないので、指す内容が AGENTS.md として読み込まれていなければ、必要に応じてその path を読む。
- 共通規約の別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、相談・文書のレビューなら `codex exec -s read-only --ignore-rules`、コードレビューなら `codex exec -s read-only --ignore-rules review` (対象範囲と検証の結果を PROMPT に書く) を shell から使い、PROMPT の冒頭に、相談・レビューだけの依頼で結果を返せばよいことを書く。`~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので `--ignore-rules` を付ける。どちらも数分から 10 分超かかる。

{{ includeTemplate "agents/rules-index" . -}}
