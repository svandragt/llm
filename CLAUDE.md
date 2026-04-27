# Skills Reference Library

A collection of reusable Claude Code skill prompts. See `README.md` for user-facing structure, validation, packaging, and installation details.

## Working in this repo

- Skills live as self-contained directories under `skills/<name>/SKILL.md`.
- After adding, renaming, or removing a skill, **also update the Skills table in `README.md`** (keep it alphabetical) and re-run `bin/link-skills.sh` to expose changes in `~/.claude/skills/`.
- `bin/manage-skills.sh` is an `fzf` TUI for toggling individual skills on/off (enable = repo symlink in `~/.claude/skills/`; disable = remove the symlink).

## Skills NOT owned by this repo

Some entries in `~/.claude/skills/` are sourced externally and must **not** be added back to `skills/`:

- `park` — upstream at https://github.com/svandragt/park (lives as a real local dir).
- `hm-coding-standards` — work-internal, manually copied into `~/.claude/skills/`.

`bin/link-skills.sh` ignores these because they aren't symlinks it manages.

## Validation

`skills validate skills/<name>` (from [skills-cli](https://pypi.org/project/skills-cli/)) — checks frontmatter before packaging.
