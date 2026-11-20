#!/usr/bin/env bash
# Claude Code の Stop hook。Claude が作業しているディレクトリから checkout の root まで遡り、最初に見つかった実行可能な
# .claude/verify.sh を、それがあるディレクトリで実行する。失敗したら exit 2 で Claude に結果を返し、ターンの終了を止める。
set -euo pipefail

input=$(cat)
# verify.sh の失敗で 1 回止めた後の Stop では実行しない
if printf '%s' "$input" | jq -e '.stop_hook_active == true' >/dev/null 2>&1; then
    exit 0
fi

# 起点は入力の cwd (Claude の cd と worktree への移動に追従する)。hook のプロセスの cwd と CLAUDE_PROJECT_DIR は
# 起動元の checkout を指しうるので、起点には使わない。cd -P で物理パスへ移り、symlink 経由の cwd からでも cd .. で toplevel に行き着く
cd -P "$(printf '%s' "$input" | jq -r '.cwd')" || exit 1
[ -n "${CLAUDE_PROJECT_DIR:-}" ] || exit 0
project=$(cd -P "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P) || exit 0

# toplevel を使うのは cwd が作業ツリーの中にあるときだけ。その外 (submodule の git dir の中・core.worktree が別の場所を指すリポジトリ)
# では toplevel が cwd の祖先でなく、遡ると checkout の外の verify.sh に行き着き、core.worktree で起動したリポジトリを指す
# ディレクトリも下の照合を通るため
if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = true ]; then
    top=$(git rev-parse --show-toplevel)
else
    top=$(pwd -P)
fi

# hook は sandbox の外で確認なしに動くので、cd した先の別のリポジトリ (clone した第三者のもの等) の verify.sh は実行しない。
# 実行するのは、cwd が session を起動したディレクトリの配下か、起動したリポジトリの git worktree list に toplevel が載る checkout
# (配下の外に作った worktree を含む) にあるときだけ (起動したディレクトリの配下にある別のリポジトリや依存物の verify.sh は止まらない)。
# - git の common dir の一致で判定しないのは、起動したリポジトリの .git を gitdir / commondir で指す .git を置いたディレクトリも一致するため。
# - 照合を awk の完全一致にするのは、grep -F だと改行を含む path が複数のパターンになるため。
# - 起動したディレクトリの名前・登録された worktree の path・継承した環境変数 (GIT_DIR 等) は、cd した先の中身からは変えられないので信頼し、
#   改行で終わる名前や改行を含む登録 path は扱わない。
case "$PWD/" in
    "$project"/*) ;;
    *)
        git -C "$project" worktree list --porcelain 2>/dev/null |
            T="worktree $top" awk '$0 == ENVIRON["T"] { f = 1 } END { exit !f }' || exit 0
        ;;
esac

# toplevel で止めるのは、checkout の中に作った worktree から親の checkout の verify.sh へ遡らないため。
# $PWD != / の条件は、toplevel の名前が改行で終わり $(…) がそれを落としたときにも止めるため
while [ ! -x .claude/verify.sh ] && [ ! . -ef "$top" ] && [ "$PWD" != / ]; do
    cd .. || exit 1
done
if [ -x .claude/verify.sh ]; then
    # stdout が空で stderr に no such file 等を含む exit 2 は、hook のスクリプトが無い場合として扱われて Claude に返らないので、
    # 失敗時は stdout に 1 行出す (Claude Code 2.1.325 の実装。公式 docs に記載は無い)
    bash .claude/verify.sh >&2 || {
        echo 'verify.sh failed'
        exit 2
    }
fi
