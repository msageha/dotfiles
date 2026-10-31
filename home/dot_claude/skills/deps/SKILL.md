---
name: deps
description: "Audits a project's dependencies: lists direct and transitive packages, flags outdated ones, surfaces known vulnerabilities, and reports prioritized update actions without changing anything. Use when the user asks for a dependency audit or update review (「依存関係を棚卸しして」「古いパッケージを洗い出して」「アップデートすべきものある？」). It plans updates; for judging whether a vulnerability is exploitable in the code, use the security skill, and for vetting one specific package before adding or upgrading it, use sonatype-guide where available."
allowed-tools: Read, Glob, Grep, Bash
disallowed-tools: Edit, Write, NotebookEdit
---

# 依存関係の分析

プロジェクトの依存関係を分析する。ファイルと環境は変更しない (install・lock ファイルの更新・audit の fix 系は実行せず、更新は推奨アクションとして示す)。

## 手順

### 1. 依存定義ファイルの検出
プロジェクトルートおよびサブディレクトリから依存定義ファイルを探す:
- `package.json` / `package-lock.json` / `pnpm-lock.yaml` / `yarn.lock` / `bun.lock` / `bun.lockb`
- `go.mod` / `go.sum`
- `pubspec.yaml` / `pubspec.lock`
- `requirements.txt` / `pyproject.toml` / `poetry.lock` / `uv.lock`
- `Cargo.toml` / `Cargo.lock`
- `Gemfile` / `Gemfile.lock`

### 2. 依存関係の分析
各パッケージマネージャーの適切なコマンドを使って以下を調査する:
- 直接依存と間接依存の一覧
- 古いバージョンの依存パッケージ (outdated チェック)
- 既知のセキュリティ脆弱性 (audit コマンドが利用可能な場合)

### 3. 報告

以下の構成で報告する:

**依存概要**: パッケージマネージャー、直接依存数、間接依存数
**更新が必要なパッケージ**: パッケージ名、現在のバージョン、最新バージョン、breaking change の有無
**セキュリティアラート**: 脆弱性の重大度とアドバイザリーへのリンク (判明している場合)
**推奨アクション**: 優先度の高い順にやるべきことをリスト化
