# Antigravity 固有の補足

- `code-reviewer` agent (セキュリティに関わる変更では `security-reviewer` も) は、ユーザーに頼まれたときと、作業の途中で自分の変更を独立した context で確かめたいときに使う。
- 共通規約の別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、shell から codex CLI か Claude Code を使い、PROMPT の冒頭に相談・レビューだけの依頼であることを書く。相談・文書のレビューは `codex exec -s read-only --ignore-rules` か `claude -p --permission-mode plan --settings '{"disableAllHooks":true}'` (Stop hook に作業ツリーを変えさせないため hook を止める)、コードレビューは `codex exec -s read-only --ignore-rules review` (対象範囲と検証の結果を PROMPT に書く) を使う。`~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので、`--ignore-rules` を付ける。どれも数分から 10 分超かかる。

{{ includeTemplate "agents/rules-index" . -}}
