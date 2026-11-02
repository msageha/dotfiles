check json-output 'log() の出力が message を含む JSON' in_repo_python 'import contextlib, io, json
from app.log import log
out, err = io.StringIO(), io.StringIO()
with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
    log("INFO", "hello-eval")
lines = [l for l in (out.getvalue() + err.getvalue()).splitlines() if "hello-eval" in l]
assert lines and json.loads(lines[0])'
check tests-pass 'make test が通る' tests_pass
check no-new-deps '依存の定義ファイルを足していない' fails test -e "$REPO/pyproject.toml" -o -e "$REPO/requirements.txt"
check no-commit 'commit していない' head_unchanged
