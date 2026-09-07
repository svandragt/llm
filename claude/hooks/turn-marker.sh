#!/bin/sh
# UserPromptSubmit hook: inject a per-turn id and instruct Claude to echo it,
# so ⟦turn tN⟧ lands in the visible reply (and thus terminal scrollback).
# Id = transcript line count at submit time (monotonic, unique per turn, no state).
#
# Only the interactive terminal TUI has scrollback worth marking. Skip every
# other context: print one-shots (entrypoint sdk-cli), other front-ends
# (claude-desktop, claude-vscode, claude-in-teams, github-action), and
# background/reporting runs (SESSION_KIND set, e.g. bg).
[ "$CLAUDE_CODE_ENTRYPOINT" = cli ] || exit 0
[ -n "$CLAUDE_CODE_SESSION_KIND" ] && exit 0
p=$(jq -r '.transcript_path // empty')
[ -n "$p" ] && [ -f "$p" ] || exit 0
n=$(wc -l < "$p" | tr -d ' ')
printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"Begin your reply with this exact marker inline, followed by a space and then your reply text on the same line: ⟦turn t%s⟧"}}\n' "$n"
