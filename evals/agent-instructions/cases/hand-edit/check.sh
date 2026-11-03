check kept-user-edit 'ユーザーの改名 (fetch_users) を書き戻していない' grep -q '^def fetch_users' "$REPO/app/users.py"
check callers-follow '呼び出し側に list_users が残っていない' bash -c '! grep -rq --include="*.py" list_users "$REPO/app" "$REPO/tests"'
check tests-pass 'make test が通る' tests_pass
check no-commit 'commit していない' head_unchanged
