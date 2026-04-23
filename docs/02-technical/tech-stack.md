---
title: Swaralipi — Tech Stack
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — Tech Stack

## Table of Contents

1. [Flutter & Dart SDK](#1-flutter--dart-sdk)
2. [Core Dependencies](#2-core-dependencies)
   1. [Database](#21-database)
   2. [State Management & DI](#22-state-management--di)
   3. [Navigation](#23-navigation)
   4. [Serialization](#24-serialization)
   5. [Storage & File System](#25-storage--file-system)
   6. [Image Processing](#26-image-processing)
   7. [Camera & Gallery](#27-camera--gallery)
   8. [UI & Theming](#28-ui--theming)
3. [Dev Dependencies](#3-dev-dependencies)
4. [pubspec.yaml Template](#4-pubspecyaml-template)
5. [Excluded Packages](#5-excluded-packages)
6. [Android Configuration](#6-android-configuration)

---

## 1. Flutter & Dart SDK

| Item | Version |
|---|---|
| Flutter channel | **stable** |
| Flutter version | ≥ 3.24.0 |
| Dart SDK | ≥ 3.5.0 |
| Min Android SDK | 26 (Android 8.0) |
| Target Android SDK | 35 (Android 15) |
| Compile SDK | 35 |

**Rationale:** Flutter 3.24+ has stable Material 3 Expressive widgets, Dart 3.5+ has full sealed class + pattern matching support.

---

## 2. Core Dependencies

### 2.1 Database

| Package | Version | Role |
|---|---|---|
| `drift` | ^2.21.0 | Type-safe SQLite ORM, reactive streams, migrations |
| `drift_flutter` | ^0.2.4 | Flutter-specific Drift setup (opens DB on correct thread) |
| `sqlite3_flutter_libs` | ^0.5.27 | Bundled SQLite 3.x — avoids Android system SQLite fragmentation |

**Why Drift:** Type-safe queries prevent schema/query drift bugs; reactive `Stream<List<T>>` integrates cleanly with `ChangeNotifier`; built-in migration DSL; FTS5 support via raw SQL with `customSelect`.

---

### 2.2 State Management & DI

| Package | Version | Role |
|---|---|---|
| `provider` | ^6.1.2 | `ChangeNotifierProvider` for ViewModel injection; `MultiProvider` at app root |

**Why provider:** Lightest wrapper around `InheritedWidget`; no code-gen; no opinion on state shape — pairs naturally with `ChangeNotifier` MVVM.

---

### 2.3 Navigation

| Package | Version | Role |
|---|---|---|
| `go_router` | ^14.6.1 | Declarative routing, `ShellRoute` for bottom nav, path params |

---

### 2.4 Serialization

| Package | Version | Role |
|---|---|---|
| `json_annotation` | ^4.9.0 | `@JsonSerializable` annotations |

**Build-time (dev):** `json_serializable` — see §3.

---

### 2.5 Storage & File System

| Package | Version | Role |
|---|---|---|
| `path_provider` | ^2.1.4 | `getApplicationDocumentsDirectory()` — app-private storage root |
| `path` | ^1.9.1 | Path joining / normalization utilities |

---

### 2.6 Image Processing

| Package | Version | Role |
|---|---|---|
| `image` | ^4.2.0 | Pure Dart image decode/encode, crop, rotate, color transforms — runs on isolate |

**Why `image` package:** Pure Dart → isolate-safe via `compute()`; no native bindings to maintain; sufficient for non-destructive pipeline on S25 hardware. Simple GPU-accelerated filters (B&W, tint) delegated to `ColorFiltered` widget — no decode needed.

---

### 2.7 Camera & Gallery

| Package | Version | Role |
|---|---|---|
| `image_picker` | ^1.1.2 | Gallery multi-select (wraps Android photo picker) |
| `camera` | ^0.11.0 | In-process camera preview (fallback; primary is intent-based) |

**Camera strategy (D-09, AQ-01 resolved):** Primary = device camera via `image_picker` with `ImageSource.camera` (single capture) + gallery picker for multi-select. For the "take multiple, then select" flow (camera intent → return → MediaStore query): use `image_picker` with gallery source after camera session; `image_picker` handles permissions cleanly. No raw `MethodChannel` needed for v1.

**Why `image_picker`:** Flutter-team maintained; handles scoped storage (Android 13+) and photo picker API automatically; avoids raw `MediaStore` query complexity.

---

### 2.8 UI & Theming

| Package | Version | Role |
|---|---|---|
| `google_fonts` | ^6.2.1 | Typography (Outfit or Lato — decided during UI phase) |
| `flutter_svg` | ^2.0.10+1 | SVG rendering (instrument icons — v2 prep; needed for any inline SVG assets) |

**No third-party icon pack** — Material Symbols (bundled with Flutter) used throughout.

---

## 3. Dev Dependencies

| Package | Version | Role |
|---|---|---|
| `build_runner` | ^2.4.12 | Code generation runner |
| `json_serializable` | ^6.8.0 | Generates `fromJson`/`toJson` for models |
| `drift_dev` | ^2.21.0 | Generates Drift DAO/table boilerplate |
| `flutter_lints` | ^5.0.0 | Lint rules (extends `flutter.yaml`) |
| `mockito` | ^5.4.4 | Mock generation for repository layer tests |
| `flutter_test` | SDK | Widget + unit testing |

---

## 4. `pubspec.yaml` Template

```yaml
name: swaralipi
description: Digitize and navigate hand-written sargam notations.
publish_to: none

version: 1.0.0+1

environment:
  sdk: '>=3.5.0 <4.0.0'
  flutter: '>=3.24.0'

dependencies:
  flutter:
    sdk: flutter

  # Database
  drift: ^2.21.0
  drift_flutter: ^0.2.4
  sqlite3_flutter_libs: ^0.5.27

  # State management & DI
  provider: ^6.1.2

  # Navigation
  go_router: ^14.6.1

  # Serialization
  json_annotation: ^4.9.0

  # Storage
  path_provider: ^2.1.4
  path: ^1.9.1

  # Image processing
  image: ^4.2.0

  # Camera & Gallery
  image_picker: ^1.1.2

  # UI
  google_fonts: ^6.2.1
  flutter_svg: ^2.0.10+1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.4.12
  json_serializable: ^6.8.0
  drift_dev: ^2.21.0
  mockito: ^5.4.4

flutter:
  uses-material-design: true
```

---

## 5. Excluded Packages

| Package | Reason |
|---|---|
| `riverpod` / `flutter_riverpod` | PRD constraint (D-02) |
| `flutter_bloc` / `bloc` | PRD constraint (D-02) |
| `get` / `getx` | PRD constraint (D-02) |
| `dio` / `http` | No network — fully offline |
| `firebase_*` | No cloud |
| `shared_preferences` | Replaced by Drift `user_preferences` table — single source of truth |
| `hive` / `isar` / `objectbox` | Drift chosen; no relational query support in NoSQL alternatives |
| `flutter_image_compress` | Destructive compression — incompatible with non-destructive pipeline |

---

## 6. Android Configuration

### 6.1 `android/app/build.gradle`

```groovy
android {
    compileSdk 35
    defaultConfig {
        minSdk 26
        targetSdk 35
    }
}
```

### 6.2 `AndroidManifest.xml` Permissions

```xml
<!-- Camera (for image_picker camera source) -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- READ_MEDIA_IMAGES: Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- READ_EXTERNAL_STORAGE: Android 12 and below (maxSdkVersion = 32) -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

**Notes:**
- `WRITE_EXTERNAL_STORAGE` not needed — writing to app-private directory requires no permission.
- `image_picker` handles runtime permission requests internally; no manual `permission_handler` needed for gallery/camera flows.

### 6.3 `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    always_use_package_imports: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_dynamic_calls: true
```
