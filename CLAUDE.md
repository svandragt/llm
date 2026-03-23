# Skills Reference Library

A collection of reusable Claude Code skill prompts.

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

## Validation

Run `skills-ref validate` to check all skills for missing or malformed frontmatter before packaging.

## Packaging

Create a zip per skill with the skill directory as the root inside the archive:

```sh
python3 -c "
import zipfile
name = 'skill-name'
with zipfile.ZipFile(f'{name}.zip', 'w') as z:
    z.write(f'skills/{name}/SKILL.md', f'{name}/SKILL.md')
"
```

Zip files are excluded from git (see `.gitignore`).
