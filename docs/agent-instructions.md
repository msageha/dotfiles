# LLM エージェント指示文の構成

このリポジトリが配る LLM エージェント (Claude Code / Codex / Antigravity / Grok) 向けの指示文・skill・サブエージェントの配置と、コードから読み取れない契約をまとめる。
指示文の編集の規範は `home/dot_claude/rules/agent-config.md`、各ツールの設定 (Claude の settings*.json、Codex の config.toml / rules、Grok の config.toml、Antigravity の settings.json) の規範は `home/dot_claude/rules/claude-settings.md` にある (Claude Code では path-scoped rule として自動で読まれる)。
以下のパスは `home/` を省いて書く。

## 原則

- 共通規約は `dot_config/agents/AGENTS.md` の 1 箇所に書き、各ツールの adapter (下記) には、そのツール固有の機構 (独立レビュー・別モデルへの相談の手段等) だけを書く。
- この repo の rules を path に応じて自動で読むのは Claude Code だけで、Codex / Antigravity / Grok にはその形で配っていない (Antigravity の glob で読ませる rule には未対応)。
  `.chezmoitemplates/agents/rules-index` が `dot_claude/rules/*.md` の見出しと frontmatter の `paths` から rule の一覧を生成し、Codex と Grok の補足 (`.chezmoitemplates/{codex,grok}/instructions.md`) が include して、着手前にそこから選んで読ませる。Antigravity には `dot_gemini/config/rules/language-rules.md.tmpl` (`trigger: model_decision`) として配る。この形式は path と description だけを常に読み込み、本文は作業が description に当たるときに読むので、常時有効な rule の予算 (下記「サイズ予算」) を使わない。
  rule の追加・削除・`paths` の変更は一覧に自動で反映される。一覧は `paths` の先頭 6 件だけを出すので、代表的な pattern を先頭に置く。rule が 1 つも見つからないときは描画を fail で止める。
- 委譲するときだけ要る手順 (依頼の書き方・外部のエージェント CLI の起動・質問できない受け手への渡し方) は `dot_config/agents/delegation.md` (適用先 `~/.config/agents/delegation.md`) に分け、共通規約の「委譲」節から、依頼を出す前に読ませる。
  委譲しないセッションと、共通規約を読むサブエージェントの起動のたびに、その分の context を使わないため。
  測れる指標の改善を長く繰り返させる委譲の手順は、ほかの委譲でその分の context を使わないよう `dot_config/agents/improvement-loop.md` に分け、`delegation.md` には使う場面だけを書いて、使うときだけ読ませる。
- `.chezmoiignore` は、`~/.claude`・`~/.codex`・`~/.gemini`・`~/.grok`・`~/.agents` の直下を `<dir>/*` で ignore し、管理する項目だけを `!` で戻している。直下に項目を足すときは `!` の行も足す (無くても描画の検査は通り、適用されないだけになる)。
- `.chezmoitemplates/` 配下は chezmoi が起動時に全件 template として parse する。
  本文用のファイル (`agents/*.md`・`*/instructions.md` 等) に生の `{{` を書くと、include / includeTemplate のどちらで参照しても全 chezmoi コマンドが失敗するので、必要なら `{{ "{{" }}` でエスケープする。
- `.gitattributes` が無く Windows の checkout は CRLF になる (CI の `chezmoi-windows` も同じ)。
  include した本文を分割・正規表現で処理するテンプレートは、`replace "\r\n" "\n"` で改行をそろえるか、パターンを `\r?\n` で書く。

## Claude Code

- `dot_claude/CLAUDE.md` が `@~/.config/agents/AGENTS.md` で共通規約を import し、Claude 固有の機構だけを足す。
  MCP やサブエージェントの「いつ使うか」は tool の定義・server instructions・agent の description にあるので再掲しない。
