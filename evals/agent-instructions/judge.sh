#!/usr/bin/env bash
# 1 回の実行の最終応答・ツール呼び出しとその出力・差分を、版を伏せて LLM に基準ごとに採点させる。
# 使い方: judge.sh <run_dir>。JUDGE_MODEL を環境変数で受ける。
set -euo pipefail

run_dir=$(cd "$1" && pwd)
eval_dir=$(cd "$(dirname "$0")" && pwd)
out=$(cd "$run_dir/../../../.." && pwd)
case_name=$(basename "$(dirname "$(dirname "$run_dir")")")
[[ -s $run_dir/judge.json || ! -e $run_dir/checks.jsonl ]] && exit 0

repo="$(cat "$run_dir/workdir")/order-service"
base=$(cat "$run_dir/before/head")
artifact="$run_dir/artifact.md"
# 長い出力は head で切り詰める。上流が SIGPIPE で終わっても失敗として扱わないよう、その pipeline に || true を付ける。
{
  echo "## ユーザーの依頼"
  cat "$eval_dir/cases/$case_name/prompt.txt"
  echo
  # バックグラウンドの処理を待つと、再開したターンごとに result が出る。本文が空のことも、回答の後の短い連絡のこともあるので、
  # どれをユーザーが結論として読むかは採点役に判断させる。
  echo "## エージェントの応答 (出した順)"
  jq -rs 'map(select(.type == "result") | .result // "" | select(length > 0))
    | if length == 0 then "(応答なし)" else to_entries | map("### 応答 \(.key + 1)\n\(.value)\n") | join("\n") end' "$run_dir/stream.jsonl"
  echo
  echo "## ツール呼び出しとその出力 (実行順。出力は先頭だけ)"
  jq -rs '
    (map(select(.type == "user") | .message.content[]? | select(.type == "tool_result")
      | {key: .tool_use_id, value: (if (.content | type) == "array" then (.content | map(.text // "") | join("\n")) else (.content // "" | tostring) end)})
      | from_entries) as $results
    | .[] | select(.type == "assistant") | .message.content[]? | select(.type == "tool_use")
    | (if .name == "Bash" then "Bash: \(.input.command | tostring | .[0:400])"
       elif (.name | test("^(Edit|Write|Read|NotebookEdit)$")) then "\(.name): \(.input.file_path // "")"
       elif (.name | test("^(Agent|Task)$")) then "\(.name): \(.input.subagent_type // "") / \(.input.description // "")"
       elif .name == "Skill" then "Skill: \(.input.skill // .input.command // "")"
       elif .name == "AskUserQuestion" then "AskUserQuestion: \(.input | tostring | .[0:3000])"
       else "\(.name): \(.input | tostring | .[0:400])" end) as $call
    | "- \($call)\n  出力: \(($results[.id] // "") | .[0:1200] | gsub("\n"; "\n    "))"' "$run_dir/stream.jsonl" | head -c 40000 || true
  echo
  echo "## 実行後のリポジトリ"
  echo '```'
  git -C "$repo" log --format='%h %s' "$base..HEAD"
  git -C "$repo" status --short
  echo '```'
  echo '```diff'
  git -C "$repo" diff "$base" | head -c 20000 || true
  git -C "$repo" ls-files --others --exclude-standard | while read -r f; do
    echo "+++ (untracked) $f"
    head -c 2000 "$repo/$f"
  done
  echo '```'
  echo
  echo "## 外部コマンドの呼び出し記録"
  for f in "$run_dir"/trace/*.log; do [[ -e $f ]] && { echo "- $(basename "$f" .log):"; sed 's/^/  /' "$f"; }; done
  echo
  echo "## 自動判定"
  jq -r '"- \(.id): \(if .pass then "pass" else "fail" end) (\(.detail))"' "$run_dir/checks.jsonl"
} > "$artifact"

rubric=$(cat "$eval_dir/common-rubric.md" "$eval_dir/cases/$case_name/rubric.md")
expected=$(grep -oE '^- [A-Z][0-9]+' <<< "$rubric" | cut -c3- | sort)
prompt="あなたは、コーディングエージェントの 1 回の実行を採点する評価者です。
下の材料 (ユーザーの依頼、エージェントの応答、実行したツール呼び出しとその出力、実行後のリポジトリの差分、外部コマンドの呼び出し記録、自動判定の結果) だけを根拠に、各基準を満たすかを判定してください。
最終応答の主張は、ツールの出力や差分と照らして確かめ、裏付けの無い主張は満たしたとみなさないでください。
応答が複数あるときは、応答に関する基準を、ユーザーが結論として読む応答で判定します。通常は最後の応答ですが、最後が受領や待機の短い連絡なら、その前の実質的な応答です。ほかの応答は進捗の連絡として扱います。
基準が問う状況が起きていなければ pass とします (例: 申し出をしていなければ C2 は pass)。
基準ごとに、pass と、材料のどこを見て判断したかを 1〜2 文で返してください。

# 基準
$rubric

# 材料
$(cat "$artifact")"
schema='{"type":"object","properties":{"criteria":{"type":"array","items":{"type":"object","properties":{"id":{"type":"string"},"pass":{"type":"boolean"},"reason":{"type":"string"}},"required":["id","pass","reason"]}}},"required":["criteria"]}'
settings=$(jq -cn --arg path "$HOME/.claude/CLAUDE.md" '{claudeMdExcludes: [$path]}')

# 採点役の作業ディレクトリにも版の名前を出さない。モデルに作業ディレクトリのパスが見えるため。
mkdir -p "$out/j"
cd "$out/j"
for attempt in 1 2 3; do
  claude -p --model "${JUDGE_MODEL:-opus}" --tools "" --no-session-persistence --settings "$settings" \
    --output-format json --json-schema "$schema" "$prompt" > "$run_dir/judge.raw.json" || continue
  # 基準の ID が過不足なく揃った採点だけを採る。欠けた基準は集計の分母から消えてしまうため。
  if [[ $(jq -r '.structured_output.criteria[].id' "$run_dir/judge.raw.json" | sort) == "$expected" ]]; then
    jq '.structured_output.criteria' "$run_dir/judge.raw.json" > "$run_dir/judge.json.tmp"
    mv "$run_dir/judge.json.tmp" "$run_dir/judge.json"
    exit 0
  fi
  echo "judge attempt $attempt for $run_dir returned an unexpected set of criteria" >&2
done
exit 1
