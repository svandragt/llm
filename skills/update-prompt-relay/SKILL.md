---
name: update-prompt-relay
description: Pull the latest noeltock/prompt-relay and reconcile the copied routing block in ~/.claude/CLAUDE.md. Use when the user says "update prompt relay", "pull prompt-relay", or invokes /update-prompt-relay.
---

# Update prompt-relay

The clone at `~/dev/llm/prompt-relay` is symlinked into `~/.claude` (agents, `references/routing.md`, `hooks/prompt-relay`, `bin/bulk-read`), so a pull updates those on its own. The one copied part is the routing block in `~/.claude/CLAUDE.md`, which has a Claude-only roster table in place of upstream's.

1. Pull and show what changed:

   ```
   git -C ~/dev/llm/prompt-relay pull --ff-only
   git -C ~/dev/llm/prompt-relay log --oneline ORIG_HEAD..HEAD
   ```

   Nothing new? Say so and stop.

2. If `profiles/claude-CLAUDE.md` changed, diff it against the block in `~/.claude/CLAUDE.md` (from `# Model routing & delegation` to the next `# ` heading). Ignore the roster table, which is deliberately different, and the `##` to `#` heading change.

3. Show the user the upstream changes to that block as a diff. Apply them to `~/.claude/CLAUDE.md` only after a one-line confirmation. Never overwrite the roster table.

4. If `settings.example.json` changed, report new env keys or hook entries and offer to merge them into `~/.claude/settings.json`. Do not remove anything already there.

5. If `hooks/claude/README.md` or `docs/install.md` mention a new file that is not yet symlinked, offer the symlink.

Report in one line what was pulled and what was applied.
