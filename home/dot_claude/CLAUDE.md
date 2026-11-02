@~/.config/agents/AGENTS.md

# Claude Code 固有の補足

- プロジェクト直下の実行可能な `.claude/verify.sh` は Stop hook (Windows 以外) が実行し、失敗すると結果を返してターンの終了を 1 回止める。
- Read ツールが「変更なし」として再読を断ったのに、内容が手元に無いとき (長いセッションで早い Read の結果が追い出された等) は、`cat` などの Bash で読み直す。
- 自前の sandbox を持つ子プロセス (codex CLI の `--sandbox` 等) を Claude の sandbox 内で起動すると、二重にかかって `Operation not permitted` になり、Claude 側の拒否としては報告されない。この症状が出たら sandbox を外して再実行し、外したことを報告する。
- Bash のコマンドは permission の許可ルールに一致する単純な形で書き、コメント行・不要な pipe・複合コマンドで確認プロンプトを増やさない。
- github MCP (plugin) の認証は、各シェルの `claude` ラッパー関数が起動時に `gh auth token` を `GITHUB_PERSONAL_ACCESS_TOKEN` へ入れて行う。接続に失敗したら、`gh auth status` と、起動したシェルにその変数があるかを確かめる。

## サブエージェント

- 作業を続ける途中の自分の変更のレビューは、独立 context の `code-reviewer` に任せる。review skill は呼んだターンの残りで Edit / Write が外れるので、レビューで作業を終えるときだけ使う。
- モデルを固定していない汎用サブエージェント (general-purpose / Explore) には、探索のように誤っても影響の小さい作業なら sonnet 級と低めの effort を指定し、レビュー・セキュリティなど誤りが高くつく作業には opus / fable 級と xhigh を指定する。
- 独立性が要るサブエージェント (ブラインド検証・複数による判定) は `subagent_type` を明示して起動する。省略すると、定義で固定したモデルとツール制限が効かない。親の会話を引き継ぐ `fork` は独立した検証に使わない。

## codex

AGENTS.md の別モデルへの相談と独立レビューには codex CLI を使う。plugin の slash command (`/codex:review` 等) はユーザー専用なので、Bash から次を使う。

- 相談・文書のレビューは `codex exec -s read-only --ignore-rules`、コードレビューは `codex exec -s read-only --ignore-rules review` (対象範囲と検証の結果は PROMPT に書く。`--uncommitted` / `--base` とは併用できない)。どちらも数分から 10 分超かかるので、バックグラウンドで流す。
- `~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので、read-only の `codex exec` には、skill の手順にあるものも含めて `--ignore-rules` を付ける。top-level の `codex review` はこの flag を受け付けない。
- PROMPT の冒頭に、相談・レビューだけの依頼で結果を返せばよいことを書く。codex も同じ共通規約を読むので、書かないと自分がユーザーに成果物を返す側だとみなしうる。
