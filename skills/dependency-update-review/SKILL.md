---
name: dependency-update-review
description: Review pending npm and Composer dependency bump commits/PRs and report whether each is safe to merge (minor/patch only, no security issues, no lockfile divergence)
---

You are reviewing dependency update commits to confirm they are safe. Report a clear pass/fail for each package.

## What to check

For each changed dependency (in `composer.json`, `composer.lock`, `package.json`, `package-lock.json`):

1. **Version bump type** — is it patch, minor, or major? Flag any major bumps.
2. **Security flags** — run `composer audit` and/or `npm audit --audit-level=moderate` and report any findings.
3. **Lockfile consistency** — confirm `composer.lock` matches `composer.json` (run `composer validate --no-check-publish`) and `package-lock.json` matches `package.json`.
4. **Major version policy** — major bumps require explicit user approval; mark them as HOLD.

## Steps

### 1. Identify changed dependency files

Check git diff for changes in: `composer.json`, `composer.lock`, `package.json`, `package-lock.json`.

### 2. List changed packages

For each file changed, extract the package names and old → new versions.

### 3. Classify each bump

- patch (x.y.Z): auto-approvable
- minor (x.Y.z): auto-approvable
- major (X.y.z): HOLD — flag for user review

### 4. Run security checks

```bash
composer audit 2>/dev/null || true
npm audit --audit-level=moderate 2>/dev/null || true
```

### 5. Validate lockfiles

```bash
composer validate --no-check-publish 2>/dev/null || true
```

### 6. Report

Output a table:

| Package | Old | New | Type | Status |
|---------|-----|-----|------|--------|
| foo/bar | 1.2.3 | 1.2.4 | patch | PASS |
| baz | 2.0.0 | 3.0.0 | major | HOLD |

Then: security audit summary, lockfile validation result, and overall verdict (PASS / HOLD / FAIL).