- Claude Code が `~/.claude/rules/` の `paths` を持つ rule を自動で読み込むのは、primary working directory の下で `paths` に一致するファイルを読み書きした時点だけ。
  その外のファイル (追加の作業ディレクトリ等) と diff だけで見るファイルでは読み込まれず、新規のファイルでは書き込んだ後になる。
  Claude Code には rule の一覧を配っていないので、`dot_claude/CLAUDE.md` がこの読み込みの条件を述べ、そうした対象では `~/.claude/rules/` と project の `.claude/rules/` から `paths` が一致する rule と `paths` の無い rule を手を付ける前に読ませる (共通規約の前文の「context に無い rule を着手前に読む」を Claude で実行できるようにするため)。
- この repo で作業すると、`home/dot_claude/CLAUDE.md` が nested の CLAUDE.md として読み込まれ、適用済みの `~/.claude/CLAUDE.md` と重複する。
  user settings の `claudeMdExcludes` (`dot_claude/private_settings.json.tmpl`) で外している。
- `modify_private_dot_claude.json` は、`~/.claude.json` を `.chezmoitemplates/claude.json` の内容へ置き換える chezmoi:modify-template。
  本体は `.chezmoitemplates/claude.json.modify` にあり、`private_dot_claude-private/modify_private_dot_claude.json` も同じ本体を include する。
  `.tmpl` を付けると二重にテンプレート処理されるので付けない。
  マシンローカルな状態 (ログイン情報・`projects`・識別子等。キーはテンプレート内の list) だけ既存値を温存し、Claude Code が実行時に書くその他のランタイム状態 (カウンタ・キャッシュ等) は apply のたびにリセットされる。
