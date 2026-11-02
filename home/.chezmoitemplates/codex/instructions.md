# Codex 固有の補足

## サブエージェント

- custom agent (`~/.codex/agents/*.toml`。役割は各 description) のうち、自分の変更のレビューは `code_reviewer` に任せ、セキュリティに関わる変更では `security_reviewer` も使う。テストの実行と報告だけなら `test_runner` に任せる。
- Codex は agent ごとの sandbox を強制せず、子は親の sandbox を継承する。reviewer・researcher・test_runner がファイルを変えないのは指示による取り決めなので、sandbox で隔離したいレビューは Codex の外から `codex exec -s read-only --ignore-rules` で行う。
- 独立レビュー (code_reviewer / security_reviewer) は `fork_turns="none"` で spawn し、必要な事実は message で渡す。既定の全履歴の fork は生成側の推論を引き継ぐので、独立にならない。
- 別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、shell から `claude -p --permission-mode plan --settings '{"disableAllHooks":true}' "<PROMPT>"` で Claude Code を使う (hook を止めるのは、Stop hook の `.claude/verify.sh` が作業ツリーを変えないため)。PROMPT の冒頭に、相談・レビューだけの依頼で結果を返せばよいことを書く。
- 組み込みの agent (explorer / worker / default) に探索を任せるときは低めの reasoning effort を、レビュー・セキュリティなど誤りが高くつく作業には {{ .codex.subagent_model }} と xhigh を指定する。

## ブラウザ

playwright / chrome-devtools MCP は Codex に置いていない。実ブラウザでの確認は、使えるブラウザ・画面操作の tool (computer use の `cua_repl` 等) があればそれで行い、無ければプロジェクトの E2E を shell で回す。どちらもできないときだけ未検証と報告する。

{{ includeTemplate "agents/rules-index" . -}}
