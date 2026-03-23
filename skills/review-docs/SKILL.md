---
name: review-docs
description: After making user-facing changes, review the docs/ directory to find pages that need updating, flag missing cross-links, and suggest new pages where needed.
---

You are reviewing project documentation after a user-facing change. Follow these steps:

## 1. Understand What Changed

Identify what was added, changed, or removed that users would interact with. Look at recently edited files or the task description for context.

## 2. Scan docs/

List all files in the `docs/` directory. Read the titles and introductory paragraphs to understand what each page covers.

## 3. Find Related Pages

For each docs page, determine whether it is topically related to the change:
- Does it describe a feature that was modified?
- Does it reference a concept that changed?
- Would a user reading this page benefit from knowing about the change?

## 4. Check for Needed Updates

For each related page found:
- Is the information still accurate?
- Does it need new sections, examples, or caveats?
- Are any steps or screenshots now outdated?

Flag each page as: **needs update**, **looks fine**, or **unsure — review manually**.

## 5. Check Cross-Links

For each related page, verify it links to other related pages. Look for a "Related" section or inline links. If two pages are closely related but don't link to each other, flag the missing link.

## 6. Suggest New Pages

If the change introduces a concept, workflow, or feature not covered by any existing page, suggest a new page title and a brief outline of what it should contain.

## 7. Report

Output a concise summary:
- List of pages that need updating (with specific changes needed)
- List of missing cross-links (Page A ↔ Page B)
- Suggested new pages (if any)
- Pages that look fine (can be listed briefly)
