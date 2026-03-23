---
name: php-quality
description: Run the full PHP quality gate: auto-fix linting, check coding standards, run static analysis, run unit tests, and verify coverage threshold.
---

Run the full quality pipeline for a PHP project in this order. Stop and fix any failures before proceeding to the next step.

## Pipeline

### 1. Auto-fix Linting

```sh
composer fix
```

Automatically corrects coding standard violations using PHP CodeSniffer's fixer (phpcbf). Review the changes made.

### 2. Check Coding Standards

```sh
composer lint
```

Verifies PSR-12 compliance and PHP version compatibility. All violations must be resolved before continuing.

### 3. Static Analysis

```sh
composer analyse
```

Runs PHPStan. Fix all reported issues. If a baseline file exists, do not add new suppressions without justification.

### 4. Unit Tests

```sh
vendor/bin/codecept run Unit
```

Or if the project uses PHPUnit directly:
```sh
vendor/bin/phpunit
```

All tests must pass. Fix any failures — do not skip or comment out failing tests.

### 5. Coverage Threshold

```sh
composer coverage
```

If a minimum coverage threshold is configured (e.g. 60%), verify it is met. If coverage has dropped, add tests before proceeding.

## Notes

- Run steps in order — fixing lint before running tests prevents false failures
- If `composer fix` is not available, run `vendor/bin/phpcbf .` directly
- If `composer analyse` is not available, run `vendor/bin/phpstan analyse` directly
- If coverage tooling is not configured, skip step 5
- The full pipeline should pass before committing or opening a pull request
