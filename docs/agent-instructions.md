# LLM エージェント指示文の構成

このリポジトリが配る LLM エージェント (Claude Code / Codex / Antigravity / Grok) 向けの指示文・skill・サブエージェントの配置と、コードから読み取れない契約をまとめる。
指示文の編集の規範は `home/dot_claude/rules/agent-config.md`、各ツールの設定 (Claude の settings*.json、Codex の config.toml / rules、Grok の config.toml、Gemini の settings.json) の規範は `home/dot_claude/rules/claude-settings.md` にある (Claude Code では path-scoped rule として自動で読まれる)。
以下のパスは `home/` を省いて書く。

## 原則

- 共通規約は `dot_config/agents/AGENTS.md` の 1 箇所に書き、各ツールの adapter (下記) には、そのツール固有の機構 (独立レビュー・別モデルへの相談の手段等) だけを書く。
- この repo の rules を path に応じて自動で読むのは Claude Code だけで、Codex / Antigravity / Grok にはその形で配っていない (Antigravity の glob で読ませる rule には未対応)。
  `.chezmoitemplates/agents/rules-index` が `dot_claude/rules/*.md` の見出しと frontmatter の `paths` から rule の一覧を生成し、各ツールの補足 (`.chezmoitemplates/{codex,gemini,grok}/instructions.md`) が include して、着手前にそこから選んで読ませる。
  rule の追加・削除・`paths` の変更は一覧に自動で反映される。一覧は `paths` の先頭 6 件だけを出すので、代表的な pattern を先頭に置く。rule が 1 つも見つからないときは描画を fail で止める。
- 委譲するときだけ要る手順 (依頼の書き方・外部のエージェント CLI の起動・質問できない受け手への渡し方) は `dot_config/agents/delegation.md` (適用先 `~/.config/agents/delegation.md`) に分け、共通規約の「委譲」節から、依頼を出す前に読ませる。
  委譲しないセッションと、共通規約を読むサブエージェントの起動のたびに、その分の context を使わないため。
- `.chezmoiignore` は、`~/.claude`・`~/.codex`・`~/.gemini`・`~/.grok`・`~/.agents` の直下を `<dir>/*` で ignore し、管理する項目だけを `!` で戻している。直下に項目を足すときは `!` の行も足す (無くても描画の検査は通り、適用されないだけになる)。
- `.chezmoitemplates/` 配下は chezmoi が起動時に全件 template として parse する。
  本文用のファイル (`agents/*.md`・`*/instructions.md` 等) に生の `{{` を書くと、include / includeTemplate のどちらで参照しても全 chezmoi コマンドが失敗するので、必要なら `{{ "{{" }}` でエスケープする。
- `.gitattributes` が無く Windows の checkout は CRLF になる (CI の `chezmoi-windows` も同じ)。
  include した本文を分割・正規表現で処理するテンプレートは、`replace "\r\n" "\n"` で改行をそろえるか、パターンを `\r?\n` で書く。

## Claude Code

- `dot_claude/CLAUDE.md` が `@~/.config/agents/AGENTS.md` で共通規約を import し、Claude 固有の機構だけを足す。
  MCP やサブエージェントの「いつ使うか」は tool の定義・server instructions・agent の description にあるので再掲しない。
- Claude Code が `~/.claude/rules/` の rule を自動で読み込むのは、primary working directory の下で `paths` に一致するファイルを読み書きした時点だけ。
  その外のファイル (追加の作業ディレクトリ等) と diff だけで見るファイルでは読み込まれず、新規のファイルでは書き込んだ後になることを `dot_claude/CLAUDE.md` が述べ、共通規約の前文が、context に無い rule を着手前に読ませる。
- この repo で作業すると、`home/dot_claude/CLAUDE.md` が nested の CLAUDE.md として読み込まれ、適用済みの `~/.claude/CLAUDE.md` と重複する。
  user settings の `claudeMdExcludes` (`dot_claude/private_settings.json.tmpl`) で外している。
