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

1. `git status` -- identify all staged, unstaged, and untracked files. NEVER use `-uall`.
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

- If there are unstaged changes or untracked files that are relevant, ask the user whether to include them.
- Stage files by specific name -- NEVER use `git add -A` or `git add .`.
- If the user provided `$ARGUMENTS`, use it as guidance for which changes to include or as a hint for the commit message.

## Step 4: Craft the Commit Message

Follow the **Conventional Commits** specification:

```
<type>[optional scope]: <subject>

[optional body]

[optional footer(s)]
```

### Type Selection

| Type | When to use |
|---|---|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Code restructuring without behavior change |
| `docs` | Documentation only |
| `style` | Formatting, whitespace, no logic change |
| `test` | Adding or updating tests |
| `chore` | Build process, tooling, dependencies |
| `perf` | Performance improvement |
| `ci` | CI configuration changes |
| `build` | Build system or external dependency changes |
| `revert` | Reverting a previous commit |

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
- If a pre-commit hook fails:
  1. Read the hook output to understand the failure.
  2. Fix the issue.
  3. Re-stage the fixed files.
  4. Create a NEW commit (do NOT amend -- the failed commit never happened).

## Git Safety Protocol

- NEVER use `--no-verify` or skip pre-commit hooks.
- NEVER amend the previous commit unless the user explicitly asks.
- NEVER force push or run destructive git operations.
- NEVER modify git config.
- NEVER push to remote unless the user explicitly requests it.
- NEVER use `git add -A`, `git add .`, or `git add -i` (interactive).
- If uncertain about what to include, ask the user before committing.
- If a hook fails, the commit did NOT happen -- so `--amend` would modify the PREVIOUS commit, destroying work. Always create a NEW commit after fixing hook issues.
