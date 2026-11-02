# LLM エージェント指示文の構成

このリポジトリが配る LLM エージェント (Claude Code / Codex / Antigravity / Grok) 向けの指示文・skill・サブエージェントの配置と、コードから読み取れない契約をまとめる。
指示文ファイルを編集・レビューする前に、この文書と `home/dot_claude/rules/agent-config.md` (編集の規範) を読む。
各ツールの設定 (Claude の settings*.json、Codex の config.toml / rules、Grok の config.toml、Gemini の settings.json) を編集するときは `home/dot_claude/rules/claude-settings.md` も読む。
Claude Code ではこの 2 つの rule が path-scoped rule として自動で読まれる。
以下のパスは `home/` を省いて書く。

## 原則

- 共通規約は `dot_config/agents/AGENTS.md` の 1 箇所に書き、各ツールの adapter (下記) にはそのツール固有の機構だけを書く。
  rule の読み方、MCP の使い分け、test-runner と test skill の使い分けも共通規約にあり、adapter には MCP の有無の違いや独立レビュー・別モデルの手段など、そのツール固有の機構を書く。
- この repo の rules を path に応じて自動で読むのは Claude Code だけで、Codex / Antigravity / Grok にはその形で配っていない (Antigravity の glob で読ませる rule には未対応)。
  `.chezmoitemplates/agents/rules-index` が `dot_claude/rules/*.md` の見出しと frontmatter の `paths` から rule の一覧を生成し、各ツールの補足 (`.chezmoitemplates/{codex,gemini,grok}/instructions.md`) が include して、着手前にそこから選んで読ませる。
  rule の追加・削除・`paths` の変更は一覧に自動で反映される。rule が 1 つも見つからないときは描画を fail で止める。
- 相談・独立レビューの工程は、共通規約の「主担当」(成果物をユーザーへ返すエージェント) だけが回す。
  Claude から相談・レビューを頼まれて起動した Codex などが、同じ工程を起動し直さないようにするため。
- 各 `*.tmpl` 先頭の来歴コメントは chezmoi テンプレートコメントなので描画されない。

## Claude Code

- `dot_claude/CLAUDE.md` が `@~/.config/agents/AGENTS.md` で共通規約を import し、Claude 固有の機構 (Stop hook、Agent tool の `subagent_type`、codex CLI の呼び方、plugin 由来の MCP) を足す。
  MCP の項には、ツール定義や server instructions に無い運用規範を持つサーバーだけを載せる (description は再掲しない)。
- この repo で作業すると、`home/dot_claude/CLAUDE.md` が nested の CLAUDE.md として読み込まれ、適用済みの `~/.claude/CLAUDE.md` と重複する。
  user settings の `claudeMdExcludes` (`dot_claude/private_settings.json.tmpl`) で外している。

## Codex

- `dot_codex/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/codex/instructions.md` を連結する。
- AGENTS.md は user role で注入されるため、Codex の base prompt (developer role) の既定動作 (質問形を実行の依頼とみなす、worktree や draft PR を自律的に作る等) を上書きできない。
  これと衝突する少数の契約だけを `.chezmoitemplates/codex/developer-instructions.md` に書き、`dot_codex/modify_private_config.toml` が top-level の `developer_instructions` に入れる。
- custom agent は `dot_codex/agents/*.toml.tmpl`。model は `.chezmoidata.toml` の `[codex] subagent_model` を参照する。
  custom agent のファイルは親の `sandbox_mode`・`approval_policy`・`model_provider`・`mcp_servers` を上書きできず、子は親の設定を継承するので ([公式 subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents))、これらは書かない。
- Codex には playwright / chrome-devtools MCP を置かない。custom agent の `mcp_servers` は無視され、main config に置くと Claude から呼ぶ `codex exec` の起動のたびに MCP が立ち上がるため。
  browser_debugger も Codex には置かず、Codex のブラウザ確認は、実行環境が提供するブラウザ・画面操作の tool か、プロジェクトの E2E で行う (`codex/instructions.md`)。

