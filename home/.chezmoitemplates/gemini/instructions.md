{{- /* Antigravity は rule ファイルの中の `@<file>` を file への参照として絶対 path に書き換え、inline code の中を除くかは公式 rules (https://antigravity.google/docs/rules) に記載が無い。本文には `@` を書かず「アットマーク」と書く */ -}}
# Antigravity 固有の補足

- project 直下の `CLAUDE.md` は自動では読み込まれないので、あれば着手前に読む。その中でアットマークに path を続けた記述は Claude Code の import 記法なので、指す内容が読み込まれていなければその path も読む。
- 共通規約の別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、相談・文書のレビューなら `codex exec -s read-only --ignore-rules` か `claude -p --permission-mode plan`、コードレビューなら `codex exec -s read-only --ignore-rules review` (対象範囲と検証の結果を PROMPT に書く) を shell から使う。PROMPT はファイルに書いて標準入力で渡し (`codex exec` は末尾に `-`)、冒頭に、ほかのエージェントからの相談・レビューだけの依頼で、結果を呼び出し元へ返せばよいことを書く。`~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので、`--ignore-rules` を付ける。どれも数分から 10 分超かかる。

{{ includeTemplate "agents/rules-index" . -}}
