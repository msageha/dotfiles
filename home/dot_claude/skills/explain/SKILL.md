---
name: explain
description: Explains a file, symbol, or piece of code in Japanese, covering what it does and why, its structure, control / data flow, dependencies, and pitfalls, scaled to the size of the target. Use when the user wants to understand how some code works (「このコードを解説して」「これ何してる？」「仕組みを教えて」「処理の流れを説明して」).
allowed-tools: Read, Grep, Glob
disallowed-tools: Edit, Write, NotebookEdit
argument-hint: <file-path-or-symbol>
---

# コード解説

引数 (`$ARGUMENTS`。空または置換されない場合は依頼文) で指定されたコードを解説する。ファイルと環境は変更しない。

## 手順

1. 対象がファイルパスの場合はそのファイルを読み込む。シンボル名の場合はコードベースから該当箇所を検索する。
2. 必要に応じて関連ファイル (インポート元、呼び出し元、型定義) も読み込み、コンテキストを把握する。
3. 次の観点のうち対象に当てはまるものを、日本語の散文で解説する。小さな関数 1 つなら数段落で足り、見出しは要らない。複数のモジュールにまたがる対象のときだけ、観点ごとに見出しで分ける。

## 観点

- 概要: このコードが何を行い、なぜ存在するのか (1-3 文)。
- アーキテクチャ: 主要な構成要素 (関数、クラス、モジュール) の役割と関係。必要に応じて ASCII 図を使う。
- 処理フロー: データや制御がどのように流れるか。
- 外部依存: このコードが依存する外部ライブラリやサービスと、他のコードからどう利用されるか。
- 注意点: バグが起きやすい箇所、暗黙の前提条件、パフォーマンス特性など把握しておくべきこと。
