---
name: ci-action-pinner
description: Update GitHub Actions `uses:` SHA pins to their latest versions without touching build tool versions (node-version, php-version, etc.)
---

You are updating GitHub Actions SHA pins in `.github/workflows/`. Follow these rules exactly.

## Rules

- **Only** update `uses:` lines — the action reference and its SHA pin.
- **Never** touch `node-version`, `php-version`, matrix values, or any other project build configuration.
- **Never** change the action version tag itself unless you can confirm the latest release — only update the SHA.

## Steps

### 1. Find all workflow files

List all `.yml` files in `.github/workflows/` and `.github/actions/`.

### 2. Extract all `uses:` references

For each file, find every line matching the pattern:
```
uses: owner/repo@SHA #vX.Y.Z
```

Collect unique `owner/repo` + version pairs.

### 3. Fetch latest SHA for each action

For each action, run:
```bash
gh api repos/{owner}/{repo}/git/ref/tags/{version} --jq '.object.sha' 2>/dev/null \
  || gh api repos/{owner}/{repo}/git/ref/tags/{version} --jq '.object.sha'
```

If the tag points to an annotated tag object (type `tag`), resolve it:
```bash
gh api repos/{owner}/{repo}/git/tags/{sha} --jq '.object.sha'
```

### 4. Update only changed SHAs

For each `uses:` line where the current SHA differs from the latest:
- Replace only the SHA portion, keeping the `#vX.Y.Z` comment intact.
- Do not change anything else on the line.

### 5. Report

List every file changed and which actions were updated (old SHA → new SHA). List any actions where the SHA was already current. If any action lookup failed, note it.
