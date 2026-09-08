---
name: "gh-fix-ci"
description: "GitHub Actions CI: diagnose and fix failing checks on PRs. Use when the user asks to debug or fix failing CI, PR checks, or GitHub Actions workflows."
allowed-tools: Bash, Read, Grep, Glob, Edit, Write
argument-hint: [optional PR number or URL]
---

# GitHub Actions CI Fix

Locate failing PR checks, fetch GitHub Actions logs, summarize failures, and -- when the request is a fix request -- fix the root cause and verify locally; push to the PR branch and confirm CI is green when the request includes pushing.

## Prerequisites

- `gh` CLI must be authenticated (`gh auth status` — repo + workflow scopes required).

## Workflow

### Step 1: Resolve the PR

- If `$ARGUMENTS` contains a PR number or URL, use that.
- Otherwise, detect the current branch PR: `gh pr view --json number,url`

### Step 2: Inspect Failing Checks

```bash
gh pr view <pr> --json mergeable,mergeStateStatus,headRefName,baseRefName
gh pr checks <pr> --json name,state,bucket,link,startedAt,completedAt,workflow
```

- `mergeable: CONFLICTING`: `pull_request`-triggered checks do not run while the PR conflicts. Resolve the conflict against the freshly fetched base first (AGENTS.md git rules), then continue.
- Checks still pending: `gh pr checks <pr> --watch` and wait; do not diagnose a partial run.
- For each `bucket: fail` check, take the run ID from `link` (`.../actions/runs/<run_id>/...`):
  ```bash
  gh run view <run_id> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
  gh run view <run_id> --log-failed
  ```

### Step 3: Scope Non-GitHub Actions Checks

- If `link` is not a GitHub Actions run (e.g., Buildkite), label it as **external** and only report the URL.
- Do not attempt to debug external CI providers.

### Step 4: Summarize Failures

For each failing check, present:
- Check name and run URL
- Concise log snippet showing the failure
- Missing logs noted explicitly

### Step 5: Decide Mode

- Question form ("原因分かる？", "どうして failed している？"): stop here and report the root cause and fix options. Do not change files.
- Fix form ("failed しているから修正して"): continue without a plan-approval round. Pause only when the fix needs a decision outside the PR's scope (workflow permissions, dependency version bumps, deleting tests).

### Step 6: Fix the Root Cause

- Fix what actually broke, within the PR's own scope; do not add files or config whose only purpose is to make the check pass.
- If an existing test is wrong relative to the intended behavior, fix the test. Add new tests only when the user asks.
- Pin a tool version only when the failure is caused by an upstream change you can cite (release notes / upstream PR); that pin is within the PR's scope, while any other dependency version change is a bump and pauses per Step 5. Do not mix unrelated pins or CI-config changes into the PR.
- Run the failing job's commands locally (or the project's equivalents, e.g. `mise run lint` / `mise run test`) and report the results.

### Step 7: Push and Recheck

- Commit and push to the PR branch only when the request includes it ("PR に積んで", "push して", "green にして"); otherwise stop at a commit-ready state and report the fix and the local verification. When pushing, update the PR body if the scope changed.
- `gh pr checks <pr> --watch --fail-fast`, then report green / failed with the check names. On failure, loop back to Step 2.
- Merge only when the user says so.

## Important Constraints

- Push only to the PR branch named in the request; never to the base branch.
