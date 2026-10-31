---
name: "gh-fix-ci"
description: "GitHub Actions CI: diagnoses failing PR checks from their logs and, on a fix request, fixes the root cause (flaky, timeout and external failures included) and verifies locally. Use when the user asks why CI failed (「CI の原因分かる？」), asks to fix failing checks (「CI が failed しているから修正して」「green にして」), or asks to watch CI."
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob
argument-hint: "[optional PR number or URL]"
---

# GitHub Actions CI Fix

Locate failing PR checks, read their GitHub Actions logs and summarize the failures. On a fix request, fix the root cause and verify locally; push to the PR branch and confirm CI is green only when the request includes pushing.

## Prerequisites

- `gh` CLI authenticated with the `repo` scope (`gh auth status`). The `workflow` scope is needed only to push changes to files under `.github/workflows/`.

## Workflow

### Step 1: Decide the mode

Decide this before touching anything, and stay within it:

- Question (「原因分かる？」「どうして failed している？」): read-only. Report the root cause and fix options; do not change files, branches or runs.
- Fix (「failed しているから修正して」): fix the root cause and verify locally, without a plan-approval round. Pause only when the fix needs a decision outside the PR's scope (workflow permissions, dependency version bumps, deleting tests).
- Push is included only when the request says so (「PR に積んで」「push して」「green にして」); otherwise stop at a commit-ready state.
- Watch (「CI を監視して」): see Step 8.

### Step 2: Resolve the PR

- If the argument (`$ARGUMENTS`; if it is empty or not substituted, the request text) contains a PR number or URL, use that.
- Otherwise, detect the current branch's PR: `gh pr view --json number,url`.

### Step 3: Inspect the checks

```bash
gh pr view <pr> --json mergeable,mergeStateStatus,headRefName,baseRefName
gh pr checks <pr> --json name,state,bucket,link,startedAt,completedAt,workflow
```

- `mergeable: CONFLICTING`: `pull_request`-triggered checks do not run while the PR conflicts. In question mode, report the conflict. In fix mode, resolve it with the pr skill's conflict procedure (rebase onto the freshly fetched `origin/<base>`, keep the base's fixes, run lint / test). Without a push request, stop there with the branch rebased and verified locally; with one, push with `--force-with-lease` and continue. If the conflict needs a design decision, present the options and wait.
- Checks still pending: `gh pr checks <pr> --watch` and wait; do not diagnose a partial run.
- For each `bucket: fail` check, take the run ID from `link` (`.../actions/runs/<run_id>/...`):

  ```bash
  gh run view <run_id> --json name,workflowName,conclusion,status,url,event,headBranch,headSha
  gh run view <run_id> --log-failed
  ```

### Step 4: Scope non-GitHub Actions checks

If `link` is not a GitHub Actions run (e.g. Buildkite), label it as external and report only its URL; this skill does not debug external CI providers.

### Step 5: Summarize the failures

For each failing check, present the check name and run URL, a short log excerpt showing the failure, and any missing logs.

### Step 6: Find the cause and fix it (fix mode)

- Fix what actually broke, within the PR's own scope; do not add files or config whose only purpose is to make the check pass.
- Flaky tests, timeouts and failures that look external are not dismissed as transient. Identify the cause and where it comes from (this PR, an earlier commit or PR on the base, the runner, or an external service), using the run's `headSha`, the same job's history on the base (`gh run list --workflow <workflow> --branch <base>`) and the log. Fix it when the cause is in code. When it is outside the code, rerun with `gh run rerun <run_id> --failed` only if the request covers acting on the PR's CI (「green にして」「PR に積んで」, or a request to rerun); otherwise report the cause, its evidence and the proposed rerun, because a rerun also repeats jobs such as deploys and consumes CI resources.
- If an existing test is wrong relative to the intended behavior, fix the test. Add new tests only when the user asks.
- Pin a tool version only when the failure is caused by an upstream change you can cite (release notes / upstream PR); that pin is within the PR's scope, while any other dependency version change is a bump and pauses per Step 1. Do not mix unrelated pins or CI-config changes into the PR.
- Run the failing job's commands locally (or the project's equivalents, e.g. `mise run lint` / `mise run test`) and report the results.

### Step 7: Push and recheck (only when the request includes pushing)

- Commit and push to the PR branch, and update the PR body if the scope changed (pr skill).
- `gh pr checks <pr> --watch --fail-fast`, then report green / failed with the check names. On failure, go back to Step 3.
- Merge only when the user says so.

### Step 8: Watch CI or a job on request

When asked to watch CI or a job, keep checking it until it finishes (`gh pr checks <pr> --watch`, `gh run watch <run_id>`, or the job's own status and log commands at a regular interval). Report each failure or anomaly with its cause as soon as you find it, not only the final status.

## Constraints

- Push only to the PR's own branch, not to the base branch.
