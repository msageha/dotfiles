---
paths:
  - "**/.github/workflows/**"
  - "**/action.yml"
  - "**/action.yaml"
---
# GitHub Actions

- Dependency Pinning: Pin actions and reusable workflows from other repositories to a full commit SHA, and note the human-readable version in a trailing comment (`uses: <owner>/<repo>@<40-char commit SHA> # <tag>`). When adding an action the repository already pins, reuse that pin; otherwise resolve the SHA from the action's newest version tag instead of copying one from memory or an example: take the tag from `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`, or from `gh api repos/<owner>/<repo>/tags --jq '.[].name'` when the latest release is not a version of the action itself (e.g. a release of a tool the action bundles), then run `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` (this also dereferences annotated tags). In a repository that has `.github/workflows/actions.lock`, also update it with `gh actions-lock <workflow-path>` (extension `github/gh-actions-lock`) after adding, removing or changing a `uses:` reference in a workflow listed there, because every action such a workflow uses must have a lockfile entry; without the path the command onboards every workflow in the repository.
- Least Privilege: Declare an explicit `permissions` block (workflow- or job-level) with the minimum scopes needed instead of relying on the default token permissions.
- Expression Injection: Never interpolate untrusted input (issue/PR titles and bodies, branch names, commit messages, review comments) into `run:` via `${{ }}`; pass it through an intermediate environment variable and quote it in the script.
- Privileged Triggers: With triggers that run with the base repository's token and secrets but can be fired by outside contributors (e.g. `pull_request_target`, `workflow_run`, `issue_comment`), do not check out or execute untrusted PR code; if unavoidable, isolate it in a separate unprivileged job.
- Secrets: Do not echo secrets or write them to artifacts; assume fork PRs run without secrets and design accordingly.
- Cloud Auth: Prefer OIDC federation over long-lived static credentials for cloud provider access.
- Timeouts: Set `timeout-minutes` on jobs to bound runaway or hung runs.
