---
name: changelog-compiler
description: Compile .changelog/*.md entries into CHANGELOG.md for a new release version, then delete the individual files
---

You are preparing a new release changelog entry. You will be given (or should ask for) the new version number and today's date.

The project uses `.changelog/` for per-PR entries and `CHANGELOG.md` as the main file.

## Input required

If not provided, ask: **What is the new version number?** (e.g. `15.4.0`)

Today's date is already known from context.

## Steps

### 1. Read all .changelog/*.md entries

List files matching `.changelog/[A-Z]*.md` (skip `README.md`, `TEMPLATE.md`). Read each one.

### 2. Group by section heading

Each file contains one or more `### Section` headings followed by bullet lines. Merge all entries under the same section heading across files.

Standard section order (use this order in output):
1. Added
2. Changed
3. Deprecated
4. Removed
5. Fixed
6. Security
7. Dependencies

Sections not in this list go at the end.

### 3. Read current CHANGELOG.md

Find the first `## [version]` line — this is `PREVIOUS_VERSION`.

### 4. Build the new entry

```
## [NEW_VERSION](https://github.com/hm-sc/standard-chartered-nr/compare/PREVIOUS_VERSION...NEW_VERSION) - YYYY-MM-DD

### Section

- Entry one.
- Entry two.

### Section2

- Entry three.

```

### 5. Insert into CHANGELOG.md

Insert the new entry immediately after the intro block (before the first `## [version]` line). Preserve all existing content exactly.

### 6. Delete .changelog entry files

Delete each `.changelog/*.md` file that was read (skip README.md and TEMPLATE.md).

### 7. Report

List the new version entry (trimmed), which files were deleted, and confirm CHANGELOG.md was updated.
