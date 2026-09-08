---
name: refactor
description: "Refactor: plan and apply a behavior-preserving refactor of a file or symbol, keeping existing tests green and the change to roughly one commit. Use when the user wants to clean up or restructure code without changing its observable behavior."
argument-hint: <file-path-or-symbol>
---

# リファクタリング

`$ARGUMENTS` を対象としてリファクタリングを行う。

## Goal

対象コードを、外部から観測可能な振る舞いを保ったまま、より読みやすく保守しやすい状態にする。

## Acceptance criteria

- リファクタリング前後で既存テストの結果が変わらない (テストが無い場合は lint / build / 型検査など既存の検証手段で確認し、テストが無いことと作成の要否を完了報告に書く。途中で止まらない)
- 1 commit にまとまるサイズに収まっている (大規模になる場合は分割計画を提示する)
- 最終レポートに「対象」「目的」「適用パターン」「変更概要」「差分サマリー」「再実行したテスト結果」を含む

## Constraints

- 外部から観測可能な振る舞いを変更しない
- 以下のいずれかに該当する場合のみ、変更適用前にユーザー承認を取る:
  - 公開 API のシグネチャ変更を伴う
  - スコープが 1 commit に収まらず分割が必要
  - 既存テストの削除、または期待値・検証対象の仕様を変える修正が必要 (rename・import path・シグネチャの機械的な追従は範囲内)
  - 依存パッケージの追加・削除を伴う
- 上記以外は委譲範囲として、計画立案 → 適用 → テスト再実行 → 結果報告まで一括で行う

## 手順

### 1. 現状分析
対象コードと関連ファイルを読み込み、以下を把握する:
- コードの責務と依存関係
- 現在のコードの問題点 (複雑度、重複、命名、構造)
- このコードの呼び出し元と影響範囲
- 既存テストの存在と網羅状況

### 2. リファクタリング計画
内部で以下の形式の計画を立案する。Constraints の承認対象に該当する場合のみユーザーに提示する。

**対象**: 変更するファイルと範囲
**目的**: なぜリファクタリングが必要か
**手法**: 適用するリファクタリングパターン (Extract Method, Move, Rename, Simplify Conditional 等)
**変更概要**: 何をどう変えるか
**リスク**: 破壊的変更の可能性と対策

### 3. 実行
計画に沿って変更を適用し、テストを再実行して結果がリファクタリング前から変わらないことを確認する。完了後に差分サマリーと検証結果を表示する。
