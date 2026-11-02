#!/usr/bin/env bash
# 共通規約と Claude 向けの補足 (CLAUDE.md) の版ごとに、Claude Code の振る舞いを同じケースで比べる。
# 使い方: run.sh [-a <arms>] [-n <runs>] [-j <jobs>] [-c <case glob>] [-b <base ref>] [-o <out dir>]
#   arms: old (base ref の版)・new (作業ツリーの版)・none (指示文なし)・<name>=<描画済みの CLAUDE.md> をカンマ区切りで並べる。
#   -o に既存の出力先を渡すと、終わっていない実行と採点だけを行う。
set -euo pipefail

eval_dir=$(cd "$(dirname "$0")" && pwd)
repo_root=$(git -C "$eval_dir" rev-parse --show-toplevel)
usage() {
  sed -n '3,6p' "$0" | sed 's/^# //' >&2
  exit 2
}

arms=old,new runs=2 jobs=4 case_glob='*' base_ref=HEAD out=
while getopts 'a:n:j:c:b:o:' opt; do
  case $opt in
    a) arms=$OPTARG ;;
    n) runs=$OPTARG ;;
    j) jobs=$OPTARG ;;
    c) case_glob=$OPTARG ;;
    b) base_ref=$OPTARG ;;
    o) out=$OPTARG ;;
    *) usage ;;
  esac
done
(($# == OPTIND - 1)) || usage
# 出力先の名前は、作業ディレクトリのパスとしてエージェントに見えるので中立にする。
out=${out:-$(mktemp -d "${TMPDIR:-/tmp}/ws.XXXXXX")}
mkdir -p "$out/variants"
out=$(cd "$out" && pwd)
export OUT=$out

# CLAUDE.md の import 行を共通規約の本文に置き換え、ユーザースコープで読まれる内容を 1 ファイルにする。
render() {
  awk -v agents="$2" '$0 == "@~/.config/agents/AGENTS.md" { while ((getline line < agents) > 0) print line; next } { print }' "$1"
}

names=()
IFS=, read -r -a arm_specs <<< "$arms"
for spec in "${arm_specs[@]}"; do
  name=${spec%%=*}
  rendered="$out/variants/$name.md.new"
  case $spec in
    old)
      git -C "$repo_root" show "$base_ref:home/dot_claude/CLAUDE.md" > "$out/variants/base-claude.md"
      git -C "$repo_root" show "$base_ref:home/dot_config/agents/AGENTS.md" > "$out/variants/base-agents.md"
      render "$out/variants/base-claude.md" "$out/variants/base-agents.md" > "$rendered"
      rm "$out/variants/base-claude.md" "$out/variants/base-agents.md"
      ;;
    new) render "$repo_root/home/dot_claude/CLAUDE.md" "$repo_root/home/dot_config/agents/AGENTS.md" > "$rendered" ;;
    none) : > "$rendered" ;;
    *=*) cp "${spec#*=}" "$rendered" ;;
    *)
      echo "unknown arm: $spec" >&2
      exit 2
      ;;
  esac
  # 再開したときに版の中身が変わっていると、同じ版の名前に違う指示文の結果が混ざるので止める。
  if [[ -e $out/variants/$name.md ]] && ! cmp -s "$rendered" "$out/variants/$name.md"; then
    echo "$name differs from the instructions already used in $out; use another output directory" >&2
    exit 2
  fi
  mv "$rendered" "$out/variants/$name.md"
  names+=("$name")
done

for case_dir in "$eval_dir"/cases/$case_glob/; do
  for name in "${names[@]}"; do
    for ((i = 1; i <= runs; i++)); do
      printf '%s %s %s\n' "$(basename "$case_dir")" "$name" "$i"
    done
  done
done | xargs -P "$jobs" -L 1 "$eval_dir/run-one.sh" || echo "some runs failed; rerun with -o $out" >&2

find "$out/runs" -mindepth 3 -maxdepth 3 -type d -print0 |
  xargs -0 -P "$jobs" -n 1 "$eval_dir/judge.sh" || echo "some judgements failed; rerun with -o $out" >&2
# shellcheck source=lib.sh
source "$eval_dir/lib.sh"
[[ -d $out/j ]] && remove_project_dir "$out/j"
"$eval_dir/report.sh" "$out" > "$out/report.md"
echo "report: $out/report.md"
