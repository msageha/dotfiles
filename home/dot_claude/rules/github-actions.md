---
paths:
  - "**/.github/workflows/**"
  - "**/action.yml"
  - "**/action.yaml"
---
# GitHub Actions

- Dependency Pinning: Pin third-party actions to a full commit SHA, and note the human-readable version in a trailing comment (`uses: <owner>/<repo>@<40-char commit SHA> # <tag>`). Resolve the SHA from the action's newest version tag instead of copying one from memory or an example: take the tag from `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, or from `gh api repos/<owner>/<repo>/tags --jq '.[].name'` when the latest release is not a version of the action itself (e.g. github/codeql-action publishes CodeQL bundle releases), then run `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` (this also dereferences annotated tags).
- Least Privilege: Declare an explicit `permissions` block (workflow- or job-level) with the minimum scopes needed; never rely on the default token permissions.
- Expression Injection: Never interpolate untrusted input (issue/PR titles and bodies, branch names, commit messages, review comments) into `run:` via `${{ }}`; pass it through an intermediate environment variable and quote it in the script.
- Privileged Triggers: With `pull_request_target` / `workflow_run`, do not check out or execute untrusted PR code; if unavoidable, isolate it in a separate unprivileged job.
- Secrets: Do not echo secrets or write them to artifacts; assume fork PRs run without secrets and design accordingly.
- Cloud Auth: Prefer OIDC federation over long-lived static credentials for cloud provider access.
- Timeouts: Set `timeout-minutes` on jobs to bound runaway or hung runs.
