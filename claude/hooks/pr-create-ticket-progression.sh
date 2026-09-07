#!/usr/bin/env bash
# PostToolUse(Bash) hook: after `gh pr create` in a Wikimedia repo, nudge Claude
# to run the ticket-progression skill. Lives in global settings but scopes itself
# to Wikimedia repos by inspecting the origin remote, so it stays quiet elsewhere.
set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

# Only react to PR creation, whatever else the Bash matcher passed through.
case "$cmd" in
	*"gh pr create"*) ;;
	*) exit 0 ;;
esac

# Wikimedia repos only: github.com/wikimedia/* and wpcomvip/wikimedia-* both match.
url=$(git remote get-url origin 2>/dev/null || true)
case "$url" in
	*wikimedia*) ;;
	*) exit 0 ;;
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"A pull request was just created in a Wikimedia repo. Run the ticket-progression skill now: link the PR to its Zenhub ticket (stage 1), then offer to advance the pipeline (stage 2, PR opened -> Code Review). Assisted, not automatic: show the proposed link/move and get a one-line confirmation before any Zenhub write, never touch a ticket that is not assigned to the user, and skip silently if the branch or PR has no ticket number."}}
JSON
