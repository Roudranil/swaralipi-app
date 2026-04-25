# Swaralipi

A single-user Android app for musicians to digitize and navigate hand-written sargam notations and sheet music.

## Purpose

Swaralipi solves the problem of searching through physical notebooks of notation. It captures notation images, stores metadata (name, artist, date, time signature, key signature, language, notes), enables full-text search and filtering, and displays images with auto-scrolling support during playback.

---

## Tech Stack

| Layer | Choice |
|---|---|
| Platform | Android (Flutter 3.41+) |
| Language | Dart 3.11+ |
| UI | Material Design 3 (`ColorScheme.fromSeed`, dynamic color) |
| State | `ChangeNotifier` + MVVM |
| Navigation | `go_router` |
| Database | Drift (type-safe SQLite) |
| Serialization | `json_serializable` |

---

## First-Time Setup

### 1. System Requirements

| Tool | Minimum Version | Notes |
|---|---|---|
| Flutter | 3.24.0 | Must be on **stable** channel |
| Dart | 3.5.0 | Bundled with Flutter |
| Java (JDK) | 17 | Required by Gradle |
| Android SDK | API 36 (compile), API 26 (min) | Via Android Studio or `sdkmanager` |
| Android Build Tools | 36.x | |

> **Device:** Samsung Galaxy S25 or any Android 8.0+ device (API 26+).

---

### 2. Install Flutter (Arch Linux)

**Option A — Manual SDK clone (recommended):**

```bash
git clone https://github.com/flutter/flutter.git ~/flutter_sdk --depth 1 -b stable
echo 'export PATH="$HOME/flutter_sdk/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Option B — AUR:**

```bash
yay -S flutter
```

Verify:

```bash
flutter --version
# Flutter 3.41.7 • channel stable
```

---

### 3. Configure Android SDK

Set environment variables (add to `~/.zshrc`):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

Flutter looks for `adb` at `$ANDROID_HOME/platform-tools/adb`. If your `platform-tools` are installed elsewhere (e.g. `/opt/android-sdk/platform-tools/`), symlink it:

```bash
ln -sf /opt/android-sdk/platform-tools/adb "$ANDROID_HOME/platform-tools/adb"
```

Accept SDK licenses:

```bash
flutter doctor --android-licenses
```

---

### 4. Verify Toolchain

```bash
flutter doctor
```

Required green checks before proceeding:

- `[✓] Flutter`
- `[✓] Android toolchain`
- `[✓] Connected device`

Chrome and Linux toolchain warnings can be ignored — this project targets Android only.

---

### 5. Clone and Install Dependencies

```bash
git clone https://github.com/Roudranil/swaralipi-app.git
cd swaralipi-app
flutter pub get
```

---

### 6. Run Code Generation

Drift and `json_serializable` require a one-time build step to generate `.g.dart` files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Re-run this whenever you add or modify:
- Drift table definitions (`@DataClassName`, `Table` subclasses)
- `@JsonSerializable` model classes

---

### 7. Run on Device

Connect your Android device with USB debugging enabled, or start an emulator, then:

```bash
flutter run
```

To target a specific device:

```bash
flutter devices                    # list available devices
flutter run -d <device-id>
```

---

## Upgrading Flutter

This project uses a manual Flutter SDK clone. To upgrade to the latest stable:

```bash
flutter upgrade
```

After upgrading, re-run `flutter pub get` to pick up any compatibility changes.

> **Note:** Some plugins (e.g. `image_picker_android`, `flutter_plugin_android_lifecycle`) require `compileSdk ≥ 36`. If a build error reports a higher required SDK after an upgrade, bump `compileSdk` in `android/app/build.gradle.kts` to match.

---

## Development Commands

```bash
# Format all Dart files
dart format .

# Static analysis (zero warnings policy)
flutter analyze

# Run tests with coverage
flutter test --coverage

# Regenerate code-gen files
dart run build_runner build --delete-conflicting-outputs

# Build debug APK
flutter build apk --debug

# Build release AAB (requires signing config)
flutter build appbundle --release
```

---

## Project Structure

```
lib/
├── main.dart                   # App entry point
├── app.dart                    # MaterialApp.router + GoRouter
├── core/
│   ├── database/               # Drift DB, DAOs, migrations
│   ├── storage/                # FileStorageService
│   ├── image/                  # ImageProcessingService
│   ├── search/                 # SearchService
│   ├── theme/                  # ThemeData, Catppuccin tokens
│   └── logging/                # AppLogger (dart:developer wrapper)
├── features/
│   ├── library/                # Home screen, search, filter
│   ├── capture/                # Camera/gallery flow, metadata form
│   ├── notation_detail/        # Detail view
│   ├── player/                 # Full-screen playback + auto-scroll
│   ├── instruments/            # Instrument management
│   ├── tags/                   # Tag CRUD
│   ├── trash/                  # Trash + restore/purge
│   ├── custom_fields/          # User-defined metadata fields
│   └── settings/               # Preferences, appearance
└── shared/
    ├── models/                 # Immutable domain models
    ├── repositories/           # Repository interfaces
    └── widgets/                # Cross-feature UI components
```

---

## Android Configuration

| Setting | Value |
|---|---|
| `compileSdk` | 36 |
| `minSdk` | 26 (Android 8.0) |
| `targetSdk` | 35 (Android 15) |
| Application ID | `com.swaralipi.swaralipi` |

Permissions declared in `AndroidManifest.xml`:

| Permission | Purpose |
|---|---|
| `CAMERA` | In-app camera capture |
| `READ_MEDIA_IMAGES` | Gallery access on Android 13+ (API 33+) |
| `READ_EXTERNAL_STORAGE` | Gallery access on Android 12 and below (max API 32) |

---

## Coding Standards

- `dart format` on all `.dart` files, 80-char line limit
- `flutter_lints` with `avoid_print`, `prefer_single_quotes`, `always_use_package_imports`
- Immutable state — `copyWith` only, no in-place mutation
- No `!` operator except where null is a programming error
- MVVM architecture — View → ViewModel → Repository → Data source
- Minimum 80% test coverage

See `CLAUDE.md` for the full development workflow and code rules.

---

## License

Private project.
