---
title: Swaralipi — CI/CD Strategy
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — CI/CD Strategy

## Table of Contents

1. [Overview](#1-overview)
2. [Pipeline Stages](#2-pipeline-stages)
3. [GitHub Actions Workflows](#3-github-actions-workflows)
   1. [PR Check Workflow](#31-pr-check-workflow)
   2. [Build & Release Workflow](#32-build--release-workflow)
4. [Code Quality Gates](#4-code-quality-gates)
5. [Build Configuration](#5-build-configuration)
6. [Release Strategy](#6-release-strategy)
7. [Versioning](#7-versioning)
8. [Secrets & Environment](#8-secrets--environment)

---

## 1. Overview

| Item | Choice |
|---|---|
| CI platform | GitHub Actions |
| Target | Android APK / AAB only |
| Distribution | Direct APK install (sideload); no Play Store in v1 |
| Trigger: PR | Analyze + test + build check |
| Trigger: main push | Full build + draft release artifact |
| Flutter version mgmt | `flutter-version` pinned in workflow |

**No iOS.** Single-user Android app on S25.

---

## 2. Pipeline Stages

```
PR opened / updated
  │
  ├── 1. Checkout + Setup Flutter
  ├── 2. flutter pub get
  ├── 3. dart format --output=none --set-exit-if-changed .
  ├── 4. flutter analyze --fatal-infos --fatal-warnings
  ├── 5. build_runner build (code-gen check)
  ├── 6. flutter test --coverage
  ├── 7. coverage threshold check (≥ 80%)
  └── 8. flutter build apk --debug (build sanity check)

Push to main
  │
  ├── 1-7 (same as PR)
  └── 8. flutter build appbundle --release
      └── 9. Upload AAB as GitHub Release artifact (draft)
```

---

## 3. GitHub Actions Workflows

### 3.1 PR Check Workflow

**File:** `.github/workflows/pr-check.yml`

```yaml
name: PR Check

on:
  pull_request:
    branches: [main]

jobs:
  check:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Check formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test --coverage --reporter=github

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | tr -d '%')
          echo "Coverage: ${COVERAGE}%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage ${COVERAGE}% is below 80% threshold"
            exit 1
          fi

      - name: Build APK (debug)
        run: flutter build apk --debug
```

### 3.2 Build & Release Workflow

**File:** `.github/workflows/release.yml`

```yaml
name: Release Build

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      version_bump:
        description: 'Version bump type (patch|minor|major)'
        required: false
        default: 'patch'

jobs:
  release:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Analyze
        run: flutter analyze --fatal-infos --fatal-warnings

      - name: Run code generation
        run: dart run build_runner build --delete-conflicting-outputs

      - name: Run tests
        run: flutter test --coverage

      - name: Build release AAB
        run: flutter build appbundle --release

      - name: Build release APK
        run: flutter build apk --release --split-per-abi

      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: swaralipi-release-${{ github.sha }}
          path: |
            build/app/outputs/bundle/release/app-release.aab
            build/app/outputs/apk/release/app-arm64-v8a-release.apk
          retention-days: 30
```

---

## 4. Code Quality Gates

All gates are **blocking** (PR cannot merge if any fails):

| Gate | Tool | Threshold |
|---|---|---|
| Formatting | `dart format` | Zero diff |
| Static analysis | `flutter analyze` | Zero warnings, zero infos |
| Tests pass | `flutter test` | 100% pass rate |
| Coverage | `lcov` | ≥ 80% line coverage |
| Build succeeds | `flutter build apk --debug` | Exit code 0 |
| Code generation is committed | `build_runner build` | No uncommitted generated files |

**Generated files policy:** `.g.dart` and `.drift.dart` files are committed to the repo. CI verifies they are up-to-date by running `build_runner` and checking for git diff.

---

## 5. Build Configuration

### 5.1 Build Flavors

v1 has two build modes only — no separate dev/staging/prod flavors (single-user, no backend):

| Mode | Command | Use |
|---|---|---|
| Debug | `flutter build apk --debug` | Local dev + CI PR check |
| Release | `flutter build apk --release --split-per-abi` | Sideload install |

### 5.2 Release APK Signing

For v1 sideload install:
- **Debug signing** acceptable (no Play Store)
- In v2 (if Play Store): keystore configured via GitHub Secrets + `key.properties`

### 5.3 ABI Splitting

`--split-per-abi` produces separate APKs for `arm64-v8a`, `armeabi-v7a`, `x86_64`. S25 uses `arm64-v8a`. Install the `arm64-v8a` APK directly.

---

## 6. Release Strategy

**v1: Sideload via USB or direct APK download.**

| Step | Action |
|---|---|
| Tag commit | `git tag v1.0.0` |
| Trigger | Push tag → `release.yml` runs |
| Artifact | `app-arm64-v8a-release.apk` uploaded to GitHub Releases |
| Install | Download APK → install on S25 via USB or browser |

No Play Store, no TestFlight, no MDM.

---

## 7. Versioning

Format: `MAJOR.MINOR.PATCH+BUILD` (Flutter pubspec standard).

| Field | Meaning |
|---|---|
| `MAJOR` | Breaking data model change (migration) |
| `MINOR` | New feature |
| `PATCH` | Bug fix |
| `BUILD` | Auto-incremented by CI (GitHub run number) |

**In `pubspec.yaml`:**
```yaml
version: 1.0.0+1
```

Build number injected by CI:
```bash
flutter build appbundle --release --build-number=${{ github.run_number }}
```

---

## 8. Secrets & Environment

**No runtime secrets.** App is fully offline; no API keys, no tokens.

**CI-only:**

| Secret | Purpose |
|---|---|
| None in v1 | No signing, no distribution service |

If Play Store is added in v2:
- `KEYSTORE_FILE` (base64-encoded keystore)
- `KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`
- All stored in GitHub repository secrets; never in source
