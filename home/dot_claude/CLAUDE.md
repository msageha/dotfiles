@~/.config/agents/AGENTS.md

# Claude Code 固有の補足

- `~/.claude/rules/` の rule が自動で読み込まれるのは、primary working directory の下で `paths` に一致するファイルを読み書きした時点だけ。その外のファイル・新規のファイル・diff だけで見るファイルなど、対象に当たる rule が読み込まれていなければ、着手前に自分で読む。
- Stop hook (Windows 以外) は、current directory から checkout の root (git の toplevel。git の外なら current directory) まで遡って最初に見つかった実行可能な `.claude/verify.sh` を実行し、失敗すると結果を返してターンの終了を 1 回止める。current directory が、session を起動したディレクトリの配下にも、起動したリポジトリの checkout (worktree を含む) にも無いときは実行しない。hook の対象にならない場所 (入らずに作業した worktree など、ターンを終えるときの current directory の外にある checkout を含む) を変えたときは、そこの `.claude/verify.sh` を自分で実行する。
- worktree は `git worktree add` で `.worktrees/<name>` に作り、`EnterWorktree` に `path` を渡して入る。`path` の無い `EnterWorktree` は `.claude/worktrees/` に作るので使わない。入ると session の作業ディレクトリが移り、sandbox の中からその worktree に commit できる。入っている間は、起動元の checkout への編集とそこへ向けた git (`git -C`・`cd` してからの git) が止められるので、起動元の変更を写すなら入る前に済ませる。片付けるときと、別の作業場所 (起動元の checkout・別の worktree) で作業を始めるときは、先に `ExitWorktree` の `action: "keep"` で起動元へ戻る (`path` で入った worktree は `remove` では消えず、入ったままでは `.worktrees/` の別の worktree に入ることも、その中を編集することもできない)。片付けは、戻ってから `git worktree remove` で行う。
- worktree に入るときは Claude Code がユーザーに承認を求め、permission の allow では省けない。background session・サブエージェント (`EnterWorktree` は親の session ごと移す) と、入れなかったとき (承認されない・承認に答える人がいない `claude -p` 等・起動したリポジトリの外の worktree) は、入らずに worktree の中のファイルを絶対パスで編集する。
- Read ツールが「変更なし」として再読を断ったのに、内容が手元に無いとき (長いセッションで早い Read の結果が追い出された等) は、`cat` などの Bash で読み直す。
- 自前の sandbox を持つ子プロセス (codex CLI の `--sandbox` 等) を Claude の sandbox 内で起動すると、二重にかかって `Operation not permitted` になり、Claude 側の拒否としては報告されない。
- Bash のコマンドは permission の許可ルールに一致する単純な形で書き、コメント行・不要な pipe・複合コマンドで確認プロンプトを増やさない。同じ種類の操作が確認プロンプトで止まり続けるなら、user settings (chezmoi の source) に絞った allow を足すことを提案する。
- github MCP (plugin) の認証は、bash / zsh / fish の `claude` ラッパー関数が起動時に `gh auth token` を `GITHUB_PERSONAL_ACCESS_TOKEN` へ入れて行う。接続に失敗したら、`gh auth status` と、起動したシェルにその変数があるかを確かめる。

## サブエージェント

- review / security / deps skill は呼んだターンの残りで Edit / Write が外れるので、その結果を返してターンを終えるときだけ使う。
- `model` / `effort` は、定義でモデルを固定していない汎用サブエージェント (general-purpose / Explore) にだけ渡す (code-reviewer 等に渡すと、定義の値より優先される)。探索のように誤っても影響の小さい作業なら sonnet 級と低めの effort、レビュー・セキュリティなど誤りが高くつく作業なら opus / fable 級と xhigh を指定する。
- 独立性が要るサブエージェント (ブラインド検証・複数による判定) は、親の会話を引き継ぐ `fork` ではなく、`subagent_type` で agent を指定して起動する。

## codex

AGENTS.md の別モデルへの相談と独立レビューには codex CLI を使う。plugin 経由 (`codex:codex-rescue` 等) では `--ignore-rules` を付けられないので、Bash から次を使う。

- 相談・文書のレビューは `codex exec -s read-only --ignore-rules`、コードレビューは `codex exec -s read-only --ignore-rules review` (対象範囲と検証の結果は PROMPT に書く。`--uncommitted` / `--base` / `--commit` とは併用できない)。PROMPT はファイルに書き、コマンドの末尾に `- < <prompt-file>` を付けて渡す (引数で渡すと、`review` を付けない `codex exec` は、stdin が開いたままのときに入力を待って止まる)。どちらも数分から 10 分超かかるので、バックグラウンドで流す。
- `~/.codex/rules/` の allow に一致するコマンドは read-only の sandbox の外で実行されるので、read-only の `codex exec` には、skill の手順にあるものも含めて `--ignore-rules` を付ける。top-level の `codex review` はこの flag を受け付けない。
- PROMPT の冒頭に、相談・レビューだけの依頼で結果を返せばよいことを書く。codex も同じ共通規約を読むので、書かないと自分がユーザーに成果物を返す側だとみなしうる。
