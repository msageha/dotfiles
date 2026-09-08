---
name: commit
description: "Git commit: analyze staged and unstaged changes and create a well-structured commit message. Use when the user wants to commit their work."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [optional commit message hint]
---

# Git Commit Workflow

You are a git commit assistant. Follow these steps precisely to create a high-quality commit.

## Step 1: Gather Context (run all in parallel)

Run the following commands simultaneously:

1. `git status` -- identify all staged, unstaged, and untracked files. Do not use `-uall`.
2. `git diff --cached` -- view staged changes.
3. `git diff` -- view unstaged changes.
4. `git log --oneline -10` -- review recent commit style and conventions.

## Step 2: Analyze Changes

- Identify which files have meaningful changes that should be committed.
- Categorize the nature of changes: new feature, bug fix, refactor, docs, test, chore, perf, style, ci, build, etc.
- Flag any files that should NOT be committed:
  - Files containing secrets (`.env`, credentials, API keys, tokens)
  - Large binary files or build artifacts
  - OS/editor-generated files (`.DS_Store`, `Thumbs.db`, etc.)
  - Lock files that shouldn't be changed (unless intentional)
- If there are no changes to commit, inform the user and stop.

## Step 3: Stage Files

- Stage every change that belongs to the requested work, staged or not (new untracked files included); "commit して" means the whole work, not the staged subset.
- Leave out the files flagged in Step 2 and changes that clearly belong to something else: another session's work in a different directory, agent runtime artifacts (e.g. `.claude/settings.local.json`, session or state files -- not a `.claude/verify.sh` or project `.claude/settings.json` that belongs to the requested work), screenshots, local settings (`.idea/`, `.envrc`, `*.local.json`), unrelated lock or CI changes. Report what you left out and why.
- Ask only when you cannot tell whether a change belongs to the work.
- Stage by pathspec (`git add <path>`); never `git add -A`, `git add .`, `git add -i`, or `git commit -a`.
- If the user provided `$ARGUMENTS`, use it as guidance for which changes to include or as a hint for the commit message.

## Step 4: Craft the Commit Message

Follow the **Conventional Commits** specification (`<type>[scope]: <subject>` + optional body and footers). Types: `feat` / `fix` / `refactor` / `docs` / `style` / `test` / `chore` / `perf` / `ci` / `build` / `revert`. Match the type and scope conventions visible in `git log`.

### Rules

- **type**: Required. One of the types above.
- **scope**: Optional. Indicates the area of the codebase (e.g., `auth`, `api`, `ui`).
- **subject**: Imperative mood, lowercase, no period, max 50 characters.
- **body**: Explain the "why" not the "what". Wrap at 72 characters. Omit if change is trivial.
- **footer**: Include `BREAKING CHANGE:` if applicable. Use `!` after type/scope for breaking changes (e.g., `feat!:`).

### Language

- Write the commit message in the **same language as the recent commit history**. If recent commits are in Japanese, write in Japanese. If in English, write in English.
- If the commit history is mixed or unclear, default to English.

## Step 5: Create the Commit

Use a HEREDOC to pass the commit message to avoid shell escaping issues:

```bash
git commit -m "$(cat <<'EOF'
<commit message here>
EOF
)"
```

## Step 6: Verify

- Run `git status` after committing to confirm success.
- If a pre-commit hook fails: read the hook output, fix the cause, re-stage, and create a new commit. Never `--amend` here: the failed commit did not happen, so `--amend` would rewrite the previous commit.
- Fix the cause, not the check: do not add files or config whose only purpose is to make a hook pass (e.g. an empty `__init__.py` to satisfy an import check). If the fix needs a project decision, stop and report it.

## Git Safety Protocol

- No `--amend` unless the user asks. No changes to git config.
- No destructive operations (`reset --hard`, `clean -f`, `stash drop`, `checkout -- .`). No force push; the only exception is `--force-with-lease` onto a PR branch you just rebased under the AGENTS.md git rules.
- Do not add `Co-Authored-By` or other attribution trailers.
