---
name: pr-merge-order
description: Plan the merge order for a batch of open PRs against a protected base, minimizing required approvals and lockfile conflicts. Use when several dependency or maintenance PRs are open at once.
---

Plan the order in which to merge a batch of open pull requests. Aim for the fewest approvals and the fewest conflict resolutions, not the fastest first merge.

Don't resolve conflicts or review the changes themselves here. Hand lockfile resolution to `composer-lock-sync` and change review to `dependency-update-review`.

## Step 1 — Collect the batch

```bash
gh pr list --limit 100 --json number,title,author,assignees,isDraft,baseRefName,headRefName,mergeable,mergeStateStatus,labels,url
```

For each candidate, get what the list view omits:

```bash
gh pr view <n> --json reviewDecision,reviews,statusCheckRollup,files,commits
```

Exclude two kinds of PR from the plan:

- **Environment sync PRs.** These are titled `sync: <branch> to <env>`, or their head branch ends in an environment suffix such as `-development` or `-preprod`. A bot opens them to push a branch onto a deploy environment. They target an unprotected branch, cost no approval, and regenerate whenever someone re-labels the source branch. Merge them when convenient, and never let them constrain the order.
- **Drafts that aren't ready.** Ask the author before you plan around a draft. A draft you can't influence isn't a step in your plan. List it as out of scope and say what it needs when it lands.

Report which PRs you excluded and why. Silent exclusion reads as "I covered everything".

## Step 2 — Read the protection rules on the base

This step determines the whole plan. Don't skip it, and don't assume defaults.

```bash
gh api repos/<owner>/<repo>/branches/<base>/protection
```

Read these four fields and determine what each one costs:

| Field | When set | Consequence |
|-------|----------|-------------|
| `required_approving_review_count` | ≥1 | Every merge costs that many reviews |
| `dismiss_stale_reviews` | true | Any push to a PR discards its approval, so push first and request review second, never the reverse |
| `required_status_checks.strict` | true | A branch must be up to date with the base, so each merge forces a no-op merge commit on every other PR |
| `require_last_push_approval` | true | The author can't be the last pusher, so a second person is needed after any fix-up |

`strict` and `dismiss_stale_reviews` together is the expensive combination. `strict` forces a push that changes nothing reviewable, and that push trips `dismiss_stale_reviews`. Every merge to the base then invalidates the approval on every other open PR, so you can't batch approvals and the total equals the number of PRs you merge.

When you find that combination, report it and recommend turning off `strict` rather than `dismiss_stale_reviews`:

```bash
gh api -X PATCH repos/<owner>/<repo>/branches/<base>/protection/required_status_checks -F strict=false
```

Use `-F` for booleans. `-f` sends the string `"false"` and the API rejects it with a 422.

Keep `dismiss_stale_reviews`. It's a real control: it stops unreviewed code landing on an approved PR. Dropping `strict` costs you the case where a PR and its base are each green but broken together. Weigh that against the repo's safety net. With a full test suite the risk is low. With only linting and visual regression, check whether the base is a staging branch with another gate behind it. If semantic breakage becomes a real problem, use a merge queue instead of `strict`.

Check the base of each PR too. A PR based on an unprotected branch costs no approval at all.

## Step 3 — Find redundancy and folds

Cut the approval count two ways before you merge anything.

**Close redundant PRs.** Compare commit subjects and changed files across the batch. When every commit in PR A also appears in PR B, close A as superseded:

```bash
gh pr view <a> --json commits -q '.commits[].messageHeadline'
gh pr view <b> --json commits -q '.commits[].messageHeadline'
```

**Fold related PRs.** When two PRs cover the same concern and touch the same files, retarget one onto the other's head branch:

```bash
gh pr edit <lower> --base <upper-head-branch>
```

The head branch is unprotected, so this merge costs no approval, and the PR keeps its number and review thread. Once the lower PR's head is contained in its base, GitHub closes it as MERGED on its own. You spend one approval instead of two.

Fold only when the combined PR still tells one story a reviewer can follow. Note the widened scope in the upper PR's description, or the reviewer meets an unexplained file. Ask first when the PR belongs to someone else.

## Step 4 — Order what remains

Step 3 already minimized approval cost, so order by conflict cost:

1. **Merge anything already approved and mergeable**, before another merge dismisses that approval. A spent approval is free. A dismissed one costs the team a second review.
2. **Merge PRs that don't touch a lockfile or other generated file.** They never conflict, so they cost nothing to move out of the way.
3. **Merge lockfile PRs one at a time.** Two open PRs that touch the same lockfile guarantee rework on one of them.
4. **Merge whole-file reformatters last.** A PR that runs a formatter such as `composer normalize`, `prettier --write`, or an import sorter over a shared manifest conflicts with every other PR that touches that file. Merge it first and every sibling PR faces an unresolvable diff. Merge it last and you re-run the formatter once, which is mechanical and safe.

## Step 5 — Verify mergeability locally

GitHub's `mergeStateStatus` goes stale. A PR reports `DIRTY` for hours and still merges cleanly. Prove the conflict exists before you write a resolution step into the plan:

```bash
git merge --no-commit --no-ff origin/<other-branch>
git merge --abort
```

`BLOCKED` together with `mergeable: MERGEABLE` means review is the only thing outstanding, so there's no work to plan.

When a lockfile conflict is real, don't merge the lockfile by hand. Reset it to one side and regenerate it:

```bash
git checkout --theirs <lockfile>   # --theirs is the incoming branch in a merge
```

Re-apply only that PR's intent with a targeted update command, then hand off to `composer-lock-sync` or the equivalent for the ecosystem. Set `git config rerere.enabled true` so you resolve each conflict once across repeated rebases.

## Step 6 — Report

Produce:

- **The order.** One line per PR: number, what it changes, and what it needs (an approval, a rebase, or nothing).
- **The approval count**, before and after your cuts. This is the headline number.
- **What you excluded**, and why: sync PRs, drafts, PRs owned by other people.
- **Any protection change you recommend**, with the reasoning and what it costs.
- **Per-PR review notes** wherever a diff confuses a reviewer: scope that grew from a fold, or changes that cancel out, such as a version bump and its revert showing as four lines that net to zero.

Keep the order scannable. Whoever executes it shouldn't have to re-derive your reasoning to take the next step.

## Known issues

- **`gh stack` can't run alongside per-PR worktrees.** It checks out each branch in turn and fails with `fatal: '<branch>' is already used by worktree at ...` (exit 1). For a short chain, retargeting by hand costs less than restructuring a checkout. `gh stack unstack --local` removes a stack's local tracking without touching GitHub.
- **Remote-tracking refs go stale too.** A branch that looks diverged might only need `git fetch`. Re-check before you report divergence.
- **Signed commits.** When the base sets `required_signatures`, sign every conflict-resolution commit. Confirm `commit.gpgsign` before you start.
- **A bot approval is cheap to replace, a human one isn't.** Auto-approval labels and Dependabot re-approve themselves, so treat those PRs as near-free in the ordering.
