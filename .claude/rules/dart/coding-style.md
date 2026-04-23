---
paths:
    - "**/*.dart"
    - "**/pubspec.yaml"
    - "**/analysis_options.yaml"
---

# Dart/Flutter Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Dart and Flutter-specific content.

## Formatting

- **dart format** for all `.dart` files — enforced in CI (`dart format --set-exit-if-changed .`)
- Line length: 80 characters (dart format default)
- Trailing commas on multi-line argument/parameter lists to improve diffs and formatting

## Immutability

- Prefer `final` for local variables and `const` for compile-time constants
- Use `const` constructors wherever all fields are `final`
- Return unmodifiable collections from public APIs (`List.unmodifiable`, `Map.unmodifiable`)
- Use `copyWith()` for state mutations in immutable state classes

```dart
// BAD
var count = 0;
List<String> items = ['a', 'b'];

// GOOD
final count = 0;
const items = ['a', 'b'];
```

## Naming

Follow Dart conventions:

- `camelCase` for variables, parameters, and named constructors
- `PascalCase` for classes, enums, typedefs, and extensions
- `snake_case` for file names and library names
- `SCREAMING_SNAKE_CASE` for constants declared with `const` at top level
- Prefix private members with `_`
- Extension names describe the type they extend: `StringExtensions`, not `MyHelpers`

## Null Safety

- Avoid `!` (bang operator) — prefer `?.`, `??`, `if (x != null)`, or Dart 3 pattern matching; reserve `!` only where a null value is a programming error and crashing is the right behaviour
- Avoid `late` unless initialization is guaranteed before first use (prefer nullable or constructor init)
- Use `required` for constructor parameters that must always be provided

```dart
// BAD — crashes at runtime if user is null
final name = user!.name;

// GOOD — null-aware operators
final name = user?.name ?? 'Unknown';

// GOOD — Dart 3 pattern matching (exhaustive, compiler-checked)
final name = switch (user) {
  User(:final name) => name,
  null => 'Unknown',
};

// GOOD — early-return null guard
String getUserName(User? user) {
  if (user == null) return 'Unknown';
  return user.name; // promoted to non-null after the guard
}
```

## Sealed Types and Pattern Matching (Dart 3+)

Use sealed classes to model closed state hierarchies:

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.error);
  final Object error;
}
```

Always use exhaustive `switch` with sealed types — no default/wildcard:

```dart
// BAD
if (state is Loading) { ... }

// GOOD
return switch (state) {
  Loading() => const CircularProgressIndicator(),
  Success(:final data) => DataWidget(data),
  Failure(:final error) => ErrorWidget(error.toString()),
};
```

## Error Handling

- Specify exception types in `on` clauses — never use bare `catch (e)`
- Never catch `Error` subtypes — they indicate programming bugs
- Use `Result`-style types or sealed classes for recoverable errors
- Avoid using exceptions for control flow

```dart
// BAD
try {
  await fetchUser();
} catch (e) {
  log(e.toString());
}

// GOOD
try {
  await fetchUser();
} on NetworkException catch (e) {
  log('Network error: ${e.message}');
} on NotFoundException {
  handleNotFound();
}
```

## Async / Futures

- Always `await` Futures or explicitly call `unawaited()` to signal intentional fire-and-forget
- Never mark a function `async` if it never `await`s anything
- Use `Future.wait` / `Future.any` for concurrent operations
- Check `context.mounted` before using `BuildContext` after any `await` (Flutter 3.7+)

```dart
// BAD — ignoring Future
fetchData(); // fire-and-forget without marking intent

