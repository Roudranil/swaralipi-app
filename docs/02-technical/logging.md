---
title: Swaralipi — Logging
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Logging

## 1. Principles

- **Never `print()`** — `dart:developer log()` only (enforced by `avoid_print` lint)
- Log **why something happened**, not what the code is doing
- Log **at the catch site** — include error + stack trace always
- **No sensitive data** in logs at any level (file paths with personal content only at `debug`)
- Logs are structured: `tag | level | message [| error] [| stack]`

---

## 2. AppLogger API

Single static class. No instantiation needed.

```dart
AppLogger.debug(String tag, String message);
AppLogger.info(String tag, String message);
AppLogger.warn(String tag, String message, {Object? error, StackTrace? stackTrace});
AppLogger.error(String tag, String message, {required Object error, required StackTrace stackTrace});
```

**Rules:**
- `error` and `stackTrace` are **required** on `error()` — never log an error without both
- `warn()` takes optional error/stack — use for degraded-but-recoverable situations
- `debug()` and `info()` take no error — use only for informational checkpoints

---

## 3. Log Levels

| Level | When to use | Visible in |
|---|---|---|
| `debug` | Verbose trace; sensitive data allowed here | Debug builds only |
| `info` | Key lifecycle events (app start, DB open, screen mount) | Debug builds only |
| `warn` | Degraded operation; recoverable error | Debug + Profile |
| `error` | Unrecoverable within current operation; caught exception | Debug + Profile + Release* |

*In release: `error` logs are written to a rotating in-app log buffer (v2 feature — not in v1). In v1, `error` logs go to `dart:developer` (visible in Android logcat during development/debugging).

---

## 4. Tag Conventions

Tag = module/class identifier. Short, consistent. PascalCase.

| Tag | Used For |
|---|---|
| `App` | App startup, lifecycle |
| `DB` | Database open, migration, WAL checkpoint |
| `NotationRepo` | Notation repository operations |
| `TagRepo` | Tag repository operations |
| `InstrumentRepo` | Instrument repository operations |
| `FileStorage` | File read/write/delete |
| `ImageProc` | Image processing on isolate |
| `SearchSvc` | Search query execution |
| `LibraryVM` | Library ViewModel |
| `CaptureVM` | Capture ViewModel |
| `PlayerVM` | Player ViewModel |
| `Flutter` | Flutter framework errors (onError handler) |
| `Zone` | Unhandled zone errors |

---

## 5. What to Log

### 5.1 Always Log

| Event | Level | Example |
|---|---|---|
| App cold start | `info` | `App | cold start | v1.0.0+1` |
| DB opened + schema version | `info` | `DB | opened | schema v3` |
| DB migration ran | `info` | `DB | migrated | v2 → v3` |
| Startup auto-purge ran | `info` | `App | purged 2 notations` |
| Any caught exception | `error` | `NotationRepo | create failed | ...` |
| Camera/gallery permission denied | `warn` | `CaptureVM | camera permission denied` |
| File delete failed (best-effort) | `warn` | `FileStorage | delete failed: instruments/...` |
| Image decode error | `warn` | `ImageProc | decode failed; using placeholder` |

### 5.2 Log at Debug Only

| Event | Reason |
|---|---|
| File paths (contain notation UUIDs) | Privacy — not useful in release |
| Search query string | User content |
| Notation title at repository layer | User content |
| Notation count on list load | Verbose |

---

## 6. What Not to Log

| Data | Reason |
|---|---|
| Notation title / artist names | User PII / content |
| File paths containing personal content | Privacy |
| `RenderParams` values | Verbose, not useful |
| Widget rebuild cycles | Noise |
| `notifyListeners()` calls | Noise |
| User preferences values | Not sensitive, but noisy |

---

## 7. Release vs Debug Behaviour

| Behaviour | Debug | Profile | Release |
|---|---|---|---|
| `debug` logs emitted | Yes | No | No |
| `info` logs emitted | Yes | No | No |
| `warn` logs emitted | Yes | Yes | No |
| `error` logs emitted | Yes | Yes | Yes* |
| Visible in logcat | Yes | Yes | Yes (if USB debuggable) |

*v1: `error` logs in release go to `dart:developer` only — no remote sink, no file write. If the user reports a bug, they can capture logcat manually.

---

## 8. Implementation

```dart
// lib/core/logging/app_logger.dart

import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

abstract final class AppLogger {
  static void debug(String tag, String message) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: 500);
    }
  }

  static void info(String tag, String message) {
    if (kDebugMode) {
      dev.log(message, name: tag, level: 800);
    }
  }

  static void warn(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kReleaseMode) {
      dev.log(
        message,
        name: tag,
        level: 900,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void error(
    String tag,
    String message, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    dev.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
```

**Notes:**
- `dart:developer log()` levels: 500 = FINE, 800 = INFO, 900 = WARNING, 1000 = SEVERE — matches Android logcat filtering.
- `abstract final class`: not instantiable; all methods are static.
- `kDebugMode` / `kReleaseMode` are compile-time constants — dead code eliminated in release builds.
