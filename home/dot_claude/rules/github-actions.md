---
paths:
  - "**/.github/workflows/**"
  - "**/action.yml"
  - "**/action.yaml"
---
# GitHub Actions

- Dependency Pinning: Pin third-party actions to a full commit SHA, and note the human-readable version in a trailing comment (e.g. `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4.2.2`).
- Least Privilege: Declare an explicit `permissions` block (workflow- or job-level) with the minimum scopes needed; never rely on the default token permissions.
- Expression Injection: Never interpolate untrusted input (issue/PR titles and bodies, branch names, commit messages, review comments) into `run:` via `${{ }}`; pass it through an intermediate environment variable and quote it in the script.
- Privileged Triggers: With `pull_request_target` / `workflow_run`, do not check out or execute untrusted PR code; if unavoidable, isolate it in a separate unprivileged job.
- Secrets: Do not echo secrets or write them to artifacts; assume fork PRs run without secrets and design accordingly.
- Cloud Auth: Prefer OIDC federation over long-lived static credentials for cloud provider access.
- Timeouts: Set `timeout-minutes` on jobs to bound runaway or hung runs.
