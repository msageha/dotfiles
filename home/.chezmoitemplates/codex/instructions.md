# Codex 固有の補足

## サブエージェント

- custom agent (`~/.codex/agents/*.toml`。役割は各 description。共通規約の test-runner は `test_runner`) のうち、自分の変更のレビューは `code_reviewer` に委ね、セキュリティ観点が要る変更では `security_reviewer` を併用する。
- Codex は agent ごとの sandbox を強制せず、子は親の sandbox を継承する。reviewer・researcher・test_runner がファイルを変更しないのは指示による取り決めで、sandbox で隔離したいレビューは Codex の外 (ユーザーのシェル等) から `codex exec -s read-only --ignore-rules` で行う (`~/.codex/rules/` の allow に一致するコマンドは sandbox の外で実行されるので `--ignore-rules` で外す。Codex の中から起動すると sandbox が二重にかかって失敗しうる)。
- 独立レビュー (code_reviewer / security_reviewer) は `fork_turns="none"` で spawn し、必要な事実は message で渡す。既定の全履歴 fork は生成側の推論を引き継ぐので独立にならない。
- Codex の中から呼べる別モデルは、custom agent と spawn 時の model 指定 (どちらも GPT 系) に限られる。主担当として独立した相談・レビュー (AGENTS.md「事実と判断」「検証と完了」) は上の独立レビューで取り、系統の異なるモデルの確認が要る判断はその旨を報告に書く。
- 組み込みの agent (explorer / worker / default) に探索を任せるときは低めの reasoning effort を、レビュー・セキュリティなど誤りが高くつく作業には {{ .codex.subagent_model }} と xhigh を指定する。

## ブラウザ

playwright / chrome-devtools MCP は Codex に置いていない。実ブラウザでの確認は、使えるブラウザ・画面操作の tool (computer use の `cua_repl` 等) があればそれで行い、無ければプロジェクトの E2E を shell で回す。どちらもできないときだけ未検証と報告する。

{{ includeTemplate "agents/rules-index" . -}}
