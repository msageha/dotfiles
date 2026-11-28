{{- /* 共通規約 (dot_config/agents/AGENTS.md) のうち Codex の既定動作と衝突する項目を、先頭の文言で探して抜き出す。
      写しを置くと、共通規約を直したときに Codex だけ古い条件で振る舞うため。項目は続きの行 (2 文字の字下げ) と、
      その間の空行も含めて取り、ちょうど 1 つ見つからなければ描画を止める (2 つあると、どちらを配るかが共通規約の並びで黙って変わるため)。
      Windows の checkout は CRLF になるので、改行を LF にそろえる */ -}}
{{- $text := replace "\r\n" "\n" (include "dot_config/agents/AGENTS.md") -}}
# ユーザーの既定の契約

次の点は、このユーザーの既定の契約として Codex の既定動作より優先する。その場でユーザーが明示的に別の指示をしたら、そちらに従う。各項目は作業規約 (global の AGENTS.md) から抜き出したもので、前文・節への言及は作業規約のものを指す。作業中のリポジトリの AGENTS.md / CLAUDE.md と食い違うときの扱いも、作業規約の前文に従う。

{{ range list "依頼か問いかは" "調査・原因分析・レビューの依頼は" "確認は方針を決める前に" "作業中の割り込みは" "commit・push・PR 作成" "今回の作業に属さない未 commit の変更" -}}
{{-   $items := regexFindAll (printf "(?m)^- %s.*(?:\n(?:  .*)?)*" (regexQuoteMeta .)) $text -1 -}}
{{-   if ne (len $items) 1 -}}
{{-     fail (printf "dot_config/agents/AGENTS.md: %d items start with %q; the Codex developer instructions copy exactly one" (len $items) .) -}}
{{-   end -}}
{{ index $items 0 | trim }}
{{ end -}}
{{- /* Codex は既定で draft PR を作るが、作業規約にはこれを打ち消す項目が無い */ -}}
- PR は依頼されない限り draft にしない。
