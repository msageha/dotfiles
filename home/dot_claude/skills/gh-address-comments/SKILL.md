---
name: "gh-address-comments"
description: "GitHub PR review comments: fetch and address comments on the open PR for the current branch. Use when the user asks to handle, fix, or respond to PR review comments."
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
argument-hint: [optional PR number or URL]
---

# PR Comment Handler

Find the open PR for the current branch and address its review comments using `gh` CLI.

## Prerequisites

- `gh` CLI must be authenticated (`gh auth status` — repo + workflow scopes required).

## Workflow

### Step 1: Resolve the PR

- If `$ARGUMENTS` contains a PR number or URL, use that.
- Otherwise, detect the current branch PR: `gh pr view --json number,url`

### Step 2: Fetch All Comments

Retrieve all review threads and comments:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate
```

### Step 3: Present Comments to User

- Number all review threads and comments sequentially.
- For each, provide:
  - Comment number
  - Author and timestamp
  - File path and line range (if applicable)
  - Comment body (summarized if very long)
  - Short summary of what fix would be required
- Group by: pending review threads first, then general comments.
- If you believe a comment is mistaken, mark it when presenting the list and attach the evidence (file:line / test output) so the user can decide whether to select it.

### Step 4: Select Comments to Address

- If the request already delegates every comment (「全部対応して」「すべて適切に対応して」 or equivalent), skip the selection round and address all of them; do not apply a comment you judge mistaken -- report it with evidence instead.
- Otherwise present the numbered list, ask which comments to address, and wait for the selection before proceeding.

### Step 5: Apply Fixes

- For each selected comment, implement the requested fix. If while implementing you find the comment is wrong, stop for that item and report the evidence instead of silently skipping or applying it.
- A comment the user individually selected that asks for new tests counts as their instruction to add them; under a full delegation, report such requests instead of adding tests.
- Summarize changes per comment number; commit / push only on request (AGENTS.md git rules).

## Important Constraints

- Never resolve review threads or post replies unless the user asks.
- If `gh` hits auth or rate-limit issues, prompt the user to re-authenticate with `gh auth login`.
