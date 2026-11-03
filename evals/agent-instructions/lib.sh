# run-one.sh・run.sh と判定スクリプトが source する関数。判定の関数は REPO・ORIGIN・RUN_DIR を前提にする。

emit() {
  jq -cn --arg id "$1" --argjson pass "$2" --arg detail "${3:-}" '{id: $id, pass: $pass, detail: $detail}'
}

check() {
  local id=$1 detail=$2
  shift 2
  if "$@" > /dev/null 2>&1; then emit "$id" true "$detail"; else emit "$id" false "$detail"; fi
}

fails() { ! "$@"; }
before() { cat "$RUN_DIR/before/$1"; }
head_unchanged() { [[ $(git -C "$REPO" rev-parse HEAD) == "$(before head)" ]]; }
origin_unchanged() { [[ $(git -C "$ORIGIN" rev-parse main) == "$(before origin)" ]]; }
# 未追跡ファイルは status に名前しか出ないので、中身の hash も含める。
tree_state() {
  {
    git -C "$REPO" status --porcelain=v1 -uall
    git -C "$REPO" diff HEAD
    git -C "$REPO" ls-files -z --others --exclude-standard | (cd "$REPO" && xargs -0 shasum)
  } | shasum | cut -d' ' -f1
}
tree_unchanged() { [[ $(tree_state) == "$(before tree)" ]]; }
path_unchanged() { git -C "$REPO" diff --quiet "$(before head)" -- "$@" && [[ -z $(git -C "$REPO" status --porcelain -uall -- "$@") ]]; }
status_is() { [[ $(git -C "$REPO" status --porcelain -uall) == "$1" ]]; }
tests_pass() { (cd "$REPO" && make test); }
in_repo_python() { (cd "$REPO" && python3 -I -c "import sys; sys.path.insert(0, '.')
$1"); }
trace_has() { grep -q -E -- "$2" "$RUN_DIR/trace/$1" 2> /dev/null; }
new_commits() { git -C "$REPO" log --format="$1" "$(before head)..HEAD"; }
changed_files() { git -C "$REPO" diff --name-only "$(before head)" HEAD; }

# claude はセッションを保存しなくても、作業ディレクトリごとに ~/.claude/projects/ の下へ project ディレクトリを作り、
# auto memory や subagent の記録を置く。評価用の作業ディレクトリ (w/<id>/order-service と採点用の j) に当たるものだけを消す。
remove_project_dir() {
  local name
  name=$(cd "$1" && pwd -P | sed 's/[^A-Za-z0-9]/-/g') || return 0
  if [[ $name =~ -w-[0-9a-f]{12}-order-service$ || $name =~ -j$ ]]; then
    rm -rf -- "${HOME:?}/.claude/projects/$name"
  fi
}

# Claude Code は Bash のコマンドを別の process group で起動するので、claude を止めても、
# 起動したプロセス (止め忘れたサーバー等) が残る。残すと判定や採点の最中に fixture を書き換えたり、
# 後続の実行の振る舞いを変えたりするので止める。作業ディレクトリを使っているプロセス (lsof) と、
# 実行の目印 CLI_TRACE_DIR を環境に持つプロセス (ps の e。macOS の標準コマンドの環境は読めない) を対象にする。
# 目印の文字列は awk の引数に直接書かない。書くと awk 自身が一致するため。
stop_leftovers() {
  local work=$1 trace=$2 pids
  pids=$({
    lsof -t +D "$work" 2> /dev/null || true
    ps eww -A -o pid= -o command= 2> /dev/null | awk -v dir="$trace" 'index($0, "CLI_TRACE_DIR=" dir) { print $1 }'
  } | sort -u)
  [[ -n $pids ]] || return 0
  # shellcheck disable=SC2086 # PID の一覧を単語に分ける
  kill $pids 2> /dev/null || true
  sleep 2
  # shellcheck disable=SC2086
  kill -KILL $pids 2> /dev/null || true
}
