---
name: commit
description: "Creates a git commit for an explicit commit request such as 「commit して」「コミットして」 or 「commit して PR 作って」: checks that the changes are needed and correct, decides which changes belong to the requested work (untracked files and the user's own edits included, secrets and local artifacts excluded), stages them by path, and writes a message in the repository's style. Use only when the user has explicitly asked to commit; loading this skill does not by itself permit a commit, and the skill does not push."
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git ls-files:*), Bash(git add:*), Bash(git commit:*), Read, Grep, Glob
argument-hint: "[optional commit message hint]"
---

# Git Commit

Loading this skill is not permission to commit. Commit only when the user explicitly asked for it, and do only the git operations the request names (AGENTS.md `git` section). This skill does not push: when the request also asks to push or to update a PR, finish the commit here and continue with the pr skill.

Git safety:

- Use `--amend` only when the user asks. Do not change git config.
- Do not run destructive operations (`reset --hard`, `clean -f`, `stash drop`, `checkout -- .`).

The argument (`$ARGUMENTS`; if it is empty or not substituted, the request text) may say which changes to include or hint at the message.

## Step 1: List the changes without printing contents

Run in parallel:

1. `git status --short` -- staged, unstaged and untracked paths. Do not use `-uall`; an entry such as `?? dir/` means the whole directory is new, so list its files with `git ls-files --others --exclude-standard -- dir/` before deciding (`git status` keeps showing only `?? dir/`).
2. `git diff --stat` and `git diff --cached --stat` -- changed paths and sizes.
3. `git log --oneline -10` -- message style and language.

Classify each path (untracked ones included) before printing any diff, because a secret that reaches the output cannot be taken back. Secret files (as defined in the AGENTS.md `安全` section) stay out of the commit and their contents are not printed; check only whether they changed.

## Step 2: Review the remaining changes

- Read `git diff -- <paths>` and `git diff --cached -- <paths>` for the non-secret paths, and read untracked files directly. If a hunk contains something that looks like a credential, do not echo the value; leave the file out and report it.
- Check that each change is needed for the requested work and is correct before committing it. If the request was conditional (「問題なければ commit して」), report the judgment and its basis, then follow the stated branch.
- If there is nothing to commit, say so and stop.

## Step 3: Decide what belongs to the work

The whole work goes in, secrets and local artifacts stay out, and unrelated changes are left untouched and reported. In practice:

- The work includes changes staged or not, new untracked files and directories, the user's uncommitted hand edits, and tracked files even when they match `.gitignore` (`.gitignore` only affects untracked files, so `git add <path>` works for them). Include the user's edits and untracked files after checking their content in Step 2, without asking whose they are.
- Besides secrets and the artifacts below, leave out only what the user excluded by limiting the scope, and changes in paths unrelated to the work (e.g. another session's). Do not touch those; report them.
- Leave out, and report with the reason: agent runtime artifacts (e.g. `.claude/settings.local.json`, session or state files; not a `.claude/verify.sh` or project `.claude/settings.json` that belongs to the work), screenshots, local settings (`.idea/`, `.envrc`, `*.local.json`), OS or editor files (`.DS_Store`), build artifacts and large binaries, and unrelated lock-file or CI changes.

## Step 4: Stage

Stage by pathspec (`git add <path>...`). Do not use `git add -A`, `git add .` or `git commit -a`, which pick up unrelated changes, secrets and artifacts along with the work; `git add -i` is also out, because it waits for interactive input.

Commit the requested work as one commit unless the user asks to split it. When splitting, stage, write and commit each part in turn (Steps 4-6). `git commit` records the whole index, so before each commit compare `git diff --cached --name-only` with that commit's paths; if other paths are already staged, commit with `git commit --only -- <paths>` so they stay staged for their own commit.

## Step 5: Write the message

Match the format of the recent history from Step 1. If the history uses Conventional Commits (`<type>[scope]: <subject>`, optional body and footers), use the types and scopes it uses. Only when there is no history or its format cannot be determined, default to Conventional Commits:

- type: `feat` / `fix` / `refactor` / `docs` / `style` / `test` / `chore` / `perf` / `ci` / `build` / `revert`.
- scope: optional; the area of the codebase (e.g. `auth`, `api`, `ui`).
- subject: imperative mood, no trailing period, at most about 50 characters; in English, start lowercase.
- body: explain why, not what; wrap at 72 characters; omit it for trivial changes.
- footer: `BREAKING CHANGE:` when applicable, or `!` after the type/scope (e.g. `feat!:`).

In any format:

- Content: write for a later reader of the history. State the final intent of the change, not how the work went (what was tried and dropped). Leave out IDs and prefixes that only an agent or tool understands (task, worker or session IDs, `[<tool>]` prefixes).
- Language: the same as the recent history (Japanese history, Japanese message). If the history is mixed or unclear, use English.
- Do not add `Co-Authored-By` or other attribution trailers.

## Step 6: Commit and confirm

Pass the message with a quoted heredoc to avoid shell escaping problems:

```bash
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

- Run `git status` to confirm the commit.
- Confirm from the `git commit` output that the configured hooks (pre-commit etc.) actually ran. If the repository has a hook config (e.g. `.pre-commit-config.yaml`) but no hook output appeared, check whether the hook is installed in the directory `git rev-parse --git-path hooks` prints (it follows `core.hooksPath` and worktrees), and report the result instead of installing it.
- If a pre-commit hook fails, read its output, fix the cause, re-stage and create a new commit. Do not use `--amend` here: the failed commit did not happen, so `--amend` would rewrite the previous commit.
- Fix the cause, not the check: do not add files or config whose only purpose is to make a hook pass (e.g. an empty `__init__.py` to satisfy an import check). If the fix needs a project decision, stop and report it.
