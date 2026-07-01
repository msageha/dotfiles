---
name: diagram
description: Analyze code and generate architecture/structure diagrams in Mermaid (flowchart, class, sequence, ER, state, or C4). Use when the user wants to visualize code structure, flow, or relationships.
allowed-tools: Read, Grep, Glob
argument-hint: [file-or-directory]
---

# ダイアグラム生成

`$ARGUMENTS` を対象としてコードを分析し、構造を視覚化するダイアグラムを生成する。引数が未指定の場合はプロジェクト全体を対象とする。

## 手順

### 1. コードの分析
対象のコードを読み込み、以下を把握する:
- モジュール / パッケージ構成
- クラスやインターフェースの継承・実装関係
- 主要な関数間の呼び出し関係
- データの流れ

### 2. ダイアグラム種別の選択
コードの特性に最も適した図を選ぶ:
- **フローチャート**: 処理フローやアルゴリズム
- **クラス図**: オブジェクト指向の構造
- **シーケンス図**: コンポーネント間のやり取り
- **ER図**: データモデルの関係
- **状態遷移図**: ステートマシンやライフサイクル
- **アーキテクチャ図** (C4 style): システム全体の構成

複数の図が有効な場合は、最も理解に役立つものを優先し、必要に応じて複数生成する。

### 3. 出力
Mermaid 記法でダイアグラムを出力する。各図には以下を含める:
- 図の説明 (何を表しているか)
- Mermaid コードブロック
- 図に含めなかった簡略化ポイントの注記 (該当する場合)

draw.io MCP が利用可能であれば、Mermaid を使って draw.io で開くことも提案する。
