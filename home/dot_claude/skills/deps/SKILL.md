---
name: deps
description: Analyze the project's dependencies — list direct/transitive deps, flag outdated packages, and surface known vulnerabilities — then report prioritized actions. Use when the user wants a dependency audit or update review.
allowed-tools: Read, Glob, Grep, Bash
---

# 依存関係の分析

プロジェクトの依存関係を分析する。

## 手順

### 1. 依存定義ファイルの検出
プロジェクトルートおよびサブディレクトリから依存定義ファイルを探す:
- `package.json` / `package-lock.json` / `pnpm-lock.yaml` / `bun.lockb`
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
