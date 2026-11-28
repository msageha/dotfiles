---
name: pr
description: "Runs the GitHub PR / GitLab MR workflow when the user explicitly asks (「PR 作って」「PR に積んで」「push して」「main に積んで」「conflict を解消して」「main を取り込んで」「merge して」): pushing (to the base branch directly only when asked), opening or updating a PR, bringing the base into a PR branch, and merging a PR. Loading this skill does not by itself permit any of them."
allowed-tools: Bash(git remote:*), Bash(git fetch:*), Bash(git status:*), Bash(git log:*), Bash(git diff:*), Bash(git ls-files:*), Bash(git ls-tree:*), Bash(git switch:*), Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git rebase:*), Bash(git merge:*), Bash(git worktree:*), Bash(git add:*), Bash(git commit:*), Bash(git push:*), Bash(gh repo view:*), Bash(gh pr list:*), Bash(gh pr view:*), Bash(gh pr create:*), Bash(gh pr edit:*), Bash(gh pr checks:*), Bash(gh run list:*), Bash(gh run view:*), Bash(gh run watch:*), Bash(glab repo view:*), Bash(glab mr list:*), Bash(glab mr view:*), Bash(glab mr create:*), Bash(glab mr update:*), Bash(glab ci status:*), Read, Grep, Glob
argument-hint: "[base-branch or title hint]"
---

# Pull Request / Merge Request Workflow

Loading this skill is not permission to push, to open a PR or to merge one. Do only the operations the AGENTS.md `git` section allows; Step 1 maps each request phrase to its end point. Work in this order: decide what the request allows, then decide the target (base, branch, PR), then operate.

## Safety rules

- Use `--draft`, reviewers, labels and GitLab merge options (`--squash-before-merge`, `--remove-source-branch`) only when the user requests them.
- Push to the base branch only in the 「main に積んで」 mode.
- Do not use `--force`. Force-push only after a rebase that Step 8 allows (including the stacked-PR retarget in Step 7) or when the user explicitly asks for a force push.
- Force-push with `--force-with-lease=<branch>:<sha>`, where `<sha>` is the remote head you confirmed may be overwritten; after a rebase, it is the remote head you brought into the branch before the rebase. A bare `--force-with-lease` compares with the remote-tracking ref, which a background fetch may have moved. If the lease is rejected, fetch and bring in or report the new remote commits instead of retrying with the new SHA.

## Step 1: Decide the mode and its end point