- `claude-private` (bash / zsh は `dot_config/shell/integrations.sh`、fish は `dot_config/fish/functions/claude-private.fish`) は、`CLAUDE_CONFIG_DIR=~/.claude-private` で Claude Code を個人アカウント用に起動する。
  claude.ai のログイン (macOS では Keychain のエントリ) は `CLAUDE_CONFIG_DIR` ごとに分かれるので、`claude` と再ログインなしで使い分けられる ([公式 authentication](https://code.claude.com/docs/en/authentication#log-in-with-multiple-accounts))。
  `~/.claude-private/` の `settings.json`・`CLAUDE.md`・`rules`・`skills`・`agents` は `~/.claude` への symlink で、`.claude.json` は `~/.claude.json` と同じ template で描画する。セッション履歴・ログイン・`projects` の trust は分かれる。
  `plugins/` は共有せず、`.chezmoiscripts/run_onchange_after_97_claude-private-plugins.sh.tmpl` が `install/common/claude_plugins.sh` で同じ plugin を別にインストールする。`plugins/data/` (plugin の永続データ。codex plugin は workspace ごとの broker の状態を置き、session の終了時にそれを止める) を共有すると、アカウントをまたいで broker を使い回し・停止しうるため。Claude Code は `installed_plugins.json` 等を一時ファイルからの rename で書き換えるので、ファイル単位の symlink でも共有を保てない。
  同じ理由で、`claude-private` の中で user settings を書き換える操作 (`/config` 等) は `settings.json` の symlink を実ファイルに置き換えうる。置き換わっても、次の apply で symlink に戻る (`~/.claude/settings.json` への書き込みが apply で消えるのと同じ)。
  `claude-private` と `codex-private` は `CLAUDE_CONFIG_DIR` と `CODEX_HOME` の両方を渡す。session の中から呼ぶもう一方の CLI (Claude から `codex`、Codex から `claude`) が環境変数を継承し、同じ個人アカウントで動く。
  起動する関数が POSIX のシェルにしか無いので、Windows には配らない (`.chezmoiignore`)。
- `~/.claude/settings.json` は通常テンプレート (`dot_claude/private_settings.json.tmpl`) で全量管理する。
  外部ツール (ローカルデーモン等) が実行時に注入する hooks は apply のたびに消える。
  hooks 配列の部分マージは脆いため、意図して全量管理にしている。
- user settings は sandbox を無効にしている。会社アカウント (`~/.claude`) では server-managed settings が sandbox を有効にし、user settings より優先される。`claude-private` には managed settings が無く、この user settings の既定のまま無効で動く。
  sandbox が無効だと、`permissions.deny` の `Read` は Claude Code 自身が判定する読み取り (file tool・解析できる Bash のファイル操作 (`cat` 等)・redirect 等) にだけ効き、ファイルを自分で開く python / node 等の子プロセスには効かない ([公式 permissions](https://code.claude.com/docs/en/permissions#what-read-and-edit-rules-cover))。
- 共通規約が定める worktree の置き場所 (`.worktrees/<name>`) に合わせるため、user settings の PreToolUse hook (Windows 以外) が、`path` の無い `EnterWorktree` (`.claude/worktrees/` に新しく作る形) を止める (置き場所の設定や `WorktreeCreate` hook を使わない理由と、tool ごと deny にしない理由は、hook のコメントにある)。
  Claude は `git worktree add` で `.worktrees/<name>` に作り、`EnterWorktree` に `path` を渡して入る。入った worktree は session 自身のものになり、sandbox の中から commit できる。`path` で入った worktree は `ExitWorktree` の `remove` では消えないので、`keep` で戻ってから `git worktree remove` で消す。
  `.claude/worktrees/` の外の path へ入るときは、Claude Code (2.1.206 以降) が毎回ユーザーに承認を求める。permission の allow でも auto mode でも省けず、省くのは `bypassPermissions` だけ ([公式 worktrees](https://code.claude.com/docs/en/worktrees))。承認に答える人がいない `claude -p` では入れず、入れる先も起動したリポジトリ (とその中に nest したリポジトリ) の worktree に限られるので、`dot_claude/CLAUDE.md` が、入れないときは入らずに worktree の中で作業させる。
  worktree に入っている間は、`path` で移れる先が `.claude/worktrees/` の配下に限られ ([公式 tools-reference](https://code.claude.com/docs/en/tools-reference#enterworktree-tool-behavior))、起動元の checkout の配下にある別の worktree への編集も止められるので (Claude Code 2.1.325 の実装)、別の作業場所へ移るときは、`dot_claude/CLAUDE.md` が `ExitWorktree` の `keep` で起動元へ戻らせる (`ExitWorktree` の tool 定義は「ユーザーが頼んだときだけ呼ぶ」と定めるので、頼まれていなくても戻ると明記している)。
  `claude --worktree` とサブエージェントの `isolation: worktree` は Claude Code 自身が作るので、引き続き `.claude/worktrees/` に作られる。agent view や `claude --bg` で起動した background session は、起動元の checkout を編集できない (`worktree.bgIsolation` の既定)。`git worktree add` で作った worktree の中の編集は通るので、`dot_claude/CLAUDE.md` が `.worktrees/<name>` の中で、入らずに作業させる。開いていた session を background へ移した場合は、元の場所で編集を続けられる。

## Codex

- `dot_codex/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/codex/instructions.md` を連結する。共通規約のうち developer instructions (下記) に置く項目は、同じ位置に参照の 1 行を残して抜く。同じ文を 2 回読ませないためで、項目を消さずに残すのは、「前項」などの項目どうしの参照と skill が参照する節を保つため。参照の行は、developer instructions に契約が無いとき (リポジトリの `.codex/agents/` の custom agent) に `~/.config/agents/AGENTS.md` の同じ項目を読ませる。
- project の指示文は `AGENTS.md` を読み、それが無いディレクトリでは `CLAUDE.md` を読む (`dot_codex/modify_private_config.toml` の `project_doc_fallback_filenames`)。
- AGENTS.md は user role で注入されるため、Codex の base prompt (developer role) の既定動作 (質問形を実行の依頼とみなす、範囲が曖昧でも仮定を置いて進める、前のターンの許可を持ち越す、worktree や draft PR を自律的に作る等) を上書きできない。
  これと衝突する少数の項目だけを、`.chezmoitemplates/codex/contract-items` が共通規約から先頭の文言で抜き出し、`.chezmoitemplates/codex/developer-instructions.md` が developer instructions にまとめる。Codex ではこちらが AGENTS.md より優先されるので、写しにすると、共通規約を変えたときに Codex だけ古い条件で振る舞う。
  抜き出す項目の先頭の文言を共通規約で変えたら、同じ変更で `contract-items` の一覧も直す (ちょうど 1 つ見つからなければ描画が fail で止まる)。共通規約に対応する項目が無い Codex 固有の契約 (draft PR を作らない) だけは、`developer-instructions.md` に直接書く。
  developer instructions は、`dot_codex/modify_private_config.toml` が top-level の `developer_instructions` に入れ、custom agent (`dot_codex/agents/*.toml.tmpl`) も自分の `developer_instructions` の末尾に入れる。custom agent の `developer_instructions` は top-level の値を置き換え、AGENTS.md はそのまま引き継ぐ (Codex 0.170.0 の `codex-rs/core/src/agent/role.rs` と `codex-rs/core/src/thread_manager.rs`) ので、入れないと subagent には抜いた項目が届かない。役割の指示と同じ developer role に並ぶので、食い違えば役割の指示に従うと契約の冒頭に書いている。
- Codex から別モデル (Claude Code) へ相談するときは、shell から `claude -p --permission-mode plan` を使う (`.chezmoitemplates/codex/instructions.md`)。plan が塞ぐのは編集で、shell コマンドは通常の permission の判定を通るので、この起動は `codex exec -s read-only` と違い capability としての read-only ではない。hook も止めないので、相談先の checkout の project settings の hook (`-p` は workspace trust を確かめない) と plugin の hook (codex plugin の stop-time review gate を有効にした workspace では、ターンの終わりに Codex のレビューが走る) も動く。`claude` は、この設定の Codex の sandbox (workspace-write、`network_access = true`) の中でも動く。
- `dot_codex/rules/default.rules` の allow は、共通規約と commit / pr skill が求める git の操作のうち、sandbox の中では `.git` に書けず失敗するものを sandbox の外で通す (git のほかに `xcodebuild` も allow している)。後ろに付けられる引数を理由に載せていない操作があるので (対象と理由は rules のコメント)、pr skill の `--onto` の rebase と `git branch -f` は、承認を求められない session (`approval_policy = "never"`) の Codex では実行できない (`on-request` の session では承認を経て実行できる)。`.git` に書く git 以外のコマンドも載せていないので、improve-pr skill の `gh pr checkout` も同じ。載せた操作も後ろの引数は絞れず (`git fetch origin --upload-pack=<command>`・`git push origin --force`・`git switch -C` も一致する)、allow は sandbox を抜けようとする agent を止める境界にはならない。`approval_policy = "never"` では allow の一覧が Codex の prompt に出ないので、一致する形は `.chezmoitemplates/codex/instructions.md` の「git の実行形」節が列挙する (見出しを共通規約の「git」節と分けているのは、skill の「AGENTS.md の `git` 節」という参照の先を 1 つにするため)。rules を変えたら同じ変更で直す。`codex execpolicy check` は argv を直接照合するので、実行時に shell の書き方で一致しなくなる条件 (同節にある、quote していない `~` `^` `*` 等・環境変数の前置き・redirect) は確かめられない。allow は read-only の session にも効き、Claude Code の codex plugin と top-level の `codex review` は `--ignore-rules` を渡せないので、これらの read-only の review でも allow のコマンドは sandbox の外で動く。
- `dot_codex/modify_private_config.toml` の本体は `.chezmoitemplates/codex/config.toml.modify` にあり、`private_dot_codex-private/modify_private_config.toml` も同じ本体を include する。
- `codex-private` (`claude-private` と同じ場所に定義する) は、`CODEX_HOME=~/.codex-private` で Codex を個人アカウント用に起動する。ログイン (`auth.json`) は `CODEX_HOME` ごとに分かれる。
  `~/.codex-private/` の `AGENTS.md`・`agents`・`rules` は `~/.codex` への symlink で、`config.toml` は `~/.codex/config.toml` と同じ template で描画する。user の skill は `CODEX_HOME` によらず `~/.agents/skills` から読まれる。
  fugu の profile と、その鍵を持つ `.env` は会社の Sakana API 用なので置かない。
  アカウントごとに使えるモデルが異なるので、既定のモデルは `.chezmoidata.toml` の `[codex] model` (`~/.codex`) と `private_model` (`~/.codex-private`) で分ける。
  会社の ChatGPT ワークスペースが配る requirements (`~/.codex/cloud-config-bundle-cache.json`) は `approval_policy = "never"` を許さないので、`~/.codex` の session は `on-request` で動く。
- custom agent は `dot_codex/agents/*.toml.tmpl`。model は `.chezmoidata.toml` の `[codex] subagent_model` を参照する。
  custom agent のファイルは親の `sandbox_mode`・`approval_policy`・`model_provider`・`mcp_servers` を上書きできず、子は親の設定を継承するので ([公式 subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents))、これらは書かない。
- Codex には playwright / chrome-devtools MCP を置かない。custom agent の `mcp_servers` は無視され、main config に置くと Claude から呼ぶ `codex exec` の起動のたびに MCP が立ち上がるため。
  Codex のブラウザ確認は、実行環境が提供するブラウザ・画面操作の tool か、プロジェクトの E2E で行う (`codex/instructions.md`)。

## Antigravity

- 1 ファイルの上限 (下記「サイズ予算」) に収めるため、共通規約を `## 成果物と報告` と `## 安全` の見出しの前で 3 つに分けて配る。
  「検証と完了」節までは `dot_gemini/config/AGENTS.md.tmpl` → `~/.gemini/config/AGENTS.md`、「成果物と報告」節から「コード」節までは `dot_gemini/config/GEMINI.md.tmpl` → `~/.gemini/config/GEMINI.md`、「安全」節以降と `.chezmoitemplates/gemini/instructions.md` は `dot_gemini/config/rules/agents-md-part3.md.tmpl` → `~/.gemini/config/rules/agents-md-part3.md`。
  前の 2 つは frontmatter 無しの常時有効な global rule で、この 2 つのパスを読むのは App と CLI (IDE / extensions は `rules/*.md` だけを読むので、共通規約は「安全」節以降しか届かない)。`rules/*.md` は frontmatter の `trigger` が無いか不正だと黙って捨てられるので、3 つ目には `trigger: always_on` を付ける ([公式 rules](https://antigravity.google/docs/rules))。
- 分割と上限の検査は `.chezmoitemplates/gemini/agents-md-part` が行う。
  見出しが見つからないとき、生成物か repo 直下の `AGENTS.md` が 24,000 bytes を超えたとき、4 ファイルの合計が下記「サイズ予算」の 20,000 tokens 相当を超えたときは、テンプレートが fail して描画を止める (Antigravity の設定を配る構成 (`skip_cli_tools` / `skip_windows_extras` が true でない) では、push 時の `chezmoi-dry-run` hook で検出される)。
  共通規約の `## 成果物と報告`・`## 安全` 見出しを変えるときは、分割位置も合わせて直す。
- `dot_gemini/antigravity-cli/modify_private_settings.json` は、管理する key だけを上書きする chezmoi:modify-template。CLI は `/permissions` で足した規則や、起動時に承認した `trustedWorkspaces` を同じファイルに書くので、全量で置き換えると apply のたびに消える。
- Antigravity は `~/.claude/`・`~/.agents/`・CLAUDE.md を自動では読まない。
  project 直下の CLAUDE.md は、補足 (`.chezmoitemplates/gemini/instructions.md`) が着手前に読ませる。
- Antigravity は rule ファイルの中の `@<file>` を file への参照として扱う。
  Antigravity が rule として読む本文 (共通規約・`.chezmoitemplates/gemini/instructions.md`・rule の一覧に出る `dot_claude/rules/*.md` の見出しと `paths`・repo 直下の `AGENTS.md`) には、`@` に path を続けた記述を書かない。
- サブエージェントの `agent.md` の `tools` は、公式 docs の表で既定値が `[]` (空のときに使える tool は未記載) なので、各 wrapper で列挙する。
  `find_by_name` / `grep_search` / `list_dir` は既定の toolset から外れた legacy の tool で、`tools` で明示すれば使える。公式 docs は未対応の tool 名で subagent が hang しうると警告しているので、agy を更新したら tool 名を点検する。

## Grok

- `dot_grok/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/grok/instructions.md` を連結する。
- `compat.claude` (`dot_grok/modify_private_config.toml`) は、`agents = false` (`~/.claude/CLAUDE.md` と project の `.claude/CLAUDE*.md`)・`rules = false` (`~/.claude/rules` と project の `.claude/rules`。有効だと `paths` を無視して全件を常時読む)・`mcps = false` (Claude Code の MCP 設定)・`skills = true`・`hooks = false` (Claude Code の hook) にしている。
  `~/.claude/agents` と Claude Code の plugin の agent は、この設定にかかわらず読まれる (plugin の skill・command は `skills = true` で読まれる)。plugin の hook が `hooks = false` で止まるかは公式 docs に記載が無い。project 直下の `CLAUDE.md` も、同梱の user guide では設定にかかわらず読まれるが、`AGENTS.md` と並ぶ `@AGENTS.md` だけの `CLAUDE.md` は `grok inspect --json` の `projectInstructions` に出ない (grok 1.0.77)。
- project の AGENTS.md / CLAUDE.md は、folder trust (`grok --trust` か対話での許可。`--trust` は `grok --help` に出ない) があるときだけ起動時に読まれる。`grok inspect --json` の `projectTrusted` で確かめる。
- `~/.grok/skills` には配らない。
  Grok は `~/.agents/skills` も読み、`~/.claude/skills` と同名の skill は `~/.agents/skills` 側を採る (中身は同じ include)。bundled と同名の skill は、`~/.agents/skills` にあればそちらが採られ (review)、`~/.claude/skills` にしか無ければ bundled 側が採られる (pdf)。

## skills

- 本体は `dot_claude/skills/<name>/SKILL.md`。
- 他のツールと共有する skill は、本体を include する wrapper で配る。
  Codex と Grok は `dot_agents/skills/<name>/SKILL.md.tmpl` → `~/.agents/skills`、Antigravity は `dot_gemini/config/skills/<name>/SKILL.md.tmpl`。
  共有 skill の本文は他のツールからも読まれ、Grok は `compat.claude.skills = true` で `~/.claude/skills` の全件も読む。
  そのため、どの skill も Claude 固有の機構 (`$ARGUMENTS` の置換・Claude Code の tool 名・bundled skill) に依存させず、使うときは「使える環境では」と条件を付ける。
- commit / pr には `disable-model-invocation` を付けず、自然文の依頼でも起動する。
  skill を読み込んだことは git 操作の許可ではなく、操作してよいかは共通規約の「git」節 (ユーザーの明示指示か、前文の常設の手順) で決まる。
  skill と各ツールの補足には、この条件を写さず「AGENTS.md の `git` 節が認めるとき」と参照で書く。写しは条件の一部 (出所の除外等) を落とし、前文より広く読まれる。「git」節に無い操作 (PR への返信・thread の resolve・review の submit) は常設の手順の対象ではないので、この参照に置き換えず「ユーザーが頼んだときだけ」と書く。

## サブエージェント

- 本文は `.chezmoitemplates/agents/<name>.md`、description は `.chezmoidata.toml` の `[agents]` が単一ソース。
  Claude (`dot_claude/agents/*.md.tmpl`)・Codex (`dot_codex/agents/*.toml.tmpl`。`'''` リテラル内に展開)・Antigravity (`dot_gemini/config/agents/*/agent.md.tmpl`) の各 wrapper が、include と `.agents.<name>` (キーは underscore。無いキーは描画時に fail する) で参照する。
- browser-debugger の定義は Claude 用 (`dot_claude/agents/`) だけに置き、Codex と Antigravity には置かない。Grok は `~/.claude/agents` を読むので、Grok の設定にある playwright / chrome-devtools MCP と合わせて使える。
- playwright / chrome-devtools MCP は、Claude (`.chezmoitemplates/claude.json`)・Grok (`dot_grok/modify_private_config.toml`)・Antigravity (`dot_gemini/config/private_mcp_config.json.tmpl`) のどれでも `--headless` を付けて起動する。
  どちらの server も既定は headed で、agent は実行中に切り替えられないので、共通規約「検証と完了」の headless の規範を MCP 経由の確認に効かせるには、起動の設定で指定するしかない。同じ規範が、MCP が headless で起動する設定であることを受け手に伝えている (受け手は、headed が要るときにウィンドウでの操作を頼まず報告する)。
  MCP のブラウザの画面を見るか手動で操作する (ログイン等) には、設定から `--headless` を外して apply し、ツールを起動し直す。
- Codex / Antigravity の code-reviewer・security-reviewer は、review / security skill の本文を frontmatter を剥いで追記する (`regexReplaceAll` は明示引数形で書く。パイプ形は空文字になる)。
  skill 本文と、Codex の developer instructions に入る共通規約の項目に `'''` を含めると、Codex の TOML が壊れる。

## サイズ予算

- Antigravity は rule ファイル 1 つを、include 展開後に 24,000 bytes で切り詰める ([公式 rules](https://antigravity.google/docs/rules))。
  対象は分割した 3 ファイルと、workspace の常時有効な rule として読まれる repo 直下の `AGENTS.md`。
- Antigravity の global と always_on の rule は、全体で 20,000 tokens の予算を共有する。超過すると、大きいファイルから順に path と description だけの pointer に格下げされ、共通規約が本文として読まれなくなる。
  token の数え方は公式 docs に無いので、日本語 1 文字 (3 bytes) を 1 token と置き、上の 4 ファイルの合計 bytes の 1/3 が 20,000 以下になるようにする。
- Antigravity は skill の本文にも 24 KB の上限を持つ (agy 同梱の changelog。`agy plugin validate` が超過を警告する。公式 docs には記載が無く、超過分の扱いは不明)。Antigravity に配る共有 skill (`dot_gemini/config/skills/`) はこれに収める。
- Codex は project doc (repo root から作業ディレクトリまでの AGENTS.md の連結) を `project_doc_max_bytes` (既定 32 KiB) で切り詰める。`~/.codex/AGENTS.md` は切り詰めの対象外。ただし Codex (0.169) は、global を含む指示文の合計がこの値を超えると warning (`Combined user instructions use <N> bytes ...`) を出す。共通規約と Codex の補足の合計は既定値を超えるので、`codex exec` の出力を含めて session ごとに出るが、切り詰めを示すものではない。
- Grok は指示文のファイルを全文読み込み、上限も切り詰めも無い (同梱の user guide `~/.grok/docs/user-guide/12-project-rules.md` の「File Size」。[公式 project rules](https://docs.x.ai/build/features/project-rules) は上限に触れていない)。同梱の `~/.grok/README.md` にある 1 ファイル 10,000 文字の上限は、公式 docs と同梱の user guide に合わないので根拠にしない。
- 残りの余裕は描画した bytes で測る (`wc -c` は LANG に依らず bytes を数え、`wc -m` は locale 依存)。

  ```sh
  chezmoi execute-template --source . < home/dot_gemini/config/AGENTS.md.tmpl | wc -c
  chezmoi execute-template --source . < home/dot_gemini/config/GEMINI.md.tmpl | wc -c
  chezmoi execute-template --source . < home/dot_gemini/config/rules/agents-md-part3.md.tmpl | wc -c
  wc -c AGENTS.md
  ```

## 配布の確認

テンプレートの描画が通っても、各ツールが実際に読み込むかは別に確かめる。どれもモデルを呼ばない。

- 適用先と source の差分: `chezmoi status` (内容を出さない)。
- Codex: この repo で `codex debug prompt-input "ping"` を実行し、AGENTS.md の連結 (共通規約 → Codex の補足 → repo の AGENTS.md) が末尾まで入っていることと、skill の一覧を見る。
- Grok: `grok inspect --json` の `projectInstructions` (有効な指示文と disabled の一覧)・`skills`・`agents`。
- Antigravity: `agy agents` で agent の一覧を見る。rule の読み込みは、対話の CLI の `/context` で読み込んだ rule のパスを見る (print mode の `agy -p` では使えない)。
