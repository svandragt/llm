---
name: hm-coding-standards
description: Set up and enforce Human Made (HM) coding standards in a WordPress plugin. Installs humanmade/coding-standards, creates a phpcs.xml ruleset, auto-fixes violations, and systematically resolves the remainder.
---

Install and enforce [Human Made Coding Standards](https://github.com/humanmade/coding-standards) in a WordPress plugin project. The standard extends WordPress Coding Standards (WPCS) with stricter security, documentation, and formatting rules.

## Installation

```sh
composer require --dev humanmade/coding-standards
composer config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true
composer install
```

Add composer scripts:

```json
"scripts": {
    "lint":     "vendor/bin/phpcs",
    "lint-fix": "vendor/bin/phpcbf"
}
```

## Create phpcs.xml

Place at the project root. Start with these exclusions — all are justified for WordPress plugins using PSR-4 autoloading:

```xml
<?xml version="1.0"?>
<ruleset name="My Plugin">
    <description>HM Coding Standards</description>

    <file>includes/</file>
    <file>admin/</file>
    <file>cli/</file>
    <file>my-plugin.php</file>

    <arg name="extensions" value="php"/>
    <arg name="colors"/>
    <arg value="sp"/>

    <config name="testVersion" value="8.1-"/>
    <config name="minimum_supported_wp_version" value="6.0"/>

    <rule ref="HM">
        <!--
            PSR-4 / Composer autoloading uses PascalCase file names,
            not WordPress hyphenated-lower convention.
        -->
        <exclude name="WordPress.Files.FileName.NotHyphenatedLowercase"/>
        <exclude name="WordPress.Files.FileName.InvalidClassFileName"/>

        <!--
            WordPress.WP.I18n crashes on PHP 8.x with WPCS 2.x due to a
            trim(null) deprecation in the sniff itself.
        -->
        <exclude name="WordPress.WP.I18n"/>

        <!--
            Visual alignment of array values (key => value columns) is
            accepted HM practice.
        -->
        <exclude name="WordPress.WhiteSpace.PrecisionAlignment.Found"/>

        <!--
            Section-divider comments and phpcs:ignore explanations rarely
            end with punctuation.
        -->
        <exclude name="Squiz.Commenting.InlineComment.InvalidEndChar"/>

        <!--
            Plugin bootstrap requires the Composer autoloader before the
            use-import block — the ordering rule cannot be satisfied here.
        -->
        <exclude name="HM.Layout.Order.WrongOrder"/>

        <!--
            Table names ({$wpdb->prefix}table) cannot be parameterised via
            wpdb::prepare() — this is the required WordPress pattern.
            Dynamic queries built with spread-operator args also fail
            static analysis.
        -->
        <exclude name="WordPress.DB.PreparedSQL.InterpolatedNotPrepared"/>
        <exclude name="WordPress.DB.PreparedSQL.NotPrepared"/>
        <exclude name="WordPress.DB.PreparedSQLPlaceholders.UnfinishedPrepare"/>

        <!--
            PSR-4 class names match file names exactly; HM sniffs assume
            WordPress hyphenated-lower naming.
        -->
        <exclude name="HM.Files.ClassFileName.MismatchedName"/>
        <exclude name="HM.Files.NamespaceDirectoryName.NoIncDirectory"/>
    </rule>
</ruleset>
```

## Fixing violations

### Step 1: Auto-fix everything possible

```sh
composer lint-fix
```

phpcbf handles: indentation (tabs), spacing, brace placement, short array syntax.

### Step 2: Run phpcs to see what remains

```sh
composer lint
```

Group the remaining violations by sniff name and fix in batches.

---

## Common remaining violations and fixes

### `Generic.Commenting.DocComment.MissingShort`

Every docblock needs a short description on the first line.

```php
// Bad
/**
 * @param string $api_key Google PSI API key.
 */

// Good
/**
 * Create a new PsiClient.
 *
 * @param string $api_key Google PSI API key.
 */
```

### `Squiz.Commenting.FunctionComment.Missing`

Every function/method needs a docblock. For functions with a `phpcs:ignore` comment placed *before* them, the ignore breaks the docblock association. Move the ignore **inline** on the function line:

```php
// Bad — phpcs:ignore between docblock and function declaration
/**
 * My function.
 */
// phpcs:ignore HM.Functions.NamespacedFunctions.MissingNamespace
function my_function(): void {

// Good — ignore on the same line as the declaration
/**
 * My function.
 */
function my_function(): void { // phpcs:ignore HM.Functions.NamespacedFunctions.MissingNamespace
```

### `Squiz.Commenting.FunctionComment.MissingParamTag`

Every parameter must have an `@param` tag.

```php
/**
 * Run a PSI test.
 *
 * @param array $args  Positional arguments.
 * @param array $assoc Associative arguments.
 */
public function run( array $args, array $assoc ): void {
```

### `Generic.Commenting.DocComment.LongNotCapital`

The long description (second paragraph in a docblock) must start with a capital letter.

```php
// Bad
 * green: score >= target; amber: score >= target - 10; red: below that.

// Good
 * Green: score >= target; amber: score >= target - 10; red: below that.
```

### `HM.Security.ValidatedSanitizedInput.MissingUnslash`

All `$_GET` and `$_POST` values must be unslashed before sanitization.

```php
// Bad
$value = sanitize_text_field( $_POST['field'] );

// Good
$value = sanitize_text_field( wp_unslash( $_POST['field'] ?? '' ) );
```

### `HM.Security.ValidatedSanitizedInput.InputNotSanitized`

Use the correct sanitization function for the data type.

```php
// Integers — use absint() not (int) cast; satisfies the sniff
$id = absint( $_POST['id'] ?? 0 );

// Text
$label = sanitize_text_field( wp_unslash( $_POST['label'] ?? '' ) );

// Textarea / multi-line
$body = sanitize_textarea_field( wp_unslash( $_POST['body'] ?? '' ) );

// Keys / slugs
$action = sanitize_key( $_POST['action'] ?? '' );

// Raw input that must be validated by the receiving function (e.g. bulk URLs for import)
// phpcs:ignore HM.Security.ValidatedSanitizedInput.InputNotSanitized -- validated by importer
$raw = wp_unslash( $_POST['bulk_urls'] ?? '' );
```

### `HM.Functions.NamespacedFunctions.MissingNamespace`

All functions must be in a namespace, or suppressed for admin include files that intentionally define global helpers:

```php
function my_helper(): void { // phpcs:ignore HM.Functions.NamespacedFunctions.MissingNamespace -- admin include
```

### `PSR1.Files.SideEffects.FoundWithSymbols`

This is a **warning**, not an error. Admin include files that define functions and also execute code will always trigger it. Acceptable to leave as-is.

### `HM.Performance.SlowMetaQuery.slow_query_meta_value`

Also a **warning**. Querying by `meta_value` is sometimes unavoidable (e.g. finding pages by page template). Acceptable to leave as-is with a comment.

---

## Renaming methods to snake_case

HM standards require snake_case for method names. When renaming, the cascade affects:

1. **Declaration** — `public function myMethod(` → `public function my_method(`
2. **Call sites** — all `->myMethod(` in the codebase
3. **Hook registrations** — `[ $this, 'myMethod' ]` callback strings
4. **Mockery expectations** — `shouldReceive('myMethod')` → `shouldReceive('my_method')`
5. **PHP named parameters** — `makeHelper(myParam: 7)` → `makeHelper(my_param: 7)`

Run in order to catch all occurrences:

```sh
grep -rn 'myMethod' includes/ admin/ cli/ tests/ performance-monitor.php
```

---

## Parameter renaming

When renaming constructor or method parameters (e.g. `$blogId` → `$blog_id`):

- Update the declaration: `private readonly int $blog_id`
- Update `$this->blog_id` references (not caught by a simple parameter rename)
- Update any named argument call sites: `fn(blog_id: $x)`

---

## Verifying clean

```sh
composer lint
```

Target: **0 errors**. Warnings from `PSR1.Files.SideEffects` and `HM.Performance.SlowMetaQuery` on admin include files are acceptable.
