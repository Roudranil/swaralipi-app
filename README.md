# Swaralipi

A single-user Android app for musicians to digitize and navigate hand-written sargam notations and sheet music.

## Purpose

Swaralipi solves the problem of searching through physical notebooks of notation. It captures notation images, stores metadata (name, artist, date, time signature, key signature, language, notes), enables full-text search and filtering, and displays images with auto-scrolling support during playback.

## Tech Stack

- **Platform:** Android (Flutter 3.24+)
- **Language:** Dart (null-safe)
- **UI:** Material Design 3 (`ColorScheme.fromSeed`, dynamic color)
- **State Management:** `ChangeNotifier` + MVVM
- **Navigation:** `go_router`
- **Local Storage:** TBD (architecture phase pending)
- **Serialization:** `json_serializable`

## Device Requirements

- **Device:** Samsung Galaxy S25 (or equivalent Android 13+)
- **Storage:** Minimum 2GB free space (images + metadata)
- **Screen:** Supports portrait and landscape orientations

## Setup

### Prerequisites

- Flutter 3.24.0 or later
- Dart 3.5.0 or later
- Android SDK 33+

### Installation

```bash
# Clone the repository
git clone https://github.com/Roudranil/swaralipi-app.git
cd swaralipi-app

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Run on connected device
flutter run
```

### Development

```bash
# Format code
dart format .

# Run analysis
flutter analyze --fatal-infos --fatal-warnings

# Run tests
flutter test --coverage

# Build APK (debug)
flutter build apk --debug

# Build AAB (release)
flutter build appbundle --release
```

## Project Structure

```
lib/
├── features/          # Feature modules
├── viewmodels/        # MVVM ViewModels
├── repositories/      # Data access layer
├── data_sources/      # Local storage, API clients
├── models/           # Data models (serializable)
└── main.dart         # App entry point
```

## Coding Standards

- **Dart:** `dart format` (80-char line limit), `flutter_lints`
- **Immutability:** All state via `copyWith`, no in-place mutation
- **Null Safety:** No `!` operator except for programming errors
- **Architecture:** MVVM with Repository pattern
- **Testing:** Minimum 80% code coverage

See `CLAUDE.md` for full development workflow and code rules.

## License

Private project.