## Antigravity (Gemini)

- 1 ファイルの上限 (下記「サイズ予算」) に収めるため、共通規約を `## git` 見出しの前後で分けて配る。
  前半は `dot_gemini/config/AGENTS.md.tmpl` → `~/.gemini/config/AGENTS.md`、後半と `.chezmoitemplates/gemini/instructions.md` は `dot_gemini/config/GEMINI.md.tmpl` → `~/.gemini/config/GEMINI.md`。
  どちらも frontmatter 無しの常時有効な global rule で、この 2 つのパスを読むのは App と CLI (IDE / extensions の global rule は `~/.gemini/AGENTS.md`・`~/.gemini/GEMINI.md`・`~/.gemini/config/rules/*.md`)。
- 分割と上限の検査は `.chezmoitemplates/gemini/agents-md-part` が行う。
  見出しが見つからないときと、生成物が 24,000 bytes を超えたときは、テンプレートが fail して描画を止める。
  共通規約の `## git` 見出しを変えるときは、分割位置も合わせて直す。
- Antigravity は `~/.claude/`・`~/.agents/`・CLAUDE.md を自動では読まない。rule は補足に生成した一覧から選んで読ませる。
- サブエージェントの `agent.md` の `tools` は、公式 docs の表で既定値が `[]` (空のときに使える tool は未記載) なので、各 wrapper で列挙する。
  `find_by_name` / `grep_search` / `list_dir` は agy 1.4.12 で既定の toolset から外れた legacy (同梱の changelog。`tools` で明示すれば使える) で、公式 docs は未対応の tool 名で subagent が hang しうると警告している。agy を更新したら tool 名を点検する。

## Grok

- `dot_grok/AGENTS.md.tmpl` が、共通規約と `.chezmoitemplates/grok/instructions.md` を連結する。
- `compat.claude` (`dot_grok/modify_private_config.toml`) は、`agents = false` (`~/.claude/CLAUDE.md` と project の `.claude/CLAUDE*.md`)・`rules = false` (`~/.claude/rules` と project の `.claude/rules`。有効だと `paths` を無視して全件を常時読む)・`skills = true` にしている。
  project 直下の `CLAUDE.md` と `~/.claude/agents` は、この設定にかかわらず読まれる。
- project の AGENTS.md / CLAUDE.md は、folder trust (`grok --trust` か対話での許可。`--trust` は `grok --help` に出ない) があるときだけ起動時に読まれる。`grok inspect --json` の `projectTrusted` で確かめる。
- `~/.grok/skills` のコピーは廃止し、`.chezmoiremove` で配布していた SKILL.md を適用先から消す。
  Grok は `~/.agents/skills` も読み、`~/.claude/skills` と同名の skill は `~/.agents/skills` 側を採る (中身は同じ include)。bundled と同名の skill (pdf) は bundled 側が採られる。

## skills

- 本体は `dot_claude/skills/<name>/SKILL.md`。
- 共有の 9 本 (commit / deps / explain / improve-pr / pr / refactor / review / security / test) は、本体を include する wrapper で他のツールにも配る。
  Codex と Grok は `dot_agents/skills/<name>/SKILL.md.tmpl` → `~/.agents/skills`、Antigravity は `dot_gemini/config/skills/<name>/SKILL.md.tmpl`。
  共有 skill の本文は他のツールからも読まれ、Grok は `compat.claude.skills = true` で `~/.claude/skills` の全件も読む。
  そのため、どの skill も Claude 固有の機構 (`$ARGUMENTS` の置換・Claude Code の tool 名・bundled skill・Stop hook) に依存させず、使うときは「使える環境では」と条件を付ける。
- commit / pr には `disable-model-invocation` を付けず、自然文の依頼でも起動する。
  skill を読み込んだことは git 操作の許可ではなく、操作してよいかは共通規約の「git」節 (ユーザーの明示指示) で決まる。

