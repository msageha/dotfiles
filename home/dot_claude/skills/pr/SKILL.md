---
name: pr
description: "Pull Request / Merge Request: analyze the current branch's changes and create a PR (GitHub) or MR (GitLab). Use when the user wants to open a PR/MR."
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [base-branch or title hint]
---

# Pull Request / Merge Request Workflow

You are a PR/MR assistant. Analyze all changes on the current branch and create a well-structured PR/MR.

## Step 1: Gather Context (run all in parallel)

Run the following commands simultaneously:

1. `git remote get-url origin` -- determine platform (GitHub vs GitLab).
2. `git status --short --branch` -- branch and working tree status. NEVER use `-uall`.
3. `git branch -vv --list $(git branch --show-current)` -- remote tracking status.
4. `git log --oneline <base>..HEAD` -- all commits that will be in the PR (use detected default branch as base).
5. `git diff --stat <base>..HEAD` -- file-level change summary.
6. `git diff` -- check for uncommitted changes.

## Step 2: Platform Detection

- URL contains `github.com` -> **GitHub** (use `gh` CLI)
- URL contains `gitlab.com` or `gitlab` -> **GitLab** (use `glab` CLI)
- Cannot determine -> ask the user.

## Step 3: Pre-flight Checks

- **Uncommitted changes**: If present, suggest committing first.
- **On main/master**: If so, propose creating a new branch.
- **Base branch**: Use `$ARGUMENTS` if provided, otherwise detect the default branch.
- **Existing PR/MR**: Check if one already exists for this branch.
  - GitHub: `gh pr list --head <branch>`
  - GitLab: `glab mr list --source-branch <branch>`
  - If exists, inform the user and ask whether to update or create new.

## Step 4: Analyze ALL Changes

- Review ALL commits from base to HEAD (not just the latest commit).
- Use `git diff <base>..HEAD` to understand the full scope of changes.
- Read modified files as needed to understand intent and impact.
- Identify: what changed, why it changed, and what risks exist.

## Step 5: Draft Title and Body

### Title
- English, imperative mood.
- Under 70 characters.
- Captures the essence of the change.

### Body

```markdown
## Summary
- 1-3 bullet points explaining the changes
- Include "why" this change is needed

## Changes
- Major changes grouped by logical area
- Not file-by-file, but by concept/feature

## Test plan
- [ ] Testing steps or verification checklist

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

## Step 6: Confirm with User

Present the following before creating:

1. **Platform**: GitHub (PR) / GitLab (MR)
2. **Base branch**: target branch name
3. **Title**: generated title
4. **Body**: generated body (full text)
5. **Commits**: list of included commits

Proceed only after user approval.

## Step 7: Create PR/MR

Push to remote if not already pushed:
```bash
git push -u origin <branch>
```

### GitHub
```bash
gh pr create --title "title" --body "$(cat <<'EOF'
body content
EOF
)"
```

### GitLab
```bash
glab mr create --title "title" --description "$(cat <<'EOF'
body content
EOF
)"
```

Return the PR/MR URL to the user.

## Safety Rules

- NEVER force push to main/master.
- NEVER use `--draft` unless the user explicitly requests it.
- NEVER assign reviewers or labels unless the user requests it.
- NEVER push if the user hasn't approved the PR content.
- GitLab-specific options (`--squash-before-merge`, `--remove-source-branch`) only when explicitly requested.
