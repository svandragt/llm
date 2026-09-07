---
name: composer-lock-sync
description: After resolving a composer.lock merge conflict, verify the lock satisfies composer.json, then validate and audit
---

You are finalizing a `composer.lock` merge conflict resolution. Run these steps in order and report results. Stop and surface the failure if any step fails.

## Step 0 — Situational awareness (optional but cheap)

Show what dependency changes are in play so the operator can spot a missing package early:

```bash
git diff MERGE_HEAD..HEAD -- composer.json
```

This is informational only — no decision is made from it.

## Step 1 — Lock must be valid JSON

```bash
jq -e . composer.lock >/dev/null && echo "valid JSON" || echo "INVALID JSON"
```

This is the **first** gate. If `git checkout --ours|--theirs composer.lock` (or a manual edit) leaves merge markers (`<<<<<<<`, `=======`, `||||||| merged common ancestors`, `>>>>>>>`) anywhere in the file, the lock is no longer valid JSON. Composer can silently swallow this and the dry-run in step 3 may still report "Nothing to install" — that is a false positive caused by composer falling back to `composer.json`-only resolution when it cannot parse the lock.

**Watch especially for nested / previously-committed conflict markers.** A common trap is a long-lived branch where a prior conflict resolution committed merge markers into the lock; subsequent `--ours` checkouts then restore that already-broken file silently.

**If invalid:**

1. Open `composer.lock` and locate every `<<<<<<<`, `=======`, `||||||| `, `>>>>>>>` block.
2. Pick one side (typically the current branch's `content-hash` is fine — step 2 will rewrite it anyway).
3. Delete the markers and the lines from the other side(s).
4. Re-run the `jq` check until it reports `valid JSON`.

Do **not** proceed to step 2 until this passes — every subsequent gate can give a false-positive on broken JSON.

## Step 2 — Refresh the lock's content hash

```bash
composer update --lock
```

Regenerates `content-hash` to match `composer.json` without changing resolved versions.

Expected: exits 0. The output line `Nothing to modify in lock file` is **not** proof of correctness — it just means no already-locked package needed metadata changes. A package newly added to `composer.json` will not be added by this command.

## Step 3 — Verify the lock fully satisfies composer.json

```bash
composer install --dry-run --no-scripts
```

This is the real integrity check. It fails if any package required by `composer.json` is missing from `composer.lock`, or if the lock references a constraint the json no longer permits.

**If it fails with a "not in lock" / "package X is not satisfiable" / "not present in the lock file" message:**

1. Identify the offending package(s) from the error output.
2. For each one, run `composer update <package>` (NOT `--lock` — that only refreshes hashes and will not add a missing package).
3. Re-run step 2 until it passes.

Common cause: the conflict was resolved by taking one side of `composer.lock` (`git checkout --theirs|--ours composer.lock`) while `composer.json` was auto-merged with new requires from the other side. The lock then doesn't contain those new packages.

## Step 4 — Validate

```bash
composer validate
```

Expected: "composer.json is valid" (warnings about funding/support/exact-version-constraints are acceptable if the project has historically tolerated them).

## Step 5 — Security audit

```bash
composer audit
```

Expected: no vulnerabilities found, or only known-and-accepted ones.

## Report

For each step: show the exit code and relevant output (trim verbose install logs). If any step fails, show the full error output and stop — do not proceed.

Final status: **DONE** (steps 1–5 all passed) or **BLOCKED** (step N failed — describe what needs fixing).
