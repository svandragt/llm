---
name: wp-plugin-tdd
description: Enforce red-green TDD for WordPress plugins using Brain Monkey and Mockery. Write a failing test first, confirm failure, implement minimum code, confirm green.
---

You are following red-green TDD for a WordPress plugin. Never write implementation code before a failing test exists.

## Stack

- **PHPUnit 10+** — test runner (`composer test`)
- **Brain Monkey** — stubs and mocks for WordPress functions (`Functions\expect`, `Functions\stubs`, `Functions\when`)
- **Mockery** — mocks for classes (e.g. `$wpdb`, custom classes)

## Test file location

- `tests/Unit/` — pure PHP logic; no HTTP, no real DB

## Base test class pattern

Every test class follows this structure:

```php
<?php

declare(strict_types=1);

namespace Yak\MyPlugin\Tests\Unit;

use Brain\Monkey;
use Brain\Monkey\Functions;
use Mockery\Adapter\Phpunit\MockeryPHPUnitIntegration;
use PHPUnit\Framework\TestCase;

class MyClassTest extends TestCase
{
    use MockeryPHPUnitIntegration;

    protected function setUp(): void
    {
        parent::setUp();
        Monkey\setUp();

        // Stub WP functions used by every test in this class
        Functions\stubs([
            'current_time'   => fn($type) => '2026-01-01 00:00:00',
            'add_query_arg'  => fn($args, $base) => $base . '?' . http_build_query($args),
        ]);
    }

    protected function tearDown(): void
    {
        Monkey\tearDown();
        parent::tearDown();
    }
}
```

## Mocking $wpdb

Mock `$wpdb` with Mockery and inject into `$GLOBALS`:

```php
$this->wpdb         = \Mockery::mock('wpdb');
$this->wpdb->prefix = 'wp_';
$GLOBALS['wpdb']    = $this->wpdb;

// Stub prepare() to do a basic sprintf so SQL assertions are readable
$this->wpdb->shouldReceive('prepare')->andReturnUsing(
    fn(...$a) => vsprintf(str_replace(['%d','%s'], ['%s',"'%s'"], $a[0]), array_slice($a, 1))
);
```

Set expectations per test:

```php
$this->wpdb->shouldReceive('get_results')->once()->andReturn($rows);
$this->wpdb->shouldReceive('insert')->once()->andReturn(1);
$this->wpdb->insert_id = 42;
```

## Functions\expect vs Functions\stubs

| Use | When |
|---|---|
| `Functions\expect('fn')->once()->with(...)` | You want to assert the function was called (how many times, with what args) |
| `Functions\stubs(['fn'])` | You just need the function to exist and not throw — you don't care about the call |
| `Functions\when('fn')->justReturn(x)` | You need a default return value but no assertion |

**Critical rule:** When you add a call to a new WP function inside a class method, every existing test for that method will break with `"fn() is not defined nor mocked"`. Fix by adding `Functions\stubs(['new_fn'])` to the setUp of tests that don't assert on it.

```php
// New WP function added to implementation — existing tests need this:
Functions\stubs(['delete_site_option', 'update_site_option']);
```

## Workflow

### Step 1: Write the failing test

Write the minimum test that describes the new behaviour. One concept per test. Name tests `testMethodNameDescribesBehaviour`.

```php
public function testSaveResultStoresAllMetricColumns(): void
{
    $this->wpdb->shouldReceive('insert')
        ->once()
        ->with('wp_psi_results', \Mockery::on(fn($data) => $data['score_performance'] === 90));

    $store = new ResultStore();
    $store->save_result(1, 1, 1, 'mobile', ['score_performance' => 90, ...]);
}
```

### Step 2: Confirm it fails (red)

```sh
composer test
# or target one file:
vendor/bin/phpunit tests/Unit/MyClassTest.php
```

The test **must fail** before writing implementation. If it passes immediately, the test is wrong.

### Step 3: Implement the minimum

Write only enough code to make the failing test pass. Do not add untested functionality.

### Step 4: Confirm green

```sh
composer test
```

All tests must pass — including previously passing ones. If a regression appears, fix it before continuing.

### Step 5: Commit

```sh
git add <files>
git commit -m "Add MyClass::method_name — <what it does>"
```

Commit after each green step. Small, focused commits.

## Common patterns

### Asserting a function was called with specific args

```php
Functions\expect('update_site_option')
    ->once()
    ->with('psi_run_error_3', \Mockery::on(fn($v) => $v['message'] === 'PSI error'));
```

### Asserting a function was never called

```php
Functions\expect('update_site_option')->never();
```

### Testing that an exception is thrown

```php
$this->expectException(\RuntimeException::class);
$this->expectExceptionMessage('API returned HTTP 403');
$client->fetch('https://example.com', 'mobile');
```

### Capturing an argument for inspection

```php
$captured = null;
Functions\expect('wp_remote_get')
    ->once()
    ->andReturnUsing(function (string $url) use (&$captured) {
        $captured = $url;
        return [];
    });

// ... call the method ...

$this->assertStringContainsString('category=accessibility', $captured);
```

### Mocking a class dependency

```php
$client = \Mockery::mock(PsiClient::class);
$client->shouldReceive('fetch')
    ->with('https://example.com', 'mobile')
    ->once()
    ->andReturn(['score_performance' => 90, ...]);
```

## Pitfalls

- **`shouldReceive()` uses string method names** — if you rename a method (e.g. camelCase → snake_case), update every `shouldReceive('oldName')` call in tests
- **Named parameters must match** — if a method parameter is renamed (e.g. `$runId` → `$run_id`), update `makeHelper(run_id: 7)` call sites
- **`$wpdb` returns strings** — `get_results()` and `get_row()` return all column values as strings. Cast IDs with `(int)` before passing to methods that declare `int` parameters
- **Brain Monkey is per-test** — `setUp`/`tearDown` must call `Monkey\setUp()` and `Monkey\tearDown()` or function mocks leak between tests
