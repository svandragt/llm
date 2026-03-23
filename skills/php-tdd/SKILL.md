---
name: php-tdd
description: Enforce red-green TDD for PHP projects. Write a failing test first, confirm failure, implement minimum code, confirm green.
---

You are following red-green TDD for a PHP project. Never write implementation code before a failing test exists.

## Workflow

### Step 1: Write the Test

Create or extend a test file in the appropriate suite:
- **Unit** (`tests/Unit/`) for pure PHP logic with no HTTP
- **Acceptance** (`tests/Acceptance/`) for browser-level flows
- **Functional** (`tests/Functional/`) for framework-level tests

Write the minimum test that describes the new behaviour. One assertion per test method where possible. Name tests descriptively: `testFunctionNameDescribesExpectedBehaviour`.

For unit tests that need a database, set up an in-memory SQLite connection in `setUp()`:
```php
protected function setUp(): void
{
    if (!R::testConnection()) {
        R::setup('sqlite::memory:');
    }
    R::freeze(false);
}
```

### Step 2: Confirm the Test Fails (Red)

Run the unit tests:
```sh
vendor/bin/codecept run Unit
# or
vendor/bin/phpunit
```

The test **must fail** before you write any implementation. If it passes immediately, the test is wrong — revise it.

### Step 3: Write the Minimum Implementation

Write only enough code to make the failing test pass. Do not add functionality not required by the test. Do not refactor other code in this step.

### Step 4: Confirm the Test Passes (Green)

Run the tests again:
```sh
vendor/bin/codecept run Unit
# or
vendor/bin/phpunit
```

All tests must pass. If new tests pass but existing tests broke, fix the regression before continuing.

### Step 5: Check Coverage (Optional)

```sh
composer coverage
```

If a minimum threshold is configured, ensure it is still met.

## Rules

- Write the test **first** — no exceptions
- Implement the **minimum** to pass — no extra logic
- One failing test at a time — don't write multiple failing tests before implementing
- Keep test methods small and focused on a single behaviour

## Coverage details

If the composer coverage command is not available, this is the excerpt from a `composer.json`:

```json
     "coverage": [
       "vendor/bin/codecept run Unit --coverage-xml",
       "php check-coverage.php tests/_output/coverage.xml 60"
     ]
```

The check-coverage.php script is
```php
<?php

/**
 * Parses a Clover XML coverage report and exits with code 1 if coverage is below the threshold.
 *
 * Usage: php check-coverage.php <clover-xml-file> [threshold]
 */

$file = $argv[1] ?? 'tests/_output/coverage.xml';
$threshold = (float) ($argv[2] ?? 80);

if (!file_exists($file)) {
    fwrite(STDERR, "Coverage file not found: $file\n");
    exit(1);
}

$xml = simplexml_load_file($file);
if ($xml === false) {
    fwrite(STDERR, "Failed to parse coverage file: $file\n");
    exit(1);
}

$metrics = $xml->xpath('//project/metrics');
if (empty($metrics)) {
    fwrite(STDERR, "No metrics found in coverage file.\n");
    exit(1);
}

$total = (int) $metrics[0]['statements'];
$covered = (int) $metrics[0]['coveredstatements'];

if ($total === 0) {
    fwrite(STDERR, "No statements found in coverage report.\n");
    exit(1);
}

$coverage = ($covered / $total) * 100;
$coverageFormatted = number_format($coverage, 2);

echo "Coverage: {$coverageFormatted}% ({$covered}/{$total} statements)\n";

if ($coverage < $threshold) {
    fwrite(STDERR, "Coverage {$coverageFormatted}% is below the required {$threshold}%.\n");
    exit(1);
}

echo "Coverage threshold of {$threshold}% met.\n";
```