// GOOD
unawaited(fetchData()); // explicit fire-and-forget
await fetchData();      // or properly awaited
```

## Imports

- Use `package:` imports throughout — never relative imports (`../`) for cross-feature or cross-layer code
- Order: `dart:` -> external `package:` -> internal `package:` (same package)
- No unused imports — `dart analyze` enforces this with `unused_import`

## Code Generation

- Generated files (`.g.dart`, `.freezed.dart`, `.gr.dart`) must be committed or gitignored consistently — pick one strategy per project
- Never manually edit generated files
- Keep generator annotations (`@JsonSerializable`, `@freezed`, `@riverpod`, etc.) on the canonical source file only

## Docstring Style Guide

Following are rules for writing docstrings (and templates) that align with Flutter SDK and Dartdoc conventions. Your output MUST adhere to the rules and templates defined below. These rules are mandatory and override stylistic freedom.

### General Rules

- Use `///` for all documentation comments.
- Write in third-person, present tense (e.g., “Creates”, “Returns”, “Represents”).
- Use complete, grammatically correct sentences.
- Keep the first line to a single concise summary sentence.
- Use short paragraphs separated by blank `///` lines.
- Do NOT use Markdown headings (`#`, `##`, etc.) inside doc comments.
- Avoid redundant type restatement unless it adds semantic value.
- Reference parameters, fields, methods, and types using square brackets
  (e.g., [value], [AccountType]).
- Documentation must be safe for Dartdoc HTML generation.
- Inline parameter comments MAY be used for IDE support but MUST NOT replace
  method-level parameter documentation for public APIs.
- Prefer clarity and explicitness over brevity for public-facing APIs.

### Method / Function Docstring Template

/// <One-sentence summary of what the method does.>
///
/// <Optional paragraph describing behavior, side effects, lifecycle, or
/// invariants. Reference parameters using [parameterName] where relevant.>
///
/// Returns <description of the return value>.
///
/// Parameters:
/// - [paramName]: <Description>.
/// - [paramName]: <Description>. Defaults to `<defaultValue>`.
/// - [paramName]: <Description>. Valid range: <constraints>.

Example:

/// Creates a new account and persists it to the database.
///
/// The account is initialized with [initialBalance], which is also used as the
/// initial value for the current balance.
///
/// Returns the unique identifier of the newly created account.
///
/// Parameters:
/// - [name]: The display name of the account.
/// - [type]: The type of account.
/// - [initialBalance]: The starting balance.
/// - [currencyCode]: ISO 4217 currency code. Defaults to `'INR'`.

### Class Docstring Template

Template:

/// <One-sentence summary describing the responsibility of the class.>
///
/// <Optional paragraph describing usage context, lifecycle, or invariants.>
///
/// <Optional paragraph describing interactions with other components.>

Example:

/// Represents a financial account tracked by the application.
///
/// An account maintains balances, currency information, and metadata used for
/// reporting and net worth calculations.

### Constructor Docstring Template

Template:

/// Creates a new instance of [ClassName].
///
/// <Optional description of initialization behavior or constraints.
///
/// Parameters:
/// - [paramName]: <Description>.
/// - [paramName]: <Description>. Must not be null.

### Property / Field Docstring Template

Template:

/// <Description of what this field represents.>
///
/// <Optional constraints, units, or lifecycle notes.>

Example:

/// The current balance of the account.
///
/// This value is updated as transactions are applied.

### Enum Docstring Template

Template:

/// <One-sentence description of what the enum represents.>
enum EnumName {
/// <Description of this value.>
valueOne,

/// <Description of this value.>
valueTwo,
}

### Getter Docstring Template

Template:

/// <Description of the derived or exposed value.>
///
/// <Optional explanation of how the value is computed.>

### Setter Docstring Template

Template:

/// Sets the <property name>.
///
/// <Optional validation rules or side effects.>

### Mixin Docstring Template

Template:

/// <Description of shared behavior provided by this mixin.>
///
/// <Optional constraints on classes that may apply this mixin.>

### Extension Docstring Template

Template:

/// <Description of the functionality added by this extension.>
///
/// <Optional usage notes or examples.>

### Top-Level Constant / Variable Docstring Template

Template:

/// <Description of the constant or variable.>
///
/// <Optional usage notes or constraints.>

### Final Enforcement Rule

If a public API element (class, method, constructor, field, enum, extension,
mixin, or constant) can have a docstring, it MUST have one written using the
appropriate template above. Failure to do so is considered incorrect output.
