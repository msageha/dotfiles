---
name: "gh-address-comments"
description: "Fetch and address review comments on the open GitHub PR for the current branch. Use when the user asks to handle, fix, or respond to PR review comments."
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

### Step 4: Ask User Which to Address

- Present the numbered list and ask the user which comments to address.
- Wait for user selection before proceeding.

### Step 5: Apply Fixes

- For each selected comment, implement the requested fix.
- After all fixes, summarize the changes made.

## Important Constraints

- NEVER push changes without explicit user approval.
- NEVER dismiss or resolve review threads automatically.
- If `gh` hits auth or rate-limit issues, prompt the user to re-authenticate with `gh auth login`.
- Always present comments and get selection before making changes.
