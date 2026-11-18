---
name: diagram
description: "Generates Mermaid diagrams (flowchart, class, sequence, ER, state, or C4) of code architecture, flow, or relationships. Use when the user wants code visualized (「図にして」「構成図を描いて」「シーケンス図で見せて」)."
allowed-tools: Read, Grep, Glob
argument-hint: "[file-or-directory]"
---

# ダイアグラム生成

引数 (`$ARGUMENTS`。空または置換されない場合は依頼文) で指定された対象のコードを分析し、構造を図にする。対象の指定が無ければプロジェクト全体を対象にする。図は、依頼が書き込み先 (README・docs 等) を指定していればそこへ書き、指定が無ければファイルを変更せずに応答に出力する。

## 手順

### 1. 分析と図の選択
対象のコードを読み、図で伝える構造 (モジュール構成・継承や実装の関係・呼び出し関係・データの流れ・状態遷移等) に合う種別の図を選ぶ。複数の図が有効なら、最も理解に役立つものを優先し、必要に応じて複数出す。

### 2. 出力
Mermaid 記法でダイアグラムを出力する。各図には以下を含める:
- 図の説明 (何を表しているか)
- Mermaid コードブロック
- 図で省いたものの注記 (あれば)

編集できる図を求められたら、draw.io MCP が使える環境では Mermaid を渡して draw.io で開く。
