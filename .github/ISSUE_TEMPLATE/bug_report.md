---
name: バグ報告
about: バグを報告する
title: "[Bug] "
labels: bug
assignees: ""
---

## 再現手順

<!-- 実行した chezmoi コマンド (例: chezmoi apply) と、エラーが出ればその出力。chezmoi diff と --verbose の出力は API キーや秘密鍵を含みうるので貼らない -->

1.

## 期待する動作

## 実際の動作

## 環境

- OS / アーキテクチャ:
- chezmoi のバージョン (`chezmoi --version`):
- フラグの値 (``chezmoi execute-template '{{ range list `skip_cli_tools` `skip_gui_tools` `skip_secrets` `skip_windows_extras` }}{{ . }}={{ dig . `-` $ }} {{ end }}'``):
