#!/usr/bin/env bash
# run.sh の出力先を集計し、ケース × 版ごとの自動判定と採点の通過率を Markdown で出す。
# 終わっていない実行と採点も数える。成功した実行だけで比べると、失敗の多い版が良く見えるため。
set -euo pipefail

out=$1
for run_dir in "$out"/runs/*/*/*/; do
  run_dir=${run_dir%/}
  index=$(basename "$run_dir") arm=$(basename "$(dirname "$run_dir")") case_name=$(basename "$(dirname "$(dirname "$run_dir")")")
  # result は再開したターンごとに出る。費用は累計なので最後の値を使い、turn 数・拒否・文字数 (ユーザーが読む応答の合計) は全 result から数える。
  result=$(jq -cs 'map(select(.type == "result")) | if length == 0 then null else last + {
      num_turns: (map(.num_turns // 0) | add),
      result: (map(.result // "" | select(length > 0)) | join("\n")),
      permission_denials: (map(.permission_denials // []) | add | unique_by(.tool_use_id))} end' "$run_dir/stream.jsonl" 2> /dev/null || true)
  jq -cn --arg case "$case_name" --arg arm "$arm" --arg index "$index" \
    --argjson checks "$(if [[ -e $run_dir/checks.jsonl ]]; then jq -s . "$run_dir/checks.jsonl"; else echo null; fi)" \
    --argjson judge "$(cat "$run_dir/judge.json" 2> /dev/null || echo null)" \
    --argjson result "${result:-null}" \
    --argjson codex "$(if [[ -e $run_dir/trace/codex.log ]]; then grep -c -E '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$run_dir/trace/codex.log" || true; else echo 0; fi)" \
    --argjson seconds "$(cat "$run_dir/seconds" 2> /dev/null || echo 0)" \
    --argjson exit "$(cat "$run_dir/exit" 2> /dev/null || echo 0)" \
    '{case: $case, arm: $arm, index: $index, checks: $checks, rubric: $judge,
      error: ($exit != 0 or $result == null or $result.is_error == true), cost: ($result.total_cost_usd // 0),
      turns: ($result.num_turns // 0), denied: (($result.permission_denials // []) | length),
      chars: (($result.result // "") | length), codex: $codex, seconds: $seconds}'
done | jq -rs '
  def rate(xs): if (xs | length) == 0 then "-" else "\(xs | map(select(.pass)) | length)/\(xs | length)" end;
  def avg(f): if length == 0 then 0 else (map(f) | add / length) end;
  group_by(.case) as $cases
  | "| case | arm | runs | 未完了 | 未採点 | 自動判定 | 採点 | 秒 | USD | turns | 文字数 | codex | 拒否 | error |",
    "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ($cases[] | group_by(.arm)[] | (map(select(.checks != null))) as $done |
      "| \(.[0].case) | \(.[0].arm) | \(length) | \(map(select(.checks == null)) | length) | \($done | map(select(.rubric == null)) | length) | \(rate($done | map(.checks[]))) | \(rate($done | map(.rubric // [] | .[]))) | \($done | avg(.seconds) | floor) | \($done | avg(.cost) * 100 | round / 100) | \($done | avg(.turns) * 10 | round / 10) | \($done | avg(.chars) | floor) | \($done | map(.codex) | add // 0) | \($done | map(.denied) | add // 0) | \($done | map(select(.error)) | length) |"),
    "",
    "## 項目ごとの通過数 (版ごと)",
    ($cases[] | map(select(.checks != null)) as $runs
      | ($runs | map(.arm) | unique) as $arms
      | "", "### \($runs[0].case)",
        "| 項目 | \($arms | join(" | ")) |", "|---|\($arms | map("---") | join("|"))|",
        (($runs | map(.checks[].id, (.rubric // [] | .[].id)) | unique)[] as $id
          | "| \($id) | \([$arms[] as $a | $runs | map(select(.arm == $a)) | rate(map((.checks + (.rubric // []))[] | select(.id == $id)))] | join(" | ")) |")),
    "",
    "## 採点で落ちた項目",
    (.[] | . as $r | (.rubric // [])[] | select(.pass | not) | "- \($r.case) / \($r.arm) / \($r.index) / \(.id): \(.reason)")'
