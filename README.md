# llm

A personal library of reusable [Claude Code](https://claude.ai/claude-code) skill prompts.

## Skills

| Skill | Description |
|---|---|
| `ci-action-pinner` | Update GitHub Actions `uses:` SHA pins to their latest versions without touching build tool versions |
| `composer-lock-sync` | After resolving a `composer.lock` merge conflict, run `composer update --lock`, validate, and audit |
| `dependency-update-review` | Review pending npm and Composer dependency bump commits/PRs and report whether each is safe to merge |
| `explain-code` | Explains code with visual diagrams and analogies |
| `lessons` | Capture concepts the user is learning as numbered lesson files under `.lessons/` |
| `php-pre-commit-setup` | Install a pre-commit git hook that runs `composer lint` and `composer analyse` before every commit |
| `php-quality` | Run the full PHP quality gate: auto-fix linting, static analysis, unit tests, and coverage check |
| `php-tdd` | Enforce red-green TDD for PHP: write a failing test first, confirm failure, implement minimum code, confirm green |
| `python-tdd` | Red-green TDD cycle for Python using pytest, then lint with ruff |
| `review-docs` | After user-facing changes, review `docs/` for pages that need updating and missing cross-links |
| `smoke-test` | Build a smoke-test document proving a new feature works end-to-end |
| `wp-plugin-tdd` | Enforce red-green TDD for WordPress plugins using Brain Monkey and Mockery |

## Structure

```
skills/<name>/SKILL.md
```

Each skill is a self-contained directory. `SKILL.md` requires YAML frontmatter:

```yaml
---
name: skill-name          # lowercase, hyphens only, max 64 chars
description: "..."        # max 200 chars — quote if it contains colons
---
```

After adding a new skill directory, re-run `bin/link-skills.sh` to expose it globally.

## Installation

`~/.claude/skills/` is the directory Claude Code loads global skills from. Rather than symlinking the whole directory to this repo (which forces every globally available skill to live here), use `bin/link-skills.sh` to create one symlink *per skill* into `~/.claude/skills/`:

```sh
git clone https://github.com/svandragt/llm.git ~/dev/llm
~/dev/llm/bin/link-skills.sh
```

The script is idempotent — re-run it after pulling new skills. It refuses to overwrite anything it doesn't already manage, so the directory can hold a mix of:

- symlinks managed by this script (skills from this repo),
- real directories written by third-party tools that ship their own Claude skill and install it globally,
- additional symlinks you create by hand pointing into other source repos (e.g. a work repo's `skills/`).

Skills scoped to a single project should live in that project's own `.claude/skills/` instead — Claude Code picks them up automatically when working in that directory.

### Enabling/disabling individual skills

`bin/manage-skills.sh` opens an `fzf` TUI listing every skill in this repo with its current state (`[x]` enabled, `[ ]` disabled, `[!]` foreign — untouched). Press enter to toggle, esc to quit. Requires `fzf`.

## Validation

Install [skills-cli](https://pypi.org/project/skills-cli/) and run `skills validate skills/<name>` to check a skill for missing or malformed frontmatter before packaging.

## Packaging

Create a zip per skill with the skill directory as the root inside the archive.

```sh
python3 -c "
import zipfile
name = 'skill-name'
with zipfile.ZipFile(f'{name}.zip', 'w') as z:
    z.write(f'skills/{name}/SKILL.md', f'{name}/SKILL.md')
"
```

Zip files are excluded from git (see `.gitignore`), and can be uploaded to https://claude.ai/customize/skills to make them available to Claude AI.

## License

[GPL-3.0](LICENSE).
