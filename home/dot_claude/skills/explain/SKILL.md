---
name: explain
description: Explain a file, symbol, or piece of code in Japanese, covering overview, architecture, control/data flow, dependencies, and pitfalls. Use when the user wants to understand how some code works.
allowed-tools: Read, Grep, Glob
argument-hint: <file-path-or-symbol>
---

# コード解説

`$ARGUMENTS` を対象として、コードの解説を行う。

## 手順

1. 対象がファイルパスの場合はそのファイルを読み込む。シンボル名の場合はコードベースから該当箇所を検索する。
2. 必要に応じて関連ファイル (インポート元、呼び出し元、型定義) も読み込み、コンテキストを把握する。
3. 以下の構成で日本語で解説する。

## 出力構成

### 概要
このコードが何を行い、なぜ存在するのかを1-3文で説明。

### アーキテクチャ
主要な構成要素 (関数、クラス、モジュール) の役割と関係を説明。必要に応じて ASCII 図を使用。

### 処理フロー
データや制御がどのように流れるかをステップバイステップで説明。

### 外部依存
このコードが依存する外部ライブラリやサービス、および他のコードからどう利用されるか。

### 注意点
バグが起きやすい箇所、暗黙の前提条件、パフォーマンス特性など把握しておくべきこと。