- `modify_private_dot_claude.json` は、`~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ置き換える chezmoi:modify-template。
  `.tmpl` を付けると二重にテンプレート処理されるので付けない。
  マシンローカルな状態 (ログイン情報・`projects`・識別子等。キーはテンプレート内の list) だけ既存値を温存し、Claude Code が実行時に書くその他のランタイム状態 (カウンタ・キャッシュ等) は apply のたびにリセットされる。
- `~/.claude/settings.json` は通常テンプレート (`dot_claude/private_settings.json.tmpl`) で全量管理する。
  外部ツール (ローカルデーモン等) が実行時に注入する hooks は apply のたびに消える。
  hooks 配列の部分マージは脆いため、意図して全量管理にしている。
- 共通規約が定める worktree の置き場所 (`.worktrees/<name>`) に合わせるため、user settings の PreToolUse hook (Windows 以外) が、`path` の無い `EnterWorktree` (`.claude/worktrees/` に新しく作る形) を止める (置き場所の設定や `WorktreeCreate` hook を使わない理由と、tool ごと deny にしない理由は、hook のコメントにある)。
  Claude は `git worktree add` で `.worktrees/<name>` に作り、`EnterWorktree` に `path` を渡して入る。入った worktree は session 自身のものになり、sandbox の中から commit できる。`path` で入った worktree は `ExitWorktree` の `remove` では消えないので、`keep` で戻ってから `git worktree remove` で消す。
  `.claude/worktrees/` の外の path へ入るときは、Claude Code (2.1.206 以降) が毎回ユーザーに承認を求める。permission の allow でも auto mode でも省けず、省くのは `bypassPermissions` だけ ([公式 worktrees](https://code.claude.com/docs/en/worktrees))。承認に答える人がいない `claude -p` では入れず、入れる先も起動したリポジトリ (とその中に nest したリポジトリ) の worktree に限られるので、`dot_claude/CLAUDE.md` が、入れないときは入らずに worktree の中で作業させる。
  worktree に入っている間は、`path` で移れる先が `.claude/worktrees/` の配下に限られ ([公式 tools-reference](https://code.claude.com/docs/en/tools-reference#enterworktree-tool-behavior))、起動元の checkout の配下にある別の worktree への編集も止められるので (Claude Code 2.1.325 の実装)、別の作業場所へ移るときは、`dot_claude/CLAUDE.md` が `ExitWorktree` の `keep` で起動元へ戻らせる (`ExitWorktree` の tool 定義は「ユーザーが頼んだときだけ呼ぶ」と定めるので、頼まれていなくても戻ると明記している)。
  `claude --worktree` とサブエージェントの `isolation: worktree` は Claude Code 自身が作るので、引き続き `.claude/worktrees/` に作られる。agent view や `claude --bg` で起動した background session は、起動元の checkout を編集できない (`worktree.bgIsolation` の既定)。`git worktree add` で作った worktree の中の編集は通るので、`dot_claude/CLAUDE.md` が `.worktrees/<name>` の中で、入らずに作業させる。開いていた session を background へ移した場合は、元の場所で編集を続けられる。

## Codex

- `dot_codex/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/codex/instructions.md` を連結する。
- project の指示文は `AGENTS.md` を読み、それが無いディレクトリでは `CLAUDE.md` を読む (`dot_codex/modify_private_config.toml` の `project_doc_fallback_filenames`)。
- AGENTS.md は user role で注入されるため、Codex の base prompt (developer role) の既定動作 (質問形を実行の依頼とみなす、範囲が曖昧でも仮定を置いて進める、前のターンの許可を持ち越す、worktree や draft PR を自律的に作る等) を上書きできない。
  これと衝突する少数の契約だけを `.chezmoitemplates/codex/developer-instructions.md` に書き、`dot_codex/modify_private_config.toml` が top-level の `developer_instructions` に入れる。
  各項目は共通規約の該当する規範と同じ条件で書き、共通規約を変えたら同じ変更で直す。Codex ではこちらが AGENTS.md より優先されるので、条件がずれると Codex だけ振る舞いが変わる。
- Codex から別モデル (Claude Code) へ相談するときは、shell から `claude -p --permission-mode plan --settings '{"disableAllHooks":true}'` を使う (`.chezmoitemplates/codex/instructions.md`)。plan だけでは Stop hook が止まらず、`.claude/verify.sh` が作業ツリーを変えうるので、hook も止める。`disableAllHooks` は user settings の PreToolUse hook (危険なコマンドの遮断) も止め、plan が塞ぐのは編集で、shell コマンドは通常の permission の判定を通るので、この起動は `codex exec -s read-only` と違い capability としての read-only ではない。`claude` は、この設定の Codex の sandbox (workspace-write、`network_access = true`) の中でも動く。
- `dot_codex/rules/default.rules` の allow は、共通規約と commit / pr skill が求める git の操作のうち、sandbox の中では `.git` に書けず失敗するものを sandbox の外で通す (git のほかに `xcodebuild` も allow している)。後ろに付けられる引数を理由に載せていない操作があるので (対象と理由は rules のコメント)、pr skill の `--onto` の rebase と `git branch -f` は Codex では実行できない。`.git` に書く git 以外のコマンドも載せていないので、improve-pr skill の `gh pr checkout` も実行できない。載せた操作も後ろの引数は絞れず (`git fetch origin --upload-pack=<command>`・`git push origin --force`・`git switch -C` も一致する)、allow は sandbox を抜けようとする agent を止める境界にはならない。`approval_policy = "never"` では allow の一覧が Codex の prompt に出ないので、一致する形は `.chezmoitemplates/codex/instructions.md` の「git の実行形」節が列挙する (見出しを共通規約の「git」節と分けているのは、skill の「AGENTS.md の `git` 節」という参照の先を 1 つにするため)。rules を変えたら同じ変更で直す。`codex execpolicy check` は argv を直接照合するので、実行時に shell の書き方で一致しなくなる条件 (同節にある、quote していない `~` `^` `*` 等・環境変数の前置き・redirect) は確かめられない。allow は read-only の session にも効き、Claude Code の codex plugin と top-level の `codex review` は `--ignore-rules` を渡せないので、これらの read-only の review でも allow のコマンドは sandbox の外で動く。
- custom agent は `dot_codex/agents/*.toml.tmpl`。model は `.chezmoidata.toml` の `[codex] subagent_model` を参照する。
  custom agent のファイルは親の `sandbox_mode`・`approval_policy`・`model_provider`・`mcp_servers` を上書きできず、子は親の設定を継承するので ([公式 subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents))、これらは書かない。
- Codex には playwright / chrome-devtools MCP を置かない。custom agent の `mcp_servers` は無視され、main config に置くと Claude から呼ぶ `codex exec` の起動のたびに MCP が立ち上がるため。
  Codex のブラウザ確認は、実行環境が提供するブラウザ・画面操作の tool か、プロジェクトの E2E で行う (`codex/instructions.md`)。

## Antigravity (Gemini)

- 1 ファイルの上限 (下記「サイズ予算」) に収めるため、共通規約を `## git` 見出しの前後で分けて配る。
  前半は `dot_gemini/config/AGENTS.md.tmpl` → `~/.gemini/config/AGENTS.md`、後半と `.chezmoitemplates/gemini/instructions.md` は `dot_gemini/config/GEMINI.md.tmpl` → `~/.gemini/config/GEMINI.md`。
  どちらも frontmatter 無しの常時有効な global rule で、この 2 つのパスを読むのは App と CLI (IDE / extensions の global rule は `~/.gemini/AGENTS.md`・`~/.gemini/GEMINI.md`・`~/.gemini/config/rules/*.md`)。
- 分割と上限の検査は `.chezmoitemplates/gemini/agents-md-part` が行う。
  見出しが見つからないときと、生成物が 24,000 bytes を超えたときは、テンプレートが fail して描画を止める。
  共通規約の `## git` 見出しを変えるときは、分割位置も合わせて直す。
- Antigravity は `~/.claude/`・`~/.agents/`・CLAUDE.md を自動では読まない。
  project 直下の CLAUDE.md は、補足 (`.chezmoitemplates/gemini/instructions.md`) が着手前に読ませる。
- Antigravity は rule ファイルの中の `@<file>` を file への参照として扱う。
  Antigravity が rule として読む本文 (共通規約・`.chezmoitemplates/gemini/instructions.md`・rule の一覧に出る `dot_claude/rules/*.md` の見出しと `paths`・repo 直下の `AGENTS.md`) には、`@` に path を続けた記述を書かない。
- サブエージェントの `agent.md` の `tools` は、公式 docs の表で既定値が `[]` (空のときに使える tool は未記載) なので、各 wrapper で列挙する。
  `find_by_name` / `grep_search` / `list_dir` は既定の toolset から外れた legacy の tool で、`tools` で明示すれば使える。公式 docs は未対応の tool 名で subagent が hang しうると警告しているので、agy を更新したら tool 名を点検する。

## Grok

- `dot_grok/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/grok/instructions.md` を連結する。
- `compat.claude` (`dot_grok/modify_private_config.toml`) は、`agents = false` (`~/.claude/CLAUDE.md` と project の `.claude/CLAUDE*.md`)・`rules = false` (`~/.claude/rules` と project の `.claude/rules`。有効だと `paths` を無視して全件を常時読む)・`skills = true` にしている。
  `~/.claude/agents` と Claude Code の plugin の agent・hook は、この設定にかかわらず読まれる (plugin の skill・command は `skills = true` で読まれる)。project 直下の `CLAUDE.md` も、同梱の user guide では設定にかかわらず読まれるが、`AGENTS.md` と並ぶ `@AGENTS.md` だけの `CLAUDE.md` は `grok inspect --json` の `projectInstructions` に出ない (grok 1.0.77)。
- project の AGENTS.md / CLAUDE.md は、folder trust (`grok --trust` か対話での許可。`--trust` は `grok --help` に出ない) があるときだけ起動時に読まれる。`grok inspect --json` の `projectTrusted` で確かめる。
- `~/.grok/skills` には配らない。
  Grok は `~/.agents/skills` も読み、`~/.claude/skills` と同名の skill は `~/.agents/skills` 側を採る (中身は同じ include)。bundled と同名の skill は、`~/.agents/skills` にあればそちらが採られ (review)、`~/.claude/skills` にしか無ければ bundled 側が採られる (pdf)。

## skills

- 本体は `dot_claude/skills/<name>/SKILL.md`。
- 他のツールと共有する skill は、本体を include する wrapper で配る。
  Codex と Grok は `dot_agents/skills/<name>/SKILL.md.tmpl` → `~/.agents/skills`、Antigravity は `dot_gemini/config/skills/<name>/SKILL.md.tmpl`。
  共有 skill の本文は他のツールからも読まれ、Grok は `compat.claude.skills = true` で `~/.claude/skills` の全件も読む。
  そのため、どの skill も Claude 固有の機構 (`$ARGUMENTS` の置換・Claude Code の tool 名・bundled skill・Stop hook) に依存させず、使うときは「使える環境では」と条件を付ける。
- commit / pr には `disable-model-invocation` を付けず、自然文の依頼でも起動する。
  skill を読み込んだことは git 操作の許可ではなく、操作してよいかは共通規約の「git」節 (ユーザーの明示指示か、前文の常設の手順) で決まる。
  skill と各ツールの補足には、この条件を写さず「AGENTS.md の `git` 節が認めるとき」と参照で書く。写しは条件の一部 (出所の除外等) を落とし、前文より広く読まれる。「git」節に無い操作 (PR への返信・thread の resolve・review の submit) は常設の手順の対象ではないので、この参照に置き換えず「ユーザーが頼んだときだけ」と書く。

## サブエージェント

- 本文は `.chezmoitemplates/agents/<name>.md`、description は `.chezmoidata.toml` の `[agents]` が単一ソース。
  Claude (`dot_claude/agents/*.md.tmpl`)・Codex (`dot_codex/agents/*.toml.tmpl`。`'''` リテラル内に展開)・Gemini (`dot_gemini/config/agents/*/agent.md.tmpl`) の各 wrapper が、include と `.agents.<name>` (キーは underscore。無いキーは描画時に fail する) で参照する。
- browser-debugger の定義は Claude 用 (`dot_claude/agents/`) だけに置き、Codex と Antigravity には置かない。Grok は `~/.claude/agents` を読むので、Grok の設定にある playwright / chrome-devtools MCP と合わせて使える。
- playwright / chrome-devtools MCP は、Claude (`.chezmoitemplates/claude.json`)・Grok (`dot_grok/modify_private_config.toml`)・Antigravity (`dot_gemini/config/private_mcp_config.json.tmpl`) のどれでも `--headless` を付けて起動する。
  どちらの server も既定は headed で、headless かは起動時の引数で決まり、agent は実行中に切り替えられない。共通規約の「ブラウザの自動操作は headless で行う」を MCP 経由の確認でも成り立たせるために、設定の側で固定している。
  MCP のブラウザの画面を見るか手動で操作する (ログイン等) には、その設定から `--headless` を外して apply し、ツールを起動し直す。
- Codex / Gemini の code-reviewer・security-reviewer は、review / security skill の本文を frontmatter を剥いで追記する (`regexReplaceAll` は明示引数形で書く。パイプ形は空文字になる)。
  skill 本文に `'''` を含めると Codex の TOML が壊れる。

## サイズ予算

- Antigravity は rule ファイル 1 つを、include 展開後に 24,000 bytes で切り詰める ([公式 rules](https://antigravity.google/docs/rules))。
  対象は分割した 2 ファイルと、workspace の常時有効な rule として読まれる repo 直下の `AGENTS.md`。
- Antigravity の global と always_on の rule は、全体で 20,000 tokens の予算を共有する。超過すると、大きいファイルから順に path と description だけの pointer に格下げされ、共通規約が本文として読まれなくなる。
  上の 3 ファイルの合計 bytes も見る。token の数え方は公式 docs に無いので、日本語 1 文字 (3 bytes) を 1 token と置き、合計 bytes の 1/3 が 20,000 を下回るようにする。
- Antigravity は skill の本文にも 24 KB の上限を持つ (agy 同梱の changelog。`agy plugin validate` が超過を警告する。公式 docs には記載が無く、超過分の扱いは不明)。Antigravity に配る共有 skill (`dot_gemini/config/skills/`) はこれに収める。
- Codex は project doc (repo root から作業ディレクトリまでの AGENTS.md の連結) を `project_doc_max_bytes` (既定 32 KiB) で切り詰める。`~/.codex/AGENTS.md` は切り詰めの対象外。ただし Codex (0.169) は、global を含む指示文の合計がこの値を超えると warning (`Combined user instructions use <N> bytes ...`) を出す。共通規約と Codex の補足の合計は既定値を超えるので、`codex exec` の出力を含めて session ごとに出るが、切り詰めを示すものではない。
- Grok は指示文のファイルを全文読み込み、上限も切り詰めも無い ([公式 project rules](https://docs.x.ai/build/features/project-rules))。同梱の `~/.grok/README.md` にある 1 ファイル 10,000 文字の上限は、公式 docs と同梱の user guide に合わないので根拠にしない。
- 共通規約・`.chezmoitemplates/gemini/instructions.md`・repo 直下の `AGENTS.md` を増やしたときと、rule を足すか rule の見出し・`paths` を変えたとき (rule の一覧が後半のファイルに入る) は、bytes を計測する。
  `wc -c` は LANG に依らず bytes を数える (`wc -m` は locale 依存)。

  ```sh
  chezmoi execute-template --source . < home/dot_gemini/config/AGENTS.md.tmpl | wc -c
  chezmoi execute-template --source . < home/dot_gemini/config/GEMINI.md.tmpl | wc -c
  wc -c AGENTS.md
  ```

## 配布の確認

テンプレートの描画が通っても、各ツールが実際に読み込むかは別に確かめる。どれもモデルを呼ばない。

- 適用先と source の差分: `chezmoi status` (内容を出さない)。
- Codex: この repo で `codex debug prompt-input "ping"` を実行し、AGENTS.md の連結 (共通規約 → Codex の補足 → repo の AGENTS.md) が末尾まで入っていることと、skill の一覧を見る。
- Grok: `grok inspect --json` の `projectInstructions` (有効な指示文と disabled の一覧)・`skills`・`agents`。
- Antigravity: `agy agents` で agent の一覧を見る。rule の読み込みはモデルを呼ばないと確かめられない。
