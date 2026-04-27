---
name: composer-lock-sync
description: After resolving a composer.lock merge conflict, run composer update --lock, validate, and audit to ensure consistency and safety
---

You are finalizing a `composer.lock` merge conflict resolution. Run these three commands in order and report results.

## Steps

### 1. Update the lock file content hash

```bash
composer update --lock
```

This regenerates the `content-hash` in `composer.lock` to match `composer.json` without changing any installed versions.

Expected: exits 0 with no errors.

### 2. Validate composer.json and composer.lock

```bash
composer validate
```

Expected: "composer.json is valid" (warnings about funding/support are acceptable).

### 3. Run security audit

```bash
composer audit
```

Expected: no vulnerabilities found, or only known-and-accepted ones.

## Report

For each command: show the exit code and relevant output (trim verbose install logs). If any command fails, show the full error output and stop — do not proceed to the next step.

Final status: **DONE** (all three passed) or **BLOCKED** (command N failed — describe what needs fixing).
