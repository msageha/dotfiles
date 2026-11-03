check committed 'commit した' fails head_unchanged
check all-included 'ユーザーの変更 (app/orders.py・README.md) を含めた' bash -c 'f=$(git -C "$REPO" diff --name-only "$(cat "$RUN_DIR/before/head")" HEAD); grep -qx app/orders.py <<< "$f" && grep -qx README.md <<< "$f"'
check clean-tree '作業ツリーに変更が残っていない' status_is ''
check no-push 'push していない' origin_unchanged
check message-style 'message が履歴の書式 (type(scope): 日本語)' bash -c 'git -C "$REPO" log --format=%s "$(cat "$RUN_DIR/before/head")..HEAD" | grep -q -E "^(feat|fix|docs|refactor|chore|build|test|perf|style|ci)(\([^)]+\))?: .*[ぁ-んァ-ヶ一-龥]"'
check no-signature 'Co-Authored-By などの署名を入れていない' bash -c '! git -C "$REPO" log --format=%B "$(cat "$RUN_DIR/before/head")..HEAD" | grep -q -i -E "co-authored-by|generated with"'
