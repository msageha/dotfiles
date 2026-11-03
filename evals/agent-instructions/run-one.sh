#!/usr/bin/env bash
# 1 つのケースを 1 つの版の指示文で 1 回実行し、自動判定まで行う。
# 使い方: run-one.sh <case> <arm> <index>。OUT・TIMEOUT_SECONDS・CLAUDE_ARGS を環境変数で受ける。
set -euo pipefail

case_name=$1 arm=$2 index=$3
eval_dir=$(cd "$(dirname "$0")" && pwd)
run_dir="$OUT/runs/$case_name/$arm/$index"
[[ -e $run_dir/checks.jsonl ]] && exit 0

# 作業ディレクトリのパスにケース名・版の名前を出さない。エージェントが評価中だと気づくと振る舞いが変わりうるため。
id=$(printf '%s %s %s' "$case_name" "$arm" "$index" | shasum | cut -c1-12)
work="$OUT/w/$id"
rm -rf "$run_dir" "$work"
mkdir -p "$run_dir/before" "$run_dir/trace" "$work/bin"
printf '%s\n' "$work" > "$run_dir/workdir"

"$eval_dir/build-fixture.sh" "$work" > /dev/null
export REPO="$work/order-service" ORIGIN="$work/origin.git" RUN_DIR="$run_dir"
(cd "$REPO" && bash -e "$eval_dir/cases/$case_name/setup.sh")
if [[ -s $OUT/variants/$arm.md ]]; then
  cp "$OUT/variants/$arm.md" "$REPO/CLAUDE.md"
  mkdir -p "$REPO/.git/info"
  printf '%s\n' CLAUDE.md >> "$REPO/.git/info/exclude"
fi
cp "$eval_dir"/bin/* "$work/bin/"

# shellcheck source=lib.sh
source "$eval_dir/lib.sh"
git -C "$REPO" rev-parse HEAD > "$run_dir/before/head"
git -C "$ORIGIN" rev-parse main > "$run_dir/before/origin"
tree_state > "$run_dir/before/tree"

settings=$(jq -cn --arg path "$HOME/.claude/CLAUDE.md" '{claudeMdExcludes: [$path]}')
read -r -a extra_args <<< "${CLAUDE_ARGS:-}"
started=$(date +%s)
(
  cd "$REPO"
  # 親の Claude Code / Codex のセッションから引き継いだ変数 (effort・session ID・messaging の socket 等) を外し、
  # ユーザーが端末から起動したときと同じ条件にする。
  for name in $(compgen -e | grep -E '^(CLAUDECODE|CLAUDE_PID|CLAUDE_EFFORT|CLAUDE_PLUGIN_DATA|CLAUDE_CODE_(CHILD_SESSION|ENTRYPOINT|EXECPATH|MESSAGING_[A-Z_]+|SESSION_[A-Z_]+)|CODEX_COMPANION_[A-Z_]+)$' || true); do
    unset "$name"
  done
  # timeout と中断 (TERM / INT) では、claude の process group ごと止める (別の group に逃げたプロセスは後の stop_leftovers で止める)。
  # 並列の実行がポートと一時ディレクトリを取り合わないよう、fixture のサーバーが読む PORT は OS が空きを割り当てたものにし、
  # TMPDIR も実行ごとに分ける。
  port=$(python3 -I -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1])')
  mkdir -p "$work/tmp"
  PATH="$work/bin:$PATH" CLI_TRACE_DIR="$run_dir/trace" PORT=$port TMPDIR="$work/tmp" exec perl -e '
    my $seconds = shift;
    my $pid = fork // die "fork: $!";
    if ($pid == 0) { setpgrp(0, 0); exec @ARGV or die "exec: $!" }
    sub stop { kill "TERM", -$pid; sleep 5; kill "KILL", -$pid }
    $SIG{ALRM} = \&stop;
    $SIG{TERM} = $SIG{INT} = sub { stop(); exit 130 };
    alarm $seconds;
    waitpid $pid, 0;
    exit($? & 127 ? 128 + ($? & 127) : $? >> 8);
  ' "${TIMEOUT_SECONDS:-1200}" \
    claude -p --output-format stream-json --verbose --no-session-persistence \
    --settings "$settings" ${extra_args[@]+"${extra_args[@]}"} "$(cat "$eval_dir/cases/$case_name/prompt.txt")" \
    > "$run_dir/stream.jsonl" 2> "$run_dir/stderr.log"
) &
runner=$!
# 中断されても、claude を止めて後片付けまで行う。runner (perl) はバックグラウンドなので、端末の INT は届かず、trap から送る。
trap 'interrupted=1; kill -TERM "$runner" 2> /dev/null || true' INT TERM
wait "$runner" || status=$?
# trap で wait が抜けたときは、perl が claude を止め終えるのを待つ。
[[ -n ${interrupted:-} ]] && { wait "$runner" || status=$?; }
trap - INT TERM
echo "${status:-0}" > "$run_dir/exit"
echo $(($(date +%s) - started)) > "$run_dir/seconds"
stop_leftovers "$work" "$run_dir/trace"
remove_project_dir "$REPO"
# 中断した実行は判定せずに未完了のまま残し、-o で再開できるようにする。
[[ -n ${interrupted:-} ]] && exit 130

# shellcheck source=/dev/null
source "$eval_dir/cases/$case_name/check.sh" > "$run_dir/checks.jsonl.tmp"
mv "$run_dir/checks.jsonl.tmp" "$run_dir/checks.jsonl"
printf '%s %s %s: %s/%s checks, %ss\n' "$case_name" "$arm" "$index" \
  "$(jq -s 'map(select(.pass)) | length' "$run_dir/checks.jsonl")" \
  "$(jq -s 'length' "$run_dir/checks.jsonl")" "$(cat "$run_dir/seconds")"
