---
name: php-pre-commit-setup
description: Install a pre-commit git hook for PHP projects that runs composer lint and composer analyse before every commit, blocking the commit if either fails.
---

Install a pre-commit hook for a PHP project that enforces coding standards and static analysis on every commit.

## What This Does

Installs a shell script at `.git/hooks/pre-commit` that runs:
1. `composer lint` — PSR-12 coding standards check
2. `composer analyse` — PHPStan static analysis

If either command fails, the commit is blocked. The developer must fix the issues before the commit can proceed.

## Installation

Run this command from the project root:

```sh
printf '#!/bin/sh\nset -e\ncomposer lint\ncomposer analyse\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
```

Verify the hook was installed:

```sh
cat .git/hooks/pre-commit
```

Expected output:
```sh
#!/bin/sh
set -e
composer lint
composer analyse
```

## Notes

- This is a **local** hook — it is not committed to the repository and must be installed by each developer after cloning
- Document the installation step in the project's `README` or `CONTRIBUTING` guide so contributors know to run it
- To bypass the hook in exceptional circumstances (not recommended): `git commit --no-verify`
- If `composer lint` or `composer analyse` are not configured, set up the corresponding composer scripts first:
  ```json
  "scripts": {
      "lint": "vendor/bin/phpcs .",
      "analyse": "vendor/bin/phpstan analyse"
  }
  ```
- Run `composer install` before first use to ensure `vendor/bin/phpcs` and `vendor/bin/phpstan` exist
