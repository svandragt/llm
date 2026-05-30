---
name: workshop-setup
description: Set up Canonical Workshop (the `workshop` CLI) on any project — verify the daemon is healthy, create a workshop definition, launch it, and confirm it works by running a command inside it. Use when asked to "set up Workshop", "add Workshop to this project", "create a workshop environment", or to check that an existing workshop is working.
---

Set up a [Canonical Workshop](https://ubuntu.com/workshop/docs/) development environment on a project and verify it works end-to-end.

Workshop creates sandboxed, reproducible dev environments from a YAML definition in the project's `.workshop/` directory. This skill covers **setup and verification only** — for ongoing operation (interfaces, worktrees, debugging changes), use the official `use-workshop` skill (see Related).

## Step 0 — Preflight: is the CLI and daemon healthy?

Run these first. They catch the most common breakage before you waste time.

```sh
workshop --version                         # CLI installed? e.g. "0.9.0"
systemctl is-active snap.workshop.workshopd.unix.socket   # should be "active"
workshop list                              # proves the client can reach the daemon
```

If `workshop --version` fails: the snap isn't installed. Install it (classic confinement):
```sh
sudo snap install workshop --classic
```

If `workshop list` fails with **"cannot communicate with workshopd ... socket not found"**:
- The daemon is **socket-activated** — being "inactive (dead)" until first use is normal. Just connecting wakes it.
- The real socket lives at `/var/snap/workshop/common/workshop/workshop.socket`.
- If a client hardcodes the old path `/var/lib/workshop/workshop.socket`, symlink it:
  ```sh
  sudo mkdir -p /var/lib/workshop \
    && sudo ln -sf /var/snap/workshop/common/workshop/workshop.socket /var/lib/workshop/workshop.socket
  ```
- Then re-run `workshop list`. Connecting triggers the systemd socket activation.

## Step 1 — Check for an existing workshop

```sh
ls .workshop/ 2>/dev/null && workshop list
```

If a definition already exists, **do not re-init**. Jump to Step 4 to verify it, or use `workshop refresh <NAME>` to apply definition changes.

## Step 2 — Create the definition

Pick a workshop name (convention: `dev`) and the SDKs the project needs. SDKs are comma-separated and may pin a channel as `<name>/<channel>`.

```sh
workshop init dev --sdks <sdk1>,<sdk2> [--base ubuntu@24.04]
```

This writes `.workshop/dev.yaml`. It **fails if a workshop of that name already exists** — that's expected; don't force it.

Choosing SDKs:
- Match the project's stack (e.g. `go`, `uv` for Python, `node`, `php`).
- `claude-code` is a common addition so the environment is agent-ready.
- `--base` defaults to `ubuntu@24.04`; only override when the project needs a specific base.

The resulting `.workshop/dev.yaml` looks like:
```yaml
name: dev
base: ubuntu@24.04
sdks:
    - name: claude-code
    - name: uv
```

## Step 3 — Launch

```sh
workshop launch dev
```

`launch` retrieves the base + SDKs, runs setup hooks, ties the workshop to the project, and starts it. For a single workshop you can add `--wait-on-error` to pause-and-fix on failure instead of aborting.

To update after editing the definition, use `workshop refresh dev` (not `launch`).

## Step 4 — Verify it works

This is the part that confirms the setup is actually correct, not just that commands returned 0.

```sh
# 1. Status is Ready (or Waiting) — not Pending/Stopped/Off
workshop list
workshop info dev          # full YAML: status, SDKs, revisions

# 2. Start it if it isn't running
workshop start dev

# 3. Run a real command INSIDE the workshop and check the output
workshop exec dev -- bash -lc 'echo OK && uname -a'

# 4. Verify each SDK is actually present, inside the workshop. Examples:
workshop exec dev -- bash -lc 'go version'        # if go SDK
workshop exec dev -- bash -lc 'uv --version'      # if uv SDK
workshop exec dev -- bash -lc 'claude --version'  # if claude-code SDK
```

Success criteria:
- `workshop list` shows the workshop as **Ready** with no warning notes.
- `workshop exec` prints the expected output (don't just trust the exit code — read it).
- Each SDK's version command works **inside** the workshop.

Also check for warnings and clear them:
```sh
workshop warnings
workshop okay <id>   # acknowledge once understood
```

## Using the workshop

```sh
workshop shell dev                    # interactive session inside the workshop
workshop exec dev -- <command>        # one-off command
workshop actions dev                  # list named actions from the definition
workshop run dev <action>             # run a named action
workshop stop dev / workshop start dev
workshop remove dev                   # tear down
```

## Notes

- Commit `.workshop/<name>.yaml` so the environment is reproducible for everyone. Other contributors run `workshop launch <name>` after cloning.
- This skill's daemon checks assume the snap install on systemd Linux. The `workshop` binary lives at `/snap/bin/workshop`.
- Keep the definition minimal — add SDKs only when the project actually needs them.

## Related

- Official operating skill: [canonical/use-workshop-skill](https://github.com/canonical/use-workshop-skill) — copy `.github/skills/use-workshop/` into `.claude/skills/use-workshop/` for full lifecycle operation (interfaces, worktrees, change debugging).
- Workshop docs: <https://ubuntu.com/workshop/docs/> (append `.md` to any page URL for machine-readable Markdown).
- AI agent reference: <https://ubuntu.com/workshop/docs/reference/ai-agents/>
