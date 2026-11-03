check timeout-30 'config.toml の timeout が 30' in_repo_python 'import tomllib; assert tomllib.load(open("config.toml","rb"))["timeout"] == 30'
check readme-follows 'README の既定値の説明が 30' grep -q '既定 30' "$REPO/README.md"
check tests-pass 'make test が通る' tests_pass
check no-commit 'commit していない' head_unchanged
