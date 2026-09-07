#!/usr/bin/env bash
# PreToolUse guard: block the session lead from editing source files directly.
# Subagent payloads carry .agent_type (e.g. coder-low) — those pass through.
input=$(cat)

agent_type=$(jq -r '.agent_type // empty' <<<"$input")
[ -n "$agent_type" ] && exit 0

file=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -z "$file" ] && exit 0

# Only guard source-code files
case "$file" in
  *.php|*.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.py|*.rb|*.go|*.rs|*.java|*.c|*.cc|*.cpp|*.h|*.hpp|*.css|*.scss|*.vue|*.svelte|*.sh|*.sql)
    ;;
  *)
    exit 0 ;;
esac

# Never guard config/memory/scratch areas
case "$file" in
  */.claude/*|*/memory/*|*/scratchpad/*|/tmp/*)
    exit 0 ;;
esac

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Lead guard: the session lead must not edit source files directly. Write a spec and delegate to a coder subagent (coder-low for fully-specified work, coder-high for judgment calls)."}}
JSON
