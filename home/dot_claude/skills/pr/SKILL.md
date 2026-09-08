---
name: pr
description: "Pull Request / Merge Request: analyze the current branch's changes and create a PR (GitHub) or MR (GitLab). Use when the user wants to open a PR/MR."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [base-branch or title hint]
---

# Pull Request / Merge Request Workflow

You are a PR/MR assistant. Analyze all changes on the current branch and create a well-structured PR/MR.

## Step 1: Gather Context

1. `git remote get-url origin` -- determine platform (GitHub vs GitLab, see Step 2).
2. Base branch: `$ARGUMENTS` if it names a branch; otherwise treat it as a title hint for Step 5 and use the repo default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`; GitLab: `glab repo view -F json --jq .default_branch`). Then `git fetch origin <base>`.
3. Run in parallel:
   - `git status --short --branch` -- branch and working tree status. Do not use `-uall`.
   - `git branch -vv --list $(git branch --show-current)` -- remote tracking status.
   - `git log --oneline origin/<base>..HEAD` -- all commits that will be in the PR.
   - `git diff --stat origin/<base>..HEAD` -- file-level change summary.
   - `git diff` -- check for uncommitted changes.
   - `gh pr list --head <branch> --json number,url` (GitLab: `glab mr list --source-branch <branch>`) -- existing PR/MR for this branch.

## Step 2: Platform Detection

- URL contains `github.com` -> **GitHub** (use `gh` CLI)
- URL contains `gitlab.com` or `gitlab` -> **GitLab** (use `glab` CLI)
- Cannot determine -> ask the user.

## Step 3: Pre-flight Checks

- **On the base branch (main/master)**: before committing anything, move onto a work branch with `git checkout -b <name>` at the current HEAD (uncommitted changes carry over); rebase onto `origin/<base>` if the base has moved. If local `<base>` already had commits beyond `origin/<base>`, they are now on the work branch: when they all belong to this work, restore the local base with `git branch -f <base> origin/<base>`; otherwise ask which ones belong before continuing. Never push to the base branch.
- **Uncommitted changes**: if the request included committing ("commit して PR 作って"), run the commit workflow first; otherwise stop and report -- committing needs its own instruction.
- **Existing PR/MR for this branch**: push the new commits to it and update its title/body to match the full diff (Step 5). Do not open a second PR.

## Step 4: Analyze ALL Changes

- Review ALL commits from base to HEAD (not just the latest commit).
- Use `git diff origin/<base>..HEAD` to understand the full scope of changes.
- Read modified files as needed to understand intent and impact.
- Identify: what changed, why it changed, and what risks exist.

## Step 5: Draft Title and Body

### Title
- Imperative mood, under 70 characters, captures the essence of the change.
- Same language rule as commits: follow the language of recent PRs/commits in this repo; default to English.

### Body

If the repository has a PR template (`.github/PULL_REQUEST_TEMPLATE.md` or `.github/PULL_REQUEST_TEMPLATE/`), fill that structure. Otherwise:

```markdown
## Summary
- 1-3 bullet points: what changed and why

## Changes
- Major changes grouped by concept/feature, not file-by-file

## Verification
- Commands actually run and their results (test counts, lint, manual checks). State explicitly what was not verified.

## Follow-ups
- Out-of-scope findings and residual risks (omit if none)
```

Do not append attribution footers ("Generated with ...", `Co-Authored-By`).

## Step 6: Create PR/MR

Push and open the PR without a confirmation round; ask only if the base branch cannot be determined or the diff mixes clearly unrelated work.

Push to remote if not already pushed:
```bash
git push -u origin <branch>
```

### GitHub
```bash
gh pr create --base <base> --title "title" --body "$(cat <<'EOF'
body content
EOF
)"
```

### GitLab
```bash
glab mr create --target-branch <base> --title "title" --description "$(cat <<'EOF'
body content
EOF
)"
```

## Step 7: Wait for CI and Report

- GitHub: `gh pr checks <pr> --watch --fail-fast`, then `gh pr view <pr> --json mergeable,mergeStateStatus`. GitLab: `glab ci status --live`.
- Report the PR/MR URL, title, included commits, CI result (green / failed with failing check names) and mergeable state.
- If a check failed, diagnose and fix it before reporting completion.

## Safety Rules

- Use `--draft`, reviewers, labels, and GitLab merge options (`--squash-before-merge`, `--remove-source-branch`) only when the user requests them.
