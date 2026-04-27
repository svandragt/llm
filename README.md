# llm

A personal library of reusable [Claude Code](https://claude.ai/claude-code) skill prompts.

## Skills

| Skill | Description |
|---|---|
| `changelog-compiler` | Compile `.changelog/*.md` entries into `CHANGELOG.md` for a new release version, then delete the individual files |
| `ci-action-pinner` | Update GitHub Actions `uses:` SHA pins to their latest versions without touching build tool versions |
| `composer-lock-sync` | After resolving a `composer.lock` merge conflict, run `composer update --lock`, validate, and audit |
| `dependency-update-review` | Review pending npm and Composer dependency bump commits/PRs and report whether each is safe to merge |
| `explain-code` | Explains code with visual diagrams and analogies |
| `hm-coding-standards` | Set up and enforce Human Made (HM) coding standards in a WordPress plugin |
| `lessons` | Capture concepts the user is learning as numbered lesson files under `.lessons/` |
| `park` | Park context for later and resume parked items by number |
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

## Installation

Make the skills available to Claude Code across all local projects by symlinking this repo's `skills/` directory to `~/.claude/skills`:

```sh
# If ~/.claude/skills already exists, move any existing skills into this repo first
mv ~/.claude/skills/my-existing-skill /path/to/this/repo/skills/

# Remove the directory and replace it with a symlink
rmdir ~/.claude/skills
ln -s /path/to/this/repo/skills ~/.claude/skills
```

Claude Code will now discover all skills in this repo automatically, regardless of which project you're working in.

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
