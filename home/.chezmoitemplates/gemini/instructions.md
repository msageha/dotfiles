# Antigravity 固有の補足

- 自分の変更の独立レビューは `code-reviewer` agent に任せ、セキュリティに関わる変更では `security-reviewer` も使う。
- 別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、shell から `codex exec -s read-only --ignore-rules` か `claude -p --permission-mode plan --settings '{"disableAllHooks":true}'` (Stop hook に作業ツリーを変えさせないため hook を止める) を使い、PROMPT の冒頭に相談・レビューだけの依頼であることを書く。どちらも使えなければ `code-reviewer` agent で代え、その旨を報告に書く。

{{ includeTemplate "agents/rules-index" . -}}
