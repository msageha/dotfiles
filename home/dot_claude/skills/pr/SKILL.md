---
name: pr
description: "Runs the pull request / merge request workflow when the user explicitly asks (「PR 作って」「PR に積んで」「push して」「main に積んで」「conflict を解消して」「main を取り込んで」): branches from the latest base, pushes (straight to the base branch only when asked), opens or updates a GitHub PR / GitLab MR with a title and body written for the whole diff, brings the base into a PR branch, and waits for CI and the mergeable state. Loading this skill does not by itself permit a push or a PR."
allowed-tools: Bash(git remote:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git ls-files:*), Bash(git ls-tree:*), Bash(git switch:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git rebase:*), Bash(git merge:*), Bash(git worktree:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh repo view:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(gh pr edit:*), Bash(gh pr checks:*), Bash(gh run list:*), Bash(gh run watch:*), Bash(glab repo view:*), Bash(glab mr list:*), Bash(glab mr create:*), Bash(glab mr update:*), Bash(glab ci status:*), Read, Grep, Glob
argument-hint: "[base-branch or title hint]"
---

# Pull Request / Merge Request Workflow

Loading this skill is not permission to push or to open a PR. Do only the operations the user explicitly asked for (AGENTS.md `git` section); Step 1 maps each request phrase to its end point. Work in this order: decide what the request allows, then decide the target (base, branch, PR), then operate.

## Safety rules

- Use `--draft`, reviewers, labels and GitLab merge options (`--squash-before-merge`, `--remove-source-branch`) only when the user requests them.
- Push to the base branch only in the 「main に積んで」 mode.
- Do not use `--force`. Force-push only with `--force-with-lease`, and only after a rebase that Step 8 allows (including the stacked-PR retarget in Step 7) or when the user explicitly asks for a force push.

## Step 1: Decide the mode and its end point

- 「PR 作って」「commit して PR 作って」「〜を直して PR 作って」: a new PR, ending when the PR is open and its CI and mergeable state are checked. It does not include merging, and the PR is not a draft.
- 「PR に積んで」 on a branch with an open PR: commit and push to that PR's branch and rewrite its title and body. If that PR is unrelated to this change (its purpose differs, or the user has just asked for a new PR), do not mix the change in: open a new PR from the latest base and report its URL. When it is unclear whether the PR is related, open a new PR, because closing a PR is easier to undo than commits pushed onto an existing one. If the branch has no open PR, push the branch and ask whether to open one.
- 「push して」 alone: push the current branch to its upstream and, if it has an open PR, rewrite that PR's title and body. If the open PR is unrelated to this change, stop and report instead of pushing; a bare push request does not permit opening a new PR. On the base branch, stop and report as well, since pushing to the base branch is the 「main に積んで」 mode.
- A PR whose base the user names as an existing PR or branch (「この PR 向けに修正 PR を作って」「#N に対する PR として出して」「`<branch>` に対しての PR」): a stacked PR. Branch from that PR's branch, open the PR against it, and do not merge it. Do not infer a stacked PR from words such as 「修正 PR」 alone, which often mean a PR against the base branch; if the change cannot be built on the latest base because it depends on an unmerged PR, ask which base to use.
- 「main に積んで」「main に push して」: commit on the base branch and push to it directly, without a work branch or PR. This is the only mode that pushes to the base branch.
- 「conflict を解消して」「main を取り込んで」: Step 8 (by default, merge `origin/<base>` into the PR branch), then push to the PR branch.
- Committing is part of the request when it says to commit, uses 「PR に積んで」 or 「main に積んで」 (both mean commit + push), or delegates the work through to a PR (「〜して PR 作って」). Otherwise, if the work has uncommitted changes, stop and report; committing needs its own instruction.
- 「self merge して」「(問題なければ) merge して」 for an open PR: merge mode. Confirm CI is green and the PR is mergeable (Step 9), complete any check the condition names, then merge with the repository's usual method (`gh pr merge <pr>`; GitLab: `glab mr merge <mr>`) and report the merge commit and the base branch's CI. If a check failed or the PR conflicts, do not merge; report instead. 「main を merge して」 means bringing the base into the PR branch (Step 8), not merging the PR.
- Merge the PR itself only in merge mode.
- Follow the route the user specified (a direct push to the base branch, keeping the existing branch name, a non-draft PR, a permitted force push) instead of replacing it with a procedure you consider safer; the user chose it knowing the repository's practice. If something on that route blocks it, such as a hook rejecting the commit or push, show how to clear that obstacle rather than recommending another route.

## Step 2: Gather context

1. `git remote get-url origin` -- the platform: `github.com` means GitHub (`gh`), a URL containing `gitlab` means GitLab (`glab`). If neither, ask.
2. The base branch: the argument (`$ARGUMENTS`; if it is empty or not substituted, the request text) if it names a branch; otherwise treat the argument as a title hint and use the repository default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`; GitLab: `glab repo view -F json --jq .default_branch`). For a stacked PR, the base is the parent PR's branch. Then `git fetch origin <base>`.
3. Run in parallel:
   - `git status --short --branch` -- branch, its remote tracking and the working tree. Do not use `-uall`.
   - `git log --oneline origin/<base>..HEAD` -- the commits in the PR.
   - `git diff --stat origin/<base>...HEAD` -- the changed files. Use three dots (diff from the merge base) so that commits added to the base after the branch point do not appear as part of the PR.
   - `gh pr list --head <branch> --json number,url,title,state` (GitLab: `glab mr list --source-branch <branch>`) -- an existing PR / MR for this branch.

## Step 3: Choose the branch

- Where to work: choose as in AGENTS.md `git` section, and in a worktree do the remaining steps, Step 8 included. When moving to a worktree while this checkout already holds this work's uncommitted changes, copy only this work's hunks there (untracked files included; if a file mixes them with other work's changes that cannot be separated, report and stop), and leave the originals in place and report them. A branch checked out in another worktree cannot be checked out again: open it detached (`git worktree add --detach <path> <branch>`), and make every push in the later steps `git push <head-remote> HEAD:refs/heads/<branch>` (the fork's remote for a PR from a fork; add `--force-with-lease` after a rebase).
- New PR: `git fetch origin <base> && git switch -c <name> origin/<base>`. Do not branch from the current branch or from a reference PR's branch. Uncommitted changes carry over; if git refuses because a modified file also differs between HEAD and `origin/<base>`, record the current commit with `git rev-parse HEAD`, create the branch at HEAD (`git switch -c <name>`), commit, and move only the new commits onto the base with `git rebase --onto origin/<base> <recorded-commit>`, so commits of the branch you started from (for example another PR's) stay out of this PR.
- The current branch already holds this work (its own commits, no PR yet): use it as is.
- Work already committed on the local base but not on `origin/<base>`: keep it with `git switch -c <name>` at HEAD and rebase onto `origin/<base>`. If all those commits belong to this work, reset the local base with `git branch -f <base> origin/<base>`; otherwise ask which ones belong before continuing.
- Continuing an existing PR: commit on its branch directly (`git switch <branch>` first if needed; in a worktree, open it as above).
- Stacked PR: `git switch -c <name> origin/<parent-branch>`.
- 「main に積んで」: work on the base branch (switch to it if needed). After committing, `git fetch origin <base>`; if `git merge-base --is-ancestor origin/<base> HEAD` succeeds, push with `git push origin <base>`, otherwise rebase onto `origin/<base>` first so the push is a fast-forward.

## Step 4: Commit (when the request includes it)

Follow the commit skill (`../commit/SKILL.md`; read it first if it is not loaded). The steps this flow relies on: decide the secret paths before printing any diff, commit this work's changes (untracked files included) by pathspec and nothing else, write the message in the history's style without attribution trailers, and when a hook fails, fix the cause and make a new commit instead of `--amend`.

## Step 5: Check the scope and read the whole change

- Review every commit from the base to HEAD and the full diff `git diff origin/<base>...HEAD`. Before printing the diff, list the paths (`--name-only`) and exclude secret files from the printed output (`-- . ':(exclude)<path>'`). If a commit on the branch contains a secret file, do not push; report it.
- Read the modified files as needed and identify the purpose, what changed and why, the risks, and any breaking change.
- Give the PR one purpose and keep it to changes that serve it, so that it can be reviewed, merged and reverted as one unit. Out-of-scope changes (unrelated fixes, a new feature, a different responsibility, edits to instruction files the task did not call for) stay out, and so do changes of a different nature that can be reviewed, merged and reverted independently of the purpose (a rename or restructuring the behavior change does not depend on, formatting unification beside a design change): if the user asked for them as a separate PR, put them on a new branch from the latest `origin/<base>`; otherwise report them as separate-PR candidates. Changes the purpose needs stay in this PR even when they touch another layer or look loosely related (see the next bullets on shared layers); do not split them by how related they look. Restore to the base state any diff that no longer serves the purpose, such as leftovers of an abandoned approach.
- List the problems this PR leaves open (unresolved review points, known gaps) under Follow-ups instead of fixing them in this flow, unless the request delegates that work (「残りも対応して PR に積んで」), in which case fix the ones the PR's purpose needs. File them as GitHub issues, one issue each, only when the user asks, and do not close PRs or issues the user did not ask to close.
- When work is split into several PRs, each PR stands alone: it includes the supporting changes (shared layers, config) its purpose needs, and its body names any PR it depends on.

## Step 6: Write the title and body

Write them for the whole diff, not the latest commit, and rewrite both on every later push to the same PR.

Title: imperative mood, under 70 characters, in the language of the repository's recent PRs and commits (default English).

Body: look for a template on the base branch first:

```bash
git ls-tree -r --name-only origin/<base> | grep -iE '^((docs|\.github)/)?pull_request_template(\.md|/)|^\.gitlab/merge_request_templates/'
```

GitHub uses `pull_request_template.md` in the root, `docs/` or `.github/`, or several templates in a `PULL_REQUEST_TEMPLATE/` directory there; GitLab uses `.gitlab/merge_request_templates/`. If one exists, fill its structure (with several, the one that fits the change). Otherwise:

```markdown
## Purpose
- What this PR achieves, and the problem in the current state (or in the previous PR) that it solves

## Changes
- Grouped by concept, not by file: what changed, and where and how it takes effect

## Reviewer requests
- Points that need the reviewer's judgment (omit if none)

## Testing
- How the change was tested, as far as a reviewer needs it to trust the change, in a line or two (omit if nothing beyond CI)

## Follow-ups
- Out-of-scope findings and residual risks (omit if none)
```

- Write for a reviewer who has not seen this conversation (AGENTS.md `成果物と報告`): lead with what the PR achieves, and make clear what this PR does on its own.
- Leave out the history of the work (abandoned attempts, closed predecessor PRs), logs and command transcripts, and third-person references to the author or the user (e.g. "<user>'s concern is ..."); write as the author.
- When a mechanical bulk replacement also contains substantive edits, list each substantive edit (before → after) under "Reviewer requests", apart from the mechanical part, and ask the reviewer to confirm them.
- Do not append attribution footers ("Generated with ...", `Co-Authored-By`).

## Step 7: Push and open or update the PR

Push and open the PR without a confirmation round; ask only if the base branch cannot be determined or the diff mixes clearly unrelated work.

```bash
git push -u origin <branch>
```

New PR, not a draft unless the user asked for one. GitHub:

```bash
gh pr create --base <base> --title "title" --body "$(cat <<'EOF'
body content
EOF
)"
```

GitLab:

```bash
glab mr create --target-branch <base> --title "title" --description "$(cat <<'EOF'
body content
EOF
)"
```

Existing PR: after the push, rewrite the title and body with `gh pr edit <pr> --title ... --body ...` (GitLab: `glab mr update <mr> --title ... --description ...`).

Stacked PR whose parent PR has been merged: retarget it to the base branch (`gh pr edit <pr> --base <base>`) if the host has not done so, rebase only this PR's commits with `git rebase --onto origin/<base> <last-parent-commit>`, and push with `--force-with-lease`, so the diff contains only this PR's changes.

## Step 8: Resolve conflicts and bring in the base

- Default: `git fetch origin <base>` and merge `origin/<base>` into the PR branch, then push normally. A merge keeps the commits reviewers have already seen, while a rebase changes their SHAs and needs a force push, which makes it hard for reviewers to see what changed since their last review.
- Rebase onto `origin/<base>` instead only when it is needed: the user asks for a rebase, no review has started on the branch yet, or the history has to be rewritten, as when retargeting a stacked PR (Step 7).
- If the checkout holds uncommitted changes that do not belong to this work (for example, another session shares it), do not stash, `--autostash`, reset or check them out (AGENTS.md `git` section): do this step in a worktree as in Step 3, start it from the local branch (the remote branch when there is none), bring in the PR head's remote branch too if it has commits the local branch lacks, and push with `--force-with-lease` after a rebase. After the checks below, report how the shared checkout's branch now relates to its remote (behind or diverged); its HEAD and uncommitted changes stay untouched.
- Keep every fix that landed on the base, and do not bring back content the base changed or removed; check each conflicted file against `git log origin/<base> -- <file>`. Keep the design intent of both sides: do not overwrite values the branch changed on purpose or settings specific to it (such as a release branch's pins) with the base's, and also update code the new base now requires (renamed APIs, moved files) even where git reported no conflict.
- A conflict that needs a design decision: present the options with a recommendation and wait.
- Run the existing lint / test (skip the separate run when the repository's push hook runs the same checks), then push: plain `git push` after a merge, `git push --force-with-lease` after a rebase.
- After the push, confirm that the host reports the PR as mergeable and that `git diff origin/<base>...HEAD` contains only this PR's changes.

## Step 9: Wait for CI and report

- GitHub: `gh pr checks <pr> --watch --fail-fast`, then `gh pr view <pr> --json mergeable,mergeStateStatus`. Checks can take a moment to appear after a push, so if none are reported, check again before concluding there is no CI; `mergeable: UNKNOWN` means GitHub is still computing it, so query again. GitLab: `glab ci status --live`. For 「main に積んで」, watch the base branch's runs (`gh run list --branch <base> --limit 5`, then `gh run watch <run_id>`).
- If a check fails or the PR conflicts, find the root cause, fix it and push again. Do not report completion before CI has finished.
- Report the PR / MR URL, title, included commits, CI result (green, or failed with the failing check names), mergeable state and conflicts, whether the change is breaking, and anything left out of the PR with the reason.
