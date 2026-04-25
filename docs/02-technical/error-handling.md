---
title: Swaralipi — Error Handling
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Error Handling

## 1. Principles

- Handle errors **explicitly at every layer** — never silently swallow
- Translate technical errors to **domain exceptions** at the repository boundary
- Present **user-friendly messages** in the UI — no stack traces, no "Exception:" prefixes
- Log **full context** (message + error + stack trace) at every catch site
- Specify **exception types** in all `on` clauses — no bare `catch (e)`
- Errors are **values**, not control flow — `AsyncState.Failure` carries the message

---

## 2. Error Taxonomy

| Category | Examples | Severity |
|---|---|---|
| DB write failure | Unique constraint violation, disk full | High |
| DB read failure | Corrupted page, migration failure | Critical |
| File I/O failure | Permission denied, disk full, file missing | High |
| Image decode failure | Corrupt JPEG, unsupported format | Medium |
| Concurrency error | Stream cancelled, ViewModel disposed mid-await | Low |
| Validation error | Empty title, invalid color hex | Low (user error) |
| Permission denied | Camera or storage permission rejected | Medium |

---

## 3. Layer-by-Layer Strategy

### 3.1 Data Source Layer

**Drift DAOs:** Drift wraps SQLite exceptions in `DriftWrappedException`. No explicit `try/catch` in DAOs — let exceptions propagate to Repository layer.

**FileStorageService:** Catch `FileSystemException` and `PathNotFoundException`; wrap in `StorageException`.

```dart
on FileSystemException catch (e, st) {
  AppLogger.error('FileStorage', 'Write failed: ${e.path}', error: e, stackTrace: st);
  throw StorageException('Failed to save file', cause: e);
}
```

### 3.2 Repository Layer

Repository is the **translation boundary**: raw infrastructure exceptions → domain exceptions.

```dart
@override
Future<void> create(Notation notation, List<NotationPage> pages) async {
  try {
    await _db.transaction(() async {
      await _dao.insertNotation(notation.toRow());
      for (final page in pages) {
        await _dao.insertPage(page.toRow());
      }
    });
  } on DriftWrappedException catch (e, st) {
    AppLogger.error('NotationRepo', 'create failed', error: e, stackTrace: st);
    throw const NotationSaveException('Could not save notation');
  }
}
```

Repositories throw only types from `lib/shared/exceptions/`.

### 3.3 ViewModel Layer

ViewModels catch domain exceptions; update `AsyncState` to `Failure`.

```dart
Future<void> saveNotation(NotationMetadata meta) async {
  _setState(Loading());
  try {
    await _repo.create(_buildNotation(meta), _pages);
    _setState(Success(_buildCaptureState()));
  } on NotationSaveException catch (e, st) {
    AppLogger.error('CaptureVM', 'save failed', error: e, stackTrace: st);
    _setState(Failure('Failed to save notation. Please try again.'));
  } on StorageException catch (e, st) {
    AppLogger.error('CaptureVM', 'file save failed', error: e, stackTrace: st);
    _setState(Failure('Not enough storage space.'));
  }
}
```

**Rule:** One `try/catch` per async operation. No nested try/catch.

### 3.4 Presentation Layer

Widgets **never catch exceptions**. They switch on `AsyncState`:

```dart
case Failure(:final message) => ErrorView(message: message),
```

For transient actions (delete, restore) that don't change primary state: use `ScaffoldMessenger.of(context).showSnackBar()` with the error message.

**`context.mounted` check after every `await`:**

```dart
await viewModel.someAction();
if (!context.mounted) return;
ScaffoldMessenger.of(context).showSnackBar(...);
```

---

## 4. Custom Exception Types

Defined in `lib/shared/exceptions/`:

```dart
// Base
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

// DB / persistence
final class NotationSaveException extends AppException {
  const NotationSaveException(super.message);
}
final class NotationNotFoundException extends AppException {
  const NotationNotFoundException(super.message);
}

// File system
final class StorageException extends AppException {
  const StorageException(super.message, {this.cause});
  final Object? cause;
}

// Image processing
final class ImageDecodeException extends AppException {
  const ImageDecodeException(super.message);
}

// Permission
final class PermissionDeniedException extends AppException {
  const PermissionDeniedException(super.message);
}

// Validation (thrown by app layer, not repositories)
final class ValidationException extends AppException {
  const ValidationException(super.message, {required this.field});
  final String field;
}
```

---

## 5. User-Facing Error Messages

| Exception | User message |
|---|---|
| `NotationSaveException` | "Failed to save. Please try again." |
| `StorageException` | "Not enough storage space." |
| `ImageDecodeException` | "Could not read this image. Try a different file." |
| `PermissionDeniedException` | "Camera access denied. Enable it in Settings." |
| `NotationNotFoundException` | "This notation no longer exists." |
| Generic unexpected | "Something went wrong. Please restart the app." |

**Rules:**
- No technical jargon in user messages
- No "Exception", "Error", "null", or stack trace fragments
- Messages end with a period
- Actionable when possible ("Enable it in Settings", "Try again")

---

## 6. Unhandled Exception Strategy

**Flutter error handler:** Override `FlutterError.onError` in `main()` to log to `AppLogger`.

```dart
FlutterError.onError = (FlutterErrorDetails details) {
  AppLogger.error(
    'Flutter',
    details.exceptionAsString(),
    error: details.exception,
    stackTrace: details.stack,
  );
  // In release: show generic error screen instead of red screen
  if (kReleaseMode) {
    // optionally navigate to ErrorScreen
  } else {
    FlutterError.dumpErrorToConsole(details);
  }
};
```

**Isolate errors:** Wrap `compute()` calls in `try/catch` at call site; treat as `ImageDecodeException` or `StorageException` as appropriate.

**Zone errors:**

```dart
runZonedGuarded(
  () => runApp(const SwaralipiApp()),
  (error, stack) {
    AppLogger.error('Zone', 'Unhandled error', error: error, stackTrace: stack);
  },
);
```

---

## 7. Error UI Patterns

| Context | Pattern |
|---|---|
| Screen-level failure (load failed) | Full-screen `ErrorView` widget with message + Retry button |
| Action failure (delete, save) | `SnackBar` with error message (auto-dismiss 4s) |
| Field validation | Inline `TextField` error text below field |
| Permission denied | Bottom sheet or inline prompt with Settings deep-link |
| Player page decode failure | Placeholder image with error icon; rest of pages still usable |

**`ErrorView` widget** (shared):
```
[Icon: warning]
[Title: "Something went wrong"]
[Body: message]
[Button: "Try again"] → calls onRetry callback
```

---

## 8. Do-Not-Do List

| Anti-pattern | Rule |
|---|---|
| `catch (e)` bare | Always `on SpecificType catch (e, st)` |
| Swallow exception silently | Always log + rethrow or update state |
| Show stack traces to user | Never |
| Throw `String` | Always throw a typed `AppException` subclass |
| Catch in widget `build()` | Never — widgets switch on state, not catch |
| Let Drift exceptions leak to ViewModel | Repository must translate at boundary |
| Skip `context.mounted` check | Always check after `await` in widgets |
