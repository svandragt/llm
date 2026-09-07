---
name: focus
description: When the user feels overwhelmed, scattered, or asks "what's next", surface exactly two next things to focus on. Triggers on "I'm overwhelmed", "what should I do next", "I'm scattered", "too much going on", "help me focus", "/focus".
---

# focus

The user feels scattered and wants **two** next things — not a dashboard, not a
full status. Completeness is the enemy here. Your whole job is ruthless
suppression: gather candidates, then throw almost all of them away.

Return **exactly two**. Never more. Two is the point.

## Gather

Don't build anything. Read what already exists. **den is the primary source** —
it already stores a per-ticket `ai_next_action` and a `triage_score`, so it has
done most of the ranking for you.

1. **den** (start here) — `mcp__den__list_tickets(project='*', limit=15)`.
   For each ticket use `ai_next_action` as the candidate action and
   `triage_score` as its weight. Prefer tickets whose next action is a reply,
   confirm, or decision (waiting on the human) over ones that are just more work.
2. **Live sessions** (optional garnish, only if it's cheap) — `ListAgents`, and
   only ping sessions that are *currently active* (row not `idle`; or a message
   already arrived `from-mode="prompting"`). Idle sessions won't answer a live
   poll — they drain messages at their next tool round — so never wait on them or
   block on stragglers. A late reply after you've already answered is fine to
   ignore. The line to send:
   > One line, no preamble: single next action you're waiting on from the human, and how urgent — [blocking]/[soon]/[whenever]? If nothing, reply "idle — <what you'd do next>".
3. **folio / park** (only if den was thin) — `mcp__folio-tasks__list_headings`,
   and anything parked and unresolved.

Skip any source that isn't reachable. Two good candidates is enough — stop early.
den alone is usually enough.

## Pick two

Rank by, in order:

1. **`[blocking]`** — something or someone is stuck waiting on the user.
2. **Smallest thing that fully closes a thread** — a yes/no, a confirm, a
   one-line reply that finishes already-committed work. Closing removes a thread;
   that is what cures "scattered", not starting something new.

Break ties toward *closing* over *starting*. If nothing is blocking and nothing
is small, take the highest `triage_score`.

## Output

Two lines. Each: the one concrete action + where it lives + why it's the pick.
Then one closing line offering to do the first one now. Nothing else — no third
option "for completeness", no status of the rest. If they want more, they'll ask.

Example:
> 1. **Reply on Wikimedia #1216** — a teammate asked weeks ago if the video block was closed on purpose; one comment unblocks them. *(someone waiting on you)*
> 2. **Wikimedia #1241** — reporter asked which supported languages are missing from the translation table; one compare-and-flag closes the ask. *(smallest close, highest triage)*
>
> Want me to draft the #1216 reply now?
