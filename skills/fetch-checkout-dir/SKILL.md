---
name: fetch-checkout-dir
description: "Copy a top-level directory from the repo's original (non-worktree) checkout into the current git worktree. Use when working in a linked worktree and an untracked directory (e.g. .claude/) is missing because it was never committed. Triggers: 'fetch the .claude dir', 'pull X from the original checkout', 'grab X from the main checkout'."
---

Linked git worktrees only get committed content — untracked directories (like a
local `.claude/` full of skills/config) exist only in whichever checkout they
were created in and don't propagate to new worktrees. This skill copies one
across.

## 1. Find the original checkout and the current project root

```bash
git worktree list
git rev-parse --show-toplevel
```

The **original checkout** is the first line of `git worktree list` — the main
worktree, not one of the linked ones (linked worktrees are every entry after
the first, and their path is what `git rev-parse --show-toplevel` prints when
run from inside them).

If `git rev-parse --show-toplevel` already matches the main worktree's path,
stop and tell the user there's nothing to fetch — they're already in the
original checkout.

## 2. Resolve which directory to copy

- If the user named a directory (as a skill argument or in their request),
  use that directly — skip to step 3.
- Otherwise, list top-level directories in the original checkout's root
  (`ls -d */ .*/ ` style, excluding `.git`) and diff against the top-level
  entries in the current project root. Keep only directories present in the
  original checkout but **absent** from the current project root — those are
  the candidates worth fetching; anything already present doesn't need
  fetching.
- If there are no candidates, tell the user and stop.
- If there is exactly one candidate, confirm with the user before copying
  rather than assuming.
- If there are multiple candidates, use AskUserQuestion (multiSelect) to let
  the user pick one or more.

## 3. Copy

For each chosen directory:

```bash
cp -r "<original_root>/<dir>" "<current_root>/<dir>"
```

Refuse to overwrite if the destination already exists — ask the user whether
to replace it or skip, don't clobber silently.

## 4. Report

State what was copied (source → destination) and note whether the directory
is tracked by git in the original checkout (`git -C <original_root> ls-files
--error-unmatch <dir>` on a sample file, or `git check-ignore`). If it's
untracked there too, mention that it still only lives in these two checkouts
and won't reach a fresh clone or other worktrees until it's committed.
