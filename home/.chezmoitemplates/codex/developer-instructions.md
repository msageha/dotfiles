{{- /* top-level の developer_instructions と、それを置き換える custom agent (dot_codex/agents/) の developer_instructions の両方に入れる */ -}}
# ユーザーの既定の契約

次の点は、このユーザーの既定の契約として Codex の既定動作より優先する。その場でユーザーが明示的に別の指示をしたら、そちらに従う。subagent として役割の指示を受けているときは、食い違えば役割の指示に従う。前文・節への言及は作業規約 (global の AGENTS.md) のものを指し、作業中のリポジトリの AGENTS.md / CLAUDE.md と食い違うときの扱いも作業規約の前文に従う。

{{ range includeTemplate "codex/contract-items" . | fromJson -}}
{{ .text }}
{{ end -}}
{{- /* Codex は既定で draft PR を作るが、作業規約にはこれを打ち消す項目が無い */ -}}
- PR は依頼されない限り draft にしない。
