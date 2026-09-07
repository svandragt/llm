#!/bin/sh
# Hold a sleep inhibitor only while a Claude Code session is working.
#
# Wired from ~/.claude/settings.json hooks: "busy" on UserPromptSubmit, "idle"
# on Stop, Notification and SessionEnd. One inhibitor process per session, so
# the machine only sleeps once every session has gone idle.
#
# It inhibits sleep but not idle, so the monitors still blank on schedule.
set -eu

state="${XDG_RUNTIME_DIR:-/tmp}/claude-inhibit"
mkdir -p "$state"

# Hooks get their JSON on stdin; fall back to the shell PID for manual calls.
id=$(jq -r '.session_id // empty' 2>/dev/null || true)
pidfile="$state/${id:-$PPID}"

case "${1:-}" in
	busy)
		if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
			exit 0
		fi
		# ponytail: 12h ceiling so a session that dies without firing an idle
		# hook can't pin the machine awake forever.
		# Detached stdio: the holder outlives the hook, and anything still
		# holding the hook's pipes open would block the caller until it exits.
		setsid systemd-inhibit --what=sleep --why="Claude busy" --mode=block \
			sleep 43200 </dev/null >/dev/null 2>&1 &
		echo $! >"$pidfile"
		;;
	idle)
		[ -f "$pidfile" ] || exit 0
		kill -- "-$(cat "$pidfile")" 2>/dev/null || true
		rm -f "$pidfile"
		;;
	*)
		echo "usage: ${0##*/} busy|idle" >&2
		exit 2
		;;
esac
