---
name: ticket-progression
description: >-
  Link a code PR to its Zenhub ticket, and optionally advance the ticket's
  pipeline. Use when the user wants to connect / link a pull request to its
  Zenhub issue, "progress" or "advance" a ticket, or when work on a
  number-prefixed branch (e.g. 1231-slug) has reached a new stage (PR opened,
  PR merged). Wikimedia repos: code is public, tickets live in the private
  humanmade/Wikimedia repo tracked in Zenhub.
---

# Ticket progression

Connect the current branch's PR to its Zenhub ticket (stage 1), and optionally move
the ticket's pipeline forward (stage 2). Cross-repo: the code repo may be public, the
ticket lives in the private `humanmade/Wikimedia` repo in a Zenhub workspace.

**Direction rule (hard):** never write the private ticket reference into the public PR
or any public surface. Only ever post the public PR *into* the private ticket / Zenhub.
See the `no-client-tickets-public` memory.

**Mode:** assisted. Always show the proposed action and get a one-line confirmation
before any write. Never touch a ticket that isn't assigned to the user.

## Zenhub access: MCP preferred, `zh` fallback

Do the Zenhub reads/writes through the **Zenhub MCP** when it's connected — it handles auth
and the schema. At the start, look for its tools (e.g. `ToolSearch "zenhub"`); if any are
present, use them for resolving the issue/PR, connecting the PR, listing pipelines, and moving
the issue. Only if no Zenhub MCP tool is available, fall back to the bundled `zh` helper
(`~/.claude/skills/ticket-progression/zh`), which talks to the GraphQL API directly.

- **Zenhub MCP setup** (one-time, user action): token from `app.zenhub.com/settings/tokens`,
  the 24-char workspace ID, Node.js; config at `developers.zenhub.com/mcp`.
- **`zh` fallback token:** `$ZENHUB_TOKEN` or `~/.config/zenhub/token`. If neither the MCP nor
  a token is available, stop and tell the user:

  > No Zenhub access. Either connect the Zenhub MCP (developers.zenhub.com/mcp) or create an
  > API token (app.zenhub.com/settings/tokens) and set `$ZENHUB_TOKEN` or
  > `~/.config/zenhub/token`. Nothing is committed.

The steps below name `zh` subcommands for the fallback; when using the MCP, use the equivalent
Zenhub MCP tool instead (same inputs: issue/PR by repo+number, connect PR↔issue, move issue to
a pipeline).

## Stage 1 — link the PR to the ticket

1. **Find the PR.** `gh pr view --json number,url,state,title`. No PR yet → "open a PR
   first, then re-run" and stop.
2. **Ticket number.** Take the leading number (matches `^([0-9]{2,})`) from the branch name
   (`git branch --show-current`); if the branch has none (e.g. `svandragt/…`), try the same
   pattern on the **PR title** (PRs are often titled `1231: …`). Still none → report "no
   ticket number on the branch or PR title — nothing to link" and stop. (This is the ticket
   number in `humanmade/Wikimedia`, not the PR's own number.)
3. **Identify the ticket via den.** `mcp__den__list_tickets` for project
   `humanmade/Wikimedia` (and the zenhub board if needed); find the issue whose number
   matches. Confirm `assignee` is the user; if not, warn and ask before continuing. Note
   its `zenhub_board`. Recover the **workspace id** from a zenhub-sourced ticket on the
   same board — its `source_url` looks like
   `…/workspaces/<slug>-<24hexWorkspaceId>/issues/…`; the trailing 24-hex is the id.
4. **Discover / cache.** Run `~/.claude/skills/ticket-progression/zh discover <workspaceId>`. This confirms the
   connect mutation name from live introspection and caches the workspace's pipelines and
   attached repos into `cache.json`.
   - **Check the code repo is attached:** if the current repo's `owner/name` is not in
     `cache.json .repos[].slug`, Zenhub can't reference the PR. Fall back to a GitHub
     comment: `gh api repos/humanmade/Wikimedia/issues/<N>/comments -f body="Linked PR: <PR url>"`
     (needs write to that private repo). Tell the user you used the comment fallback and
     why, then stop.
5. **Resolve node ids.**
   `~/.claude/skills/ticket-progression/zh resolve-issue humanmade/Wikimedia <N>` → issue node id.
   `~/.claude/skills/ticket-progression/zh resolve-pr <currentOwner/repo> <M>` → PR node id.
   A `NOT_FOUND` error means the number doesn't name a real ticket (often a mistyped title) —
   report "ticket #<N> not found — check the number" and stop, don't connect.
6. **Confirm + connect.** Show: `Link PR #<M> "<pr title>" → ticket #<N> "<ticket title>"?`
   On yes: `~/.claude/skills/ticket-progression/zh connect <issueId> <prId>`. Report success, and mention the PR
   now shows as a linked PR on the ticket card (and that this may auto-advance the pipeline
   if the workspace has that automation).

## Sweep — link all open PRs at once

To check/link every open PR in a repo (not just the current branch), run the bundled sweeper:
`~/.claude/skills/ticket-progression/link-open` (dry-run: prints what it would link) then
`… link-open --apply` to create the connections. It detects the ticket number from each PR's
branch or title, skips PRs with no number / non-existent tickets / already-linked ones, and
targets `humanmade/Wikimedia`. Optional `owner/repo` arg overrides the current repo. Show the
dry-run and confirm before `--apply`.

## Stage 2 — advance the pipeline (only if asked)

Forward-only, assignee-only, confirm each. Decide the target from state:

| Local state | Target pipeline |
| --- | --- |
| number branch with commits, no PR | In Progress |
| open PR | Code Review |
| PR merged | HM QA |

1. `~/.claude/skills/ticket-progression/zh pipelines <workspaceId>` → `{name → id}`. Match the target by name using
   these aliases (case-insensitive): In Progress ~ `in progress`; Code Review ~ `code review`,
   `in review`; HM QA ~ `hm qa`, `qa`. No confident match → list the pipelines and ask.
2. Compare with the ticket's current `zenhub_pipeline` (from den). If already at or past the
   target, report "nothing to do" (never move backward).
3. Confirm `Move ticket #<N> from "<current>" → "<target>"?`; on yes:
   `~/.claude/skills/ticket-progression/zh move <issueId> <targetPipelineId>`.

## Notes

- `zh` is thin on purpose; the Zenhub schema specifics are confirmed by `zh discover`
  (introspection) on first tokened run and cached. If `connect`/`move` report the mutation
  wasn't discovered, re-run `zh discover <workspaceId>` and check `cache.json .mutationNames`.
- den data can lag its source; treat den as identity/assignee/current-pipeline read, and
  Zenhub as the authoritative write. den catches up on its next sync.