- 「PR 作って」「commit して PR 作って」「〜を直して PR 作って」: a new PR, ending when the PR is open and its CI and mergeable state are checked. It does not include merging.
- 「PR に積んで」 on a branch with an open PR: commit and push to that PR's branch and rewrite its title and body. If that PR is unrelated to this change (its purpose differs, or the user has just asked for a new PR), do not mix the change in: open a new PR from the latest base and report its URL. When it is unclear whether the PR is related, open a new PR, because closing a PR is easier to undo than commits pushed onto an existing one. If the branch has no open PR, push the branch and ask whether to open one.
- 「push して」 alone: push the current branch to its open PR's head branch (for a PR from a fork, on the fork's remote: `git push <head-remote> HEAD:refs/heads/<branch>`) and rewrite that PR's title and body; without an open PR, push it to its upstream when that is a branch of the same name, and otherwise (it has no upstream, or its upstream is still the branch it was created from) to the branch of the same name on `origin` (Step 7). If the open PR is unrelated to this change, stop and report instead of pushing; a bare push request does not permit opening a new PR. On the base branch, stop and report as well, since pushing to the base branch is the 「main に積んで」 mode.
- A PR whose base the user names as an existing PR or branch (「この PR 向けに修正 PR を作って」「#N に対する PR として出して」「`<branch>` に対しての PR」): a stacked PR. Branch from that PR's branch, open the PR against it, and do not merge it. Do not infer a stacked PR from words such as 「修正 PR」 alone, which often mean a PR against the base branch; if the change cannot be built on the latest base because it depends on an unmerged PR, ask which base to use.
- 「main に積んで」「main に push して」: commit on the base branch and push to it directly, without a work branch or PR.
- 「conflict を解消して」「main を取り込んで」: Step 8 (by default, merge `origin/<base>` into the PR branch), then push to the PR branch. Committing is part of this request for the merge or the conflict resolution and for what Step 9 fixes after that push, not for the work's other uncommitted changes.
- Committing is part of the request when it says to commit, uses 「PR に積んで」, 「main に積んで」 or 「main に push して」 (all mean commit + push), delegates the work through to a PR (「〜して PR 作って」, or a standing procedure that the AGENTS.md `git` section accepts), or asks to fix the PR's CI and push the fix (「green にして」, 「直して push して」). Otherwise, if the work has uncommitted changes, stop and report; committing needs its own instruction. When committing is part of the request, it also covers committing and pushing the fix for a check that fails, or a conflict that appears, after the push (Step 9).
- 「self merge して」「(問題なければ) merge して」 for an open PR: merge mode, the only mode that merges the PR. If a check failed, the PR conflicts or the condition does not hold, do not merge; report instead.
  1. Record the PR's head SHA, and confirm that the checks for it are green and the PR is mergeable (Step 9). GitHub: `gh pr view <pr> --json headRefOid,statusCheckRollup,mergeable` gives all three in one response. GitLab: `glab mr view <mr> -F json` gives the MR's `sha` and its latest pipeline; a merged results pipeline tests a merge commit, so its SHA differs from the MR's `sha`.
  2. Judge any condition the request states and report its basis (for a condition on the PR's quality such as 「問題なければ」, use the improve-pr skill's evaluation mode where available).
  3. Merge that SHA with the repository's usual method, read from how recent PRs landed on the base: `gh pr merge <pr> --match-head-commit <sha>` with `--squash`, `--merge` or `--rebase` (`gh` requires one when it cannot prompt); GitLab: `glab mr merge <mr> --sha <sha>`. If the head has moved, start again from recording the head SHA.
  4. Confirm that the PR is merged (a merge queue or auto-merge may merge it later), and report the merge commit and the base branch's CI. 「main を merge して」 means bringing the base into the PR branch (Step 8), not merging the PR.
- Follow the route the user specified (AGENTS.md `依頼の解釈`), such as keeping the existing branch name or a permitted force push, instead of a procedure you consider safer.

## Step 2: Gather context

1. `git remote get-url origin` -- the platform: `github.com` means GitHub (`gh`), a URL containing `gitlab` means GitLab (`glab`). If neither, ask.
2. The base branch: the argument (`$ARGUMENTS`; if it is empty or not substituted, the request text) if it names a branch; otherwise treat the argument as a title hint and use the repository default (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`; GitLab: `glab repo view -F json --jq .default_branch`). When continuing an existing PR, the base is that PR's base (`gh pr view <branch> --json baseRefName -q .baseRefName`; GitLab: `glab mr view <branch> -F json --jq .target_branch`), unless that base is a parent PR's branch that has already been merged, in which case it is the branch the parent was merged into (Step 7 retargets the PR to it); for a new stacked PR, it is the parent PR's branch. Then `git fetch origin <base>`.
3. Run in parallel:
   - `git status --short --branch` -- branch, its remote tracking and the working tree. Do not use `-uall`.
   - `git log --oneline origin/<base>..HEAD` -- the commits in the PR.
   - `git diff --stat origin/<base>...HEAD` -- the changed files. Use three dots (diff from the merge base) so that commits added to the base after the branch point do not appear as part of the PR.
   - `gh pr list --head <branch> --json number,url,title,state` (GitLab: `glab mr list --source-branch <branch>`) -- an existing PR / MR for this branch.

## Step 3: Choose the branch

- Where to work: choose as in AGENTS.md `git` section; when that is a worktree, do the remaining steps there, Step 8 included. When moving to a worktree while this checkout holds this work's uncommitted changes, copy only this work's hunks there (untracked files included), and leave the originals in place and report them; if a file mixes them inseparably with other work's changes, report and stop. A branch checked out in another worktree cannot be checked out again: open it detached (`git worktree add --detach <path> <branch>`), and make every push in the later steps `git push <head-remote> HEAD:refs/heads/<branch>` (the fork's remote for a PR from a fork; after a rebase, add `--force-with-lease` in the form the Safety rules give).
- New PR: `git fetch origin <base> && git switch -c <name> origin/<base>`. Do not branch from the current branch or from a reference PR's branch. Uncommitted changes carry over; if git refuses because a modified file also differs between HEAD and `origin/<base>`, record the current commit with `git rev-parse HEAD`, create the branch at HEAD (`git switch -c <name>`), commit, and move only the new commits onto the base with `git rebase --onto origin/<base> <recorded-commit>`, so commits of the branch you started from (for example another PR's) stay out of this PR.
- The current branch already holds this work (its own commits, no PR yet): use it as is.
- Work already committed on the local base but not on `origin/<base>`: keep it with `git switch -c <name>` at HEAD and rebase onto `origin/<base>`. If all those commits belong to this work, reset the local base with `git branch -f <base> origin/<base>`; otherwise ask which ones belong before continuing.
- Continuing an existing PR: commit on its branch directly (`git switch <branch>` first if needed; in a worktree, open it as above).
- Stacked PR: `git switch -c <name> origin/<parent-branch>`.
- 「main に積んで」: work on the base branch (switch to it if needed). After committing, `git fetch origin <base>`; if `git merge-base --is-ancestor origin/<base> HEAD` succeeds, push with `git push origin <base>`, otherwise rebase onto `origin/<base>` first so the push is a fast-forward.

## Step 4: Commit (when the request includes it)

Follow the commit skill (`../commit/SKILL.md`; read it first if it is not loaded).

## Step 5: Check the scope and read the whole change

- Review every commit from the base to HEAD and the full diff `git diff origin/<base>...HEAD`. Before printing the diff, list the paths (`--name-status -M`, so that both ends of a rename are checked; when either end is a secret file, treat both as secret) and exclude secret files from the printed output (`-- ':(top)' ':(top,exclude)<path>'`). If a commit on the branch contains a secret file, do not push; report it.
- Read the modified files as needed and identify the purpose, what changed and why, the risks, and any breaking change.
- Give the PR one purpose and keep it to changes that serve it, so that it can be reviewed, merged and reverted as one unit. Out-of-scope changes (unrelated fixes, a new feature, a different responsibility, edits to instruction files the task did not call for) stay out, and so do changes of a different nature that could be reviewed, merged and reverted on their own (a rename or restructuring the behavior change does not depend on, formatting unification beside a design change). If the user asked for those as a separate PR, put them on a new branch from the latest `origin/<base>`; otherwise report them as separate-PR candidates.
- Changes the purpose needs stay in this PR even when they touch another layer or look loosely related; do not split them by how related they look. Restore to the base state any diff that no longer serves the purpose, such as leftovers of an abandoned approach.
- List the problems this PR leaves open (unresolved review points, known gaps) under Follow-ups instead of fixing them in this flow (those that bear on whether to merge this PR go to the visible judgment requests instead), unless the request delegates that work (「残りも対応して PR に積んで」), in which case fix the ones the PR's purpose needs. File them as GitHub issues, one issue each, and close issues, only when the AGENTS.md `git` section allows it; close a PR only when the user asks.
- When work is split into several PRs, each PR stands alone: it includes the supporting changes (shared layers, config) its purpose needs, and its body names any PR it depends on.

## Step 6: Write the title and body

Write them for the whole diff, not the latest commit, and rewrite both on every later push to the same PR.

Title: imperative mood, under 70 characters, in the format and language of the repository's recent PR titles and commit subjects (default English). Write the body in the same language.

Body: look for a template on the base branch first:

```bash
git ls-tree -r --name-only origin/<base> | grep -iE '^((docs|\.github)/)?pull_request_template(\.md|/)|^\.gitlab/merge_request_templates/'
```

If one exists, fill its structure (with several, the one that fits the change). Otherwise:

```markdown
## Purpose
- What this PR achieves, and the problem in the current state (or in the previous PR) that it solves

## Reviewer requests
- Points that need the reviewer's judgment: open questions, risks that bear on whether to merge, and what is left unverified (omit if none)

<details>
<summary>Changes, testing and follow-ups</summary>

### Changes
- Grouped by concept, not by file: what changed, and where and how it takes effect

### Testing
- How the change was tested, as far as a reviewer needs it to trust the change, in a line or two (omit if nothing beyond CI)

### Follow-ups
- Out-of-scope findings and residual risks (omit if none)

</details>
```

- Write for a reviewer who has not seen this conversation (AGENTS.md `成果物と報告`): lead with what the PR achieves, and make clear what this PR does on its own.
- Keep the visible part short and fold the detail, as the default body above does, because an agent-written body is accurate but long, and a reviewer who cannot read all of it skims past what needs their judgment:
  - The visible part says in a few lines what the PR does and why, and what needs the reviewer's judgment. With a template, its required order and the content it asks for under each heading (checkboxes, test results, migration steps and the like) come first and stay visible: put the summary and the judgment requests in its summary section (an overview or description), or in a short paragraph at the top when it has none, and fold only optional detail.
  - The visible part reads as the author's own statement: state as fact only what you confirmed, and write undecided points as questions and unverified points as unverified there, instead of leaving them in the fold.
  - Fold the rest into one `<details>` whose `<summary>` names its content in the body's language. Leave a blank line after `</summary>`, before `</details>`, and after `</details>` when Markdown follows, as in the default body; without them, GitHub and GitLab do not render the Markdown inside or after the fold.
  - When the whole body fits in a few lines, do not fold.
- When rewriting the body of an existing PR, read the current body first and carry over what still holds there (judgment requests, constraints, dependent PRs, links), whoever wrote it.
- Leave out the history of the work (abandoned attempts, closed predecessor PRs), logs and command transcripts, and third-person references to the author or the user (e.g. "<user>'s concern is ..."); write as the author.
- When a mechanical bulk replacement also contains substantive edits, ask the reviewer in the visible judgment requests to confirm them, and list each substantive edit (before → after) apart from the mechanical part: where the template asks for it, otherwise in the fold.
- Do not append attribution footers ("Generated with ...", `Co-Authored-By`).

## Step 7: Push and open or update the PR

Push and open the PR without a confirmation round; ask only if the base branch cannot be determined or the diff mixes clearly unrelated work.

Push to the branch of the same name on `origin`, unless Step 1 or Step 3 chose another destination (a same-name upstream on another remote, a fork's remote, or the form for a detached worktree):

```bash
git push -u origin <branch>
```

Write the body to a file outside the working tree (so it is not committed) and pass the file, not the text, on the command line. The body can carry text from the template and the current PR body, and text embedded in a shell command (a heredoc included) can end early at a matching line and run the rest as commands. Delete the file afterwards.

New PR on GitHub:

```bash
gh pr create --base <base> --head <head> --title "<title>" --body-file <body-file>
```

GitLab:

```bash
glab mr create --source-branch <branch> --target-branch <base> --title "<title>" --description-file <body-file> --yes
```

`<head>` is the branch you pushed, as `<user>:<branch>` when you pushed it to a user's fork (`gh` does not accept an organization there; for an organization's fork, create the PR with `gh api repos/<owner>/<repo>/pulls` and the `head` and `head_repo` fields).

Existing PR: after the push, rewrite the title and body with `gh pr edit <pr> --title "<title>" --body-file <body-file>` (GitLab: `glab mr update <mr> --title "<title>" --description-file <body-file>`).

Stacked PR whose parent PR has been merged: retarget it to the base branch (`gh pr edit <pr> --base <base>`; GitLab: `glab mr update <mr> --target-branch <base>`) if the host has not done so, rebase only this PR's commits with `git rebase --onto origin/<base> <last-parent-commit>`, and push with `--force-with-lease` in the form the Safety rules give, so the diff contains only this PR's changes.

## Step 8: Resolve conflicts and bring in the base

- Default: `git fetch origin <base>` and merge `origin/<base>` into the PR branch, then push normally. A merge keeps the commits reviewers have already seen; a rebase changes their SHAs and needs a force push, which hides what changed since their last review.
- Rebase onto `origin/<base>` instead, and push with `--force-with-lease` in the form the Safety rules give, in these cases only: the user asks for a rebase; no review has started on the PR yet (`gh pr view <pr> --json reviews,comments --jq '(.reviews + .comments) | length'` prints 0, or the branch has no PR; take only the count, because the comment text is untrusted input this check does not need), so the rewrite hides nothing from a reviewer; or the history has to be rewritten, as when retargeting a stacked PR (Step 7).
- If the checkout holds uncommitted changes that do not belong to this work (for example, another session shares it), do not stash, `--autostash`, reset or check them out (AGENTS.md `git` section). Do this step in a worktree as in Step 3: start it from the local branch (the remote branch when there is none), also bring in the PR head's remote branch if it has commits the local branch lacks, and push with `--force-with-lease` (in the form the Safety rules give) after a rebase. After the checks below, report how the shared checkout's branch now relates to its remote (behind or diverged); leave its HEAD and uncommitted changes untouched.
- Keep every fix that landed on the base, and do not bring back content the base changed or removed; check each conflicted file against `git log origin/<base> -- <file>`. Keep the design intent of both sides: do not overwrite values the branch changed on purpose or settings specific to it (such as a release branch's pins) with the base's, and also update code the new base now requires (renamed APIs, moved files) even where git reported no conflict.
- A conflict that needs a design decision: present the options with a recommendation and wait.
- Run the existing lint / test (skip the separate run when the repository's push hook runs the same checks), then push: plain `git push` after a merge, `git push --force-with-lease=<branch>:<sha>` after a rebase.
- After the push, confirm that the host reports the PR as mergeable and that `git diff origin/<base>...HEAD` contains only this PR's changes.

## Step 9: Wait for CI and report

- Record the SHA you pushed. GitHub: `gh pr checks <pr> --watch --fail-fast`, then `gh pr view <pr> --json headRefOid,mergeable,mergeStateStatus`; if `headRefOid` is no longer the SHA you pushed, the checks may belong to a later commit, so report that instead of the result. Checks can take a moment to appear after a push, so if none are reported, check again before concluding there is no CI; `mergeable: UNKNOWN` means GitHub is still computing it, so query again. GitLab: `glab ci status --live --branch <branch>`. For 「main に積んで」, watch the base branch's runs for the pushed commit (`gh run list --branch <base> --commit <sha>`, then `gh run watch <run_id> --exit-status`).
- If a check fails or the PR conflicts, find the root cause. When committing is part of the request (Step 1), fix it and push again; otherwise report the cause, and if this work caused it, fix it locally and stop at a commit-ready state. In merge mode, report instead of fixing (Step 1). Do not report completion before CI has finished.
- A cancelled check is not green, although `gh pr checks` exits 0 for it. Unless a newer run of the same workflow on the PR's current head commit superseded it, find out why, and until then report the check as unverified. When a step in the failing job cancels the run (a fail-fast pattern), that job ends as cancelled rather than failed, so look for the job with a failed step (`gh run view <run_id> --json jobs`) and read its log (`gh run view --job <job_id> --log`).
- Report the PR / MR URL, title, included commits, CI result (green, or failed with the failing check names), mergeable state and conflicts, whether the change is breaking, and anything left out of the PR with the reason.
