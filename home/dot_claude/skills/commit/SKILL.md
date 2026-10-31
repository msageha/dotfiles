---
name: commit
description: "Creates a git commit for an explicit commit request such as 「commit して」「コミットして」 or 「commit して PR 作って」: checks that the changes are needed and correct, decides which changes belong to the requested work (untracked files and the user's own edits included, secrets and local artifacts excluded), stages them by path, and writes a message in the repository's style. Use only when the user has explicitly asked to commit; loading this skill does not by itself permit a commit, and the skill does not push."
allowed-tools: Bash(git:*), Read, Grep, Glob
argument-hint: "[optional commit message hint]"
---

# Git Commit

Loading this skill is not permission to commit. Commit only when the user explicitly asked for it, and do only the git operations the request names (AGENTS.md `git` section). This skill does not push: when the request also asks to push or to update a PR, finish the commit here and continue with the pr skill.

The argument (`$ARGUMENTS`; if it is empty or not substituted, the request text) may say which changes to include or hint at the message.

## Step 1: List the changes without printing contents

Run in parallel:

1. `git status --short` -- staged, unstaged and untracked paths. Do not use `-uall`; an entry such as `?? dir/` means the whole directory is new, so list its files with `git ls-files --others --exclude-standard -- dir/` before deciding (`git status` keeps showing only `?? dir/`).
2. `git diff --stat` and `git diff --cached --stat` -- changed paths and sizes.
3. `git log --oneline -10` -- message style and language.

Classify each path (untracked ones included) before printing any diff, because a secret that reaches the output cannot be taken back. Secret files (`.env*`, credentials, private keys, token files, `auth.json`, `.npmrc` / `.netrc` with tokens) stay out of the commit and their contents are not printed; check only whether they changed.

## Step 2: Review the remaining changes

- Read `git diff -- <paths>` and `git diff --cached -- <paths>` for the non-secret paths, and read untracked files directly. If a hunk contains something that looks like a credential, do not echo the value; leave the file out and report it.
- Check that each change is needed for the requested work and is correct before committing it. If the request was conditional (「問題なければ commit して」), report the judgment and its basis, then follow the stated branch.
- If there is nothing to commit, say so and stop.

## Step 3: Decide what belongs to the work

The AGENTS.md `git` section sets the rule: the whole work goes in, secrets and local artifacts stay out, unrelated changes are reported, and you ask only when a change's attribution is unclear. In practice:

- The work includes changes staged or not, new untracked files and directories, edits the user made by hand for the same work, and tracked files even when they match `.gitignore` (`.gitignore` only affects untracked files, so `git add <path>` works for them).
- Leave out, and report with the reason: another session's work in other paths, agent runtime artifacts (e.g. `.claude/settings.local.json`, session or state files; not a `.claude/verify.sh` or project `.claude/settings.json` that belongs to the work), screenshots, local settings (`.idea/`, `.envrc`, `*.local.json`), OS or editor files (`.DS_Store`), build artifacts and large binaries, and unrelated lock-file or CI changes.

## Step 4: Stage

Stage by pathspec (`git add <path>...`) as the AGENTS.md `git` section requires. `git add -i` is also out, because it waits for interactive input.

## Step 5: Write the message

Use Conventional Commits (`<type>[scope]: <subject>`, optional body and footers), matching the types and scopes visible in `git log`.

- type: `feat` / `fix` / `refactor` / `docs` / `style` / `test` / `chore` / `perf` / `ci` / `build` / `revert`.
- scope: optional; the area of the codebase (e.g. `auth`, `api`, `ui`).
- subject: imperative mood, no trailing period, at most about 50 characters; in English, start lowercase.
- body: explain why, not what; wrap at 72 characters; omit it for trivial changes.
- footer: `BREAKING CHANGE:` when applicable, or `!` after the type/scope (e.g. `feat!:`).
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
- If a pre-commit hook fails, read its output, fix the cause, re-stage and create a new commit. Do not use `--amend` here: the failed commit did not happen, so `--amend` would rewrite the previous commit.
- Fix the cause, not the check: do not add files or config whose only purpose is to make a hook pass (e.g. an empty `__init__.py` to satisfy an import check). If the fix needs a project decision, stop and report it.

## Git safety

- Use `--amend` only when the user asks. Do not change git config.
- Do not run destructive operations (`reset --hard`, `clean -f`, `stash drop`, `checkout -- .`).
