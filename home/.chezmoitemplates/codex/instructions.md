# Codex 固有の補足

## サブエージェント

- custom agent のうち、`code_reviewer` (セキュリティに関わる変更では `security_reviewer` も) は、ユーザーに頼まれたときと、作業の途中で自分の変更を独立した context で確かめたいときに使う。共通規約の別モデルによる相談・独立レビューは、下の `claude -p` で取る。テストの実行と報告だけなら `test_runner` に任せる。
- Codex の中から `codex exec -s read-only` を起動しても、sandbox が二重にかかって失敗しうる。
- 独立レビュー (code_reviewer / security_reviewer) は `fork_turns="none"` で spawn し、必要な事実は message で渡す。既定の全履歴の fork は生成側の推論を引き継ぐので、独立にならない。
- 別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、shell から `claude -p --permission-mode plan --settings '{"disableAllHooks":true}' "<PROMPT>"` で Claude Code を使う (Stop hook の `.claude/verify.sh` に作業ツリーを変えさせないため、hook を止める)。PROMPT の冒頭に、相談・レビューだけの依頼で結果を返せばよいことを書く。
- 組み込みの agent (explorer / worker / default) に探索を任せるときは低めの reasoning effort を、レビュー・セキュリティなど誤りが高くつく作業には {{ .codex.subagent_model }} と xhigh を指定する。

## ブラウザ

実ブラウザでの確認は、使えるブラウザ・画面操作の tool (computer use の `cua_repl` 等) があればそれで行い、無ければプロジェクトの E2E を shell で回す。どちらもできないときだけ未検証と報告する。

{{ includeTemplate "agents/rules-index" . -}}
