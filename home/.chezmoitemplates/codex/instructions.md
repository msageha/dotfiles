# Codex 固有の補足

- AGENTS.md が無いディレクトリでは、代わりに `CLAUDE.md` が読み込まれる。その `@<path>` 行は Claude Code の import 記法で Codex は展開しないので、指す内容が読み込まれていなければその path を読む。

## サブエージェント

- Codex の中から `codex exec` は起動しない (sandbox が二重にかかって失敗しうる)。
- 独立レビュー (code_reviewer / security_reviewer) は `fork_turns="none"` で spawn し、必要な事実は message で渡す。既定の全履歴の fork は生成側の推論を引き継ぐので、独立にならない。
- 別モデルへの相談・独立レビュー (AGENTS.md「事実と判断」「検証と完了」) には、shell から `claude -p --permission-mode plan --settings '{"disableAllHooks":true}' < <prompt-file>` で Claude Code を使う (Stop hook の `.claude/verify.sh` に作業ツリーを変えさせないため、hook を止める)。PROMPT はファイルに書いて標準入力から渡し、冒頭に、ほかのエージェントからの相談・レビューだけの依頼で、結果を呼び出し元へ返せばよいことを書く。
- 組み込みの agent (explorer / worker / default) に探索を任せるときは低めの reasoning effort を、レビュー・セキュリティなど誤りが高くつく作業には {{ .codex.subagent_model }} と xhigh を指定する。

## git の実行形 (sandbox と allow)

- この設定の sandbox は `.git` への書き込みを拒否し、`approval_policy = "never"` の session では承認を求めることもできない。承認なしで sandbox の外で動く git の操作は、`~/.codex/rules/` の allow に先頭の語が一致するコマンドだけ: `git add`・`git commit`・`git switch`・`git merge`・`git worktree add`・`git worktree prune`・`git fetch origin`・`git push origin`・`git push -u origin`・`git pull --rebase origin`・`git rebase --continue` / `--abort` / `--skip`。
- 一致させるために、option は上の語の後ろに置き (`git fetch origin --prune`。`git fetch --prune origin` は一致しない)、作業ディレクトリは `cd` や `git -C` ではなく `workdir` で指定する。allow に一致しないコマンド (pipe の先を含む)・redirect・環境変数の前置き・変数や `$(…)` の展開・heredoc を同じ呼び出しに混ぜるか、quote していない引数に `*` `?` `[` `]` `{` `}` `~` `^` `#` `\` があると、全体が sandbox の中で動く (`HEAD~1`・`@{u}` のような引数は single quote で囲む)。一致しなかった `git push` は、送信に成功しても remote-tracking ref と upstream を更新しない。
- commit message は、heredoc や `$(…)` を使わず、ファイルに書いて `git commit -F <path>` で渡す。
- 自分が作った worktree は、ディレクトリを `rm -r` で消してから (`-f` を付けた `rm` はこの設定では拒否される) `git worktree prune` で片付ける。
- rebase は `git pull --rebase origin <base>` で行う。`.git` に書くほかの操作 (`--onto` を使う rebase・`git branch`・`git tag`・`git stash`・`gh pr checkout` 等) は失敗する。上の形で同じ結果にできなければ、承認を求められる session では承認を求めて実行し、求められなければ実行するコマンドをユーザーに渡す。

## ブラウザ

実ブラウザでの確認は、使えるブラウザ・画面操作の tool (computer use の `cua_repl` 等) があればそれで行い、無ければプロジェクトの E2E を shell で回す。どちらもできないときだけ未検証と報告する。

{{ includeTemplate "agents/rules-index" . -}}