## サブエージェント

- 本文は `.chezmoitemplates/agents/<name>.md`、description は `.chezmoidata.toml` の `[agents]` が単一ソース。
  Claude (`dot_claude/agents/*.md.tmpl`)・Codex (`dot_codex/agents/*.toml.tmpl`。`'''` リテラル内に展開)・Gemini (`dot_gemini/config/agents/*/agent.md.tmpl`) の各 wrapper が、include と `.agents.<name>` (キーは underscore。無いキーは描画時に fail する) で参照する。
- browser-debugger の定義は Claude 用 (`dot_claude/agents/`) だけに置き、Codex と Antigravity には置かない。Grok は `~/.claude/agents` を読むので、Grok の設定にある playwright / chrome-devtools MCP と合わせて使える。
- Codex / Gemini の code-reviewer・security-reviewer は、review / security skill の本文を frontmatter を剥いで追記する (`regexReplaceAll` は明示引数形で書く。パイプ形は空文字になる)。
  skill 本文に `'''` を含めると Codex の TOML が壊れる。

## サイズ予算

- Antigravity は rule ファイル 1 つを、include 展開後に 24,000 bytes で切り詰める ([公式 rules](https://antigravity.google/docs/rules))。
  単位は bytes なので、日本語 (UTF-8 で 1 文字 3 bytes) では約 8,000 文字になる。rules の上限を 12,000 characters とする記述は現行の公式 docs に無い。
  対象は分割した 2 ファイルと、workspace の常時有効な rule として読まれる repo 直下の `AGENTS.md`。
- Antigravity の global と always_on の rule は、全体で 20,000 tokens の予算を共有する。超過すると、大きいファイルから順に path と description だけの pointer に格下げされ、共通規約が本文として読まれなくなる。
  上の 3 ファイルの合計 bytes も見る (日本語が多いので、bytes の 1/4 程度の tokens になる)。
- Codex は project doc (repo root から作業ディレクトリまでの AGENTS.md の連結) を `project_doc_max_bytes` (既定 32 KiB) で切り詰める。`~/.codex/AGENTS.md` はこの上限の対象外。
- 共通規約・`.chezmoitemplates/gemini/instructions.md`・repo 直下の `AGENTS.md` を増やしたら、bytes を計測する。
  `wc -c` は LANG に依らず bytes を数える (`wc -m` は locale 依存)。

  ```sh
  chezmoi execute-template < home/dot_gemini/config/AGENTS.md.tmpl | wc -c
  chezmoi execute-template < home/dot_gemini/config/GEMINI.md.tmpl | wc -c
  wc -c AGENTS.md
  ```

## 配布の確認

テンプレートの描画が通っても、各ツールが実際に読み込むかは別に確かめる。どれもモデルを呼ばない。

- 適用先と source の差分: `chezmoi status` (内容を出さない)。
- Codex: この repo で `codex debug prompt-input "ping"` を実行し、AGENTS.md の連結 (共通規約 → Codex の補足 → repo の AGENTS.md) が末尾まで入っていることと、skill の一覧を見る。
- Grok: `grok inspect --json` の `projectInstructions` (有効な指示文と disabled の一覧)・`skills`・`agents`。
- Antigravity: `agy agents` で agent の一覧を見る。rule の読み込みはモデルを呼ばないと確かめられない。

## 振る舞いの確認

規範を足す・削る・言い換える改訂では、`mise run eval-agent-instructions` で改訂前 (`old`) と改訂後 (`new`) の Claude Code を同じ依頼で比べ、狙った振る舞いの変化と、ユーザー由来の振る舞いの喪失が無いことを確かめる (仕組み・費用・限界は `evals/agent-instructions/README.md`)。
規範を削る候補は、指示文なし (`none`) でも同じ振る舞いになるかで見分けられる。
ただし測れるのは、ケースのある規範についての 1 回の依頼への振る舞いだけで、ケースの無い規範に差が出ないことは削る根拠にならない。
