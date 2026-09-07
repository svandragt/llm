#!/usr/bin/env bash
# PreToolUse hook for Bash: block filesystem-wide scans.
# Blocks find/fd/grep -r/rg/locate/du whose target is / or a top-level
# directory ($HOME, /usr, /nix, /home, /var, /opt, /etc). Project paths pass.
set -u
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || exit 0
roots='(/|/home|/home/[a-z0-9_-]+|/usr|/nix|/var|/opt|/etc|~|\$HOME)'
block=0
if printf '%s' "$cmd" | grep -Eq "(^|[;&|]\s*|\bsudo\s+)(find|fd|fdfind)\s+(-[A-Za-z]+\s+)*${roots}(\s|$)"; then block=1; fi
if printf '%s' "$cmd" | grep -Eq "(^|[;&|]\s*)(grep\s+(-[A-Za-z]*r[A-Za-z]*|--recursive)|rg)\b[^;&|]*\s${roots}(\s|$)"; then block=1; fi
if printf '%s' "$cmd" | grep -Eq "(^|[;&|]\s*)(locate|plocate|mlocate|updatedb)\b|(^|[;&|]\s*)du\s+(-[A-Za-z]+\s+)*${roots}(\s|$)"; then block=1; fi
if [ "$block" = 1 ]; then
  echo "Blocked: filesystem-wide scan. Search inside the project or a named directory instead; for reference source, fetch it from its repository into the scratchpad." >&2
  exit 2
fi
exit 0
