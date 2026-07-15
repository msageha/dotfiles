---
name: "gh-fix-ci"
description: "GitHub Actions CI: diagnose and fix failing checks on PRs. Use when the user asks to debug or fix failing CI, PR checks, or GitHub Actions workflows."
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
argument-hint: [optional PR number or URL]
---

# GitHub Actions CI Fix

Locate failing PR checks, fetch GitHub Actions logs, summarize failures, propose a fix plan, and implement after explicit approval.

## Prerequisites

- `gh` CLI must be authenticated (`gh auth status` — repo + workflow scopes required).

## Workflow

### Step 1: Resolve the PR

- If `$ARGUMENTS` contains a PR number or URL, use that.
- Otherwise, detect the current branch PR: `gh pr view --json number,url`

### Step 2: Inspect Failing Checks

```bash
gh pr checks <pr> --json name,state,bucket,link,startedAt,completedAt,workflow
```

- If a field is rejected, rerun with available fields.
- For each failing check, extract the run ID from `detailsUrl`:
  ```bash
  gh run view <run_id> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
  gh run view <run_id> --log-failed
  ```
- If the run is still in progress, fetch job logs directly:
  ```bash
  gh api "/repos/{owner}/{repo}/actions/jobs/{job_id}/logs"
  ```

### Step 3: Scope Non-GitHub Actions Checks

- If `detailsUrl` is not a GitHub Actions run (e.g., Buildkite), label it as **external** and only report the URL.
- Do not attempt to debug external CI providers.

### Step 4: Summarize Failures

For each failing check, present:
- Check name and run URL
- Concise log snippet showing the failure
- Missing logs noted explicitly

### Step 5: Create a Fix Plan

- Draft a concise plan listing the changes needed to fix each failure.
- **Wait for user approval before making any changes.**

### Step 6: Implement After Approval

- Apply the approved fixes.
- Summarize diffs and suggest running relevant tests locally.

### Step 7: Recheck

- After changes, suggest re-running checks:
  ```bash
  gh pr checks <pr>
  ```

## Important Constraints

- NEVER push changes without explicit user approval.
- NEVER skip pre-commit hooks.
- Always present the plan and get approval before implementing fixes.
