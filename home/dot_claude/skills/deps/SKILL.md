---
name: deps
description: "Audits a project's dependencies without changing anything: outdated packages, known vulnerabilities, and prioritized update actions (「依存関係を棚卸しして」「古いパッケージを洗い出して」「アップデートすべきものある？」). To judge whether a vulnerability is exploitable in the code, use the security skill; to vet one package before adding or upgrading it, use sonatype-guide where available."
allowed-tools: Read, Glob, Grep, Bash(npm ls:*), Bash(npm outdated:*), Bash(npm audit), Bash(npm audit --json), Bash(pnpm list:*), Bash(pnpm outdated:*), Bash(pnpm audit), Bash(pnpm audit --json), Bash(yarn outdated:*), Bash(bun outdated:*), Bash(go list:*), Bash(govulncheck:*), Bash(pip list:*), Bash(pip-audit), Bash(uv tree --frozen:*), Bash(uv audit --frozen), Bash(uv audit --frozen --output-format json), Bash(uv pip list:*), Bash(cargo tree --locked:*), Bash(cargo outdated:*), Bash(cargo audit --file Cargo.lock), Bash(cargo audit --file Cargo.lock --json), Bash(bundle outdated:*), Bash(dart pub outdated:*), Bash(flutter pub outdated:*)
disallowed-tools: Edit, Write, NotebookEdit
---

# 依存関係の分析

プロジェクトの依存関係を分析する。ファイルと環境は変更しない (install・lock ファイルの更新・audit の fix 系は実行せず、更新は推奨アクションとして示す)。

## 手順

### 1. 依存定義ファイルの検出
プロジェクトルートとサブディレクトリから、依存を定義する manifest と lock ファイルを探す (例: `package.json` と各パッケージマネージャーの lock、`go.mod`、`pyproject.toml` / `requirements.txt` / `uv.lock`、`Cargo.toml`、`Gemfile`、`pubspec.yaml`)。

### 2. 依存関係の分析
各パッケージマネージャーの読み取り系のコマンド (例: `npm ls` / `npm outdated` / `npm audit --json`、`pnpm list` / `pnpm outdated`、`go list -m -u all` / `govulncheck ./...`、`pip list --outdated` / `pip-audit`、`uv tree --frozen --outdated` / `uv audit --frozen`、`cargo tree --locked` / `cargo outdated` / `cargo audit --file Cargo.lock`、`bundle outdated`、`dart pub outdated`) で以下を調査する:
- 直接依存と間接依存の一覧
- 古いバージョンの依存パッケージ (outdated チェック)
- 既知のセキュリティ脆弱性 (audit コマンドが利用可能な場合)

依存を解決し直すコマンドには、lock ファイルが無いか manifest と食い違うと lock を生成・更新するもの (`uv tree`・`uv audit`・`cargo tree`・`cargo outdated`・`cargo audit`) があるので、次の形で実行する:
- `uv tree`・`uv audit` には `--frozen` を付け、既存の `uv.lock` をそのまま読む (`--locked` も lock を書かないが、lock の検証のために依存を解決し直し、対象の build backend を実行しうる)。lock が manifest と合うかは確かめないので、結果は既存の lock のものとして報告する。lock が無ければ失敗する。
- `cargo tree` には `--locked` を付ける。lock を書かず、lock が無いか manifest と食い違うと失敗する。
- `cargo outdated` は lock の書き込みを止めるフラグを持たないので、`cargo tree --locked` が通ったときだけ実行する。
- `cargo audit` は lock が無いと生成するので、workspace root で `--file Cargo.lock` を付けて既存の lock を読ませる。
- lock が無い・古いことで失敗したら、lock を生成・更新せずにその旨を報告し、manifest と既存の lock から読める範囲で分析を続ける。

`pip list` と引数なしの `pip-audit` は、manifest や lock ではなく、Python 環境に install 済みのものを読む。`pip list` が読むのは実行した `pip` の環境なので、プロジェクトの venv の `pip` を使うか、`uv pip list --python <venv の Python>` で対象を指定する。`pip-audit` が読むのは自身が動いている Python の環境なので (venv を activate しても変わらない)、venv に入っている `pip-audit` を使うか、`PIPAPI_PYTHON_LOCATION` に venv の Python を指定する。プロジェクトの venv を対象にできなければ、install せずにファイルから調べる (uv のプロジェクトは上の `uv` のコマンド、バージョンを固定した requirements は `pip-audit -r <file> --no-deps --disable-pip`。この 2 つのフラグが無い `pip-audit -r` は `pip install -r` と同等の依存解決をする)。

### 3. 報告

以下の構成で報告する:

**推奨アクション**: 優先度の高い順にやるべきことをリスト化
**依存概要**: パッケージマネージャー、直接依存数、間接依存数
**更新が必要なパッケージ**: パッケージ名、現在のバージョン、最新バージョン、breaking change の有無
**セキュリティアラート**: 脆弱性の重大度とアドバイザリーへのリンク (判明している場合)
