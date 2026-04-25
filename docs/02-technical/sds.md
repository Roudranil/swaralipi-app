---
title: Swaralipi — System Design Spec
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — System Design Spec

## Related Documents

| Document | Role |
|---|---|
| [PRD](../01-product/PRD.md) | Product requirements and feature acceptance criteria |
| [Data Model](./data-model.md) | Full schema, indexes, constraints, query patterns |
| [Navigation Structure](./navigation-structure.md) | Route registry, shell layout, transition specs |
| [State Management](./state-management.md) | ViewModel catalog, AsyncState, DI wiring |
| [Storage](./storage.md) | File layout, write/delete protocols, lifecycle tasks |
| [Tech Stack](./tech-stack.md) | Package list, pubspec template, Android config |
| [Error Handling](./error-handling.md) | Exception taxonomy, layer strategy, UI patterns |
| [Logging](./logging.md) | AppLogger API, levels, tag conventions |
| [Testing Strategy](./testing-strategy.md) | Pyramid, tooling, coverage targets, TDD workflow |
| [UI Spec](./ui-spec.md) | Widget choices, MD3 tokens, component patterns |
| [UX Flows](./ux-flows.md) | Screen-by-screen interaction flows |
| [CI/CD](./ci-cd.md) | Pipeline stages, quality gates, release strategy |

## 1. Context & Goals

### 1.1 Problem Statement

| Item | Value |
|---|---|
| Platform | Android (Samsung Galaxy S25, latest OS) |
| Users | 1 (single-user, no auth) |
| Data residency | On-device only |
| Network | Zero — fully offline |

### 1.2 Key Constraints

- No backend, no cloud, no auth, no multi-tenancy
- All images stored in app-private directory
- Non-destructive image edits (filters, crop applied at render time)
- Soft-delete only; 30-day retention; manual empty-trash
- ChangeNotifier / MVVM — no Riverpod, BLoC, GetX
- Material 3 + Catppuccin Mocha/Latte palette

### 1.3 Non-Functional Requirements

| Requirement | Target |
|---|---|
| Cold start | < 2 s |
| Library load (100 notations) | < 500 ms |
| Image display per page | < 300 ms |
| Search response | < 200 ms |
| Accessibility | TalkBack; 4.5:1 contrast |
| Orientation | Portrait + Landscape throughout |

---

## 2. Architecture Overview

### 2.1 Layer Diagram

```
┌──────────────────────────────────────────────────┐
│                 Presentation Layer               │
│   Screens · Widgets · GoRouter shell             │
├──────────────────────────────────────────────────┤
│               ViewModel Layer                    │
│   ChangeNotifier ViewModels · UI State DTOs      │
├──────────────────────────────────────────────────┤
│               Repository Layer                   │
│   Interfaces + Implementations                   │
│   NotationRepo · TagRepo · InstrumentRepo · ...  │
├────────────────────┬─────────────────────────────┤
│   Database Layer   │   File Storage Layer         │
│   Drift + SQLite   │   dart:io · path_provider    │
├────────────────────┴─────────────────────────────┤
│               Infrastructure Layer               │
│   ImageProcessor · SearchIndex · Logger          │
└──────────────────────────────────────────────────┘
```

### 2.2 Module Map

```
┌── core/
│   ├── database/        Drift DB definition, DAOs, migrations
│   ├── storage/         FileStorageService (disk I/O)
│   ├── image/           ImageProcessingService (filters, crop, rotate)
│   ├── search/          SearchService (in-memory index + SQLite FTS)
│   ├── theme/           ThemeData, Catppuccin tokens, ColorScheme
│   └── logging/         AppLogger (dart:developer wrapper)
│
├── features/
│   ├── library/         Home, search bar, filter sheet, sort
│   ├── capture/         Page editor, metadata form, camera bridge
│   ├── notation_detail/ Detail view
│   ├── player/          Full-screen player
│   ├── instruments/     Instrument class + instance management
│   ├── tags/            Tag CRUD
│   ├── trash/           Trash screen + restore/purge
│   ├── custom_fields/   Custom field definitions
│   └── settings/        Appearance, preferences
│
└── shared/
    ├── models/          Immutable domain models (copyWith)
    ├── repositories/    Repository interfaces
    └── widgets/         Cross-feature UI components
```

### 2.3 Directory Structure

```
lib/
├── main.dart
├── app.dart                    # MaterialApp.router + GoRouter
├── core/
│   ├── database/
│   │   ├── app_database.dart   # Drift DB class
│   │   ├── daos/
│   │   └── migrations/
│   ├── storage/
│   │   └── file_storage_service.dart
│   ├── image/
│   │   └── image_processing_service.dart
│   ├── search/
│   │   └── search_service.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── catppuccin.dart
│   └── logging/
│       └── app_logger.dart
├── features/
│   ├── library/
│   │   ├── screens/
│   │   ├── viewmodels/
│   │   └── widgets/
│   ├── capture/
│   │   ├── screens/
│   │   ├── viewmodels/
│   │   └── widgets/
│   ├── notation_detail/
│   ├── player/
│   ├── instruments/
│   ├── tags/
│   ├── trash/
│   ├── custom_fields/
│   └── settings/
└── shared/
    ├── models/
    ├── repositories/
    └── widgets/
```

---

## 3. Layer Design

### 3.1 Presentation Layer

**Responsibilities:**
- Render UI from ViewModel state
- Forward user events to ViewModel
- No business logic, no direct DB/file access

**Rules:**
- `StatelessWidget` subclasses; no inline helper methods for widget composition
- Observe via `ListenableBuilder` or `ChangeNotifierProvider` (from `provider` package)
- `ListView.builder` / `SliverList` for all lists
- `const` constructors everywhere possible
- Check `context.mounted` after every `await`

### 3.2 ViewModel Layer

**Responsibilities:**
- Hold UI state as immutable DTOs
- Execute use-case logic (orchestrate repository calls)
- Emit state changes via `notifyListeners()`
- Handle loading / error / data states via sealed classes

**Rules:**
- Extends `ChangeNotifier`
- State exposed as sealed class: `Idle | Loading | Success(data) | Error(message)`
- No `BuildContext` references
- Injected repositories via constructor (manual DI)
- Dispose repositories only if ViewModel owns them

### 3.3 Repository Layer

**Responsibilities:**
- Abstract data source from business logic
- Translate DB row ↔ domain model
- Enforce soft-delete filtering by default

**Rules:**
- Defined as abstract class (interface); concrete class injected at app start
- Returns domain models, never raw DB rows or JSON
- All write operations return `void` or the newly persisted model
- All list reads return `Stream<List<T>>` or `Future<List<T>>`

**Repositories:**

| Repository | Responsibilities |
|---|---|
| `NotationRepository` | CRUD, soft-delete, play-count, duplicate |
| `NotationPageRepository` | Page CRUD within a notation |
| `TagRepository` | Tag CRUD, assign/remove from notation |
| `InstrumentRepository` | Class + instance CRUD, archive |
| `CustomFieldRepository` | Definition CRUD |
| `TrashRepository` | List deleted items, restore, purge |
| `PreferencesRepository` | Read/write `UserPreferences` |

### 3.4 Data Source Layer

**Responsibilities:**
- Drift DAOs: typed SQL queries, migrations
- `FileStorageService`: all disk I/O for images

**Rules:**
- DAOs return Drift table rows; repositories translate to domain models
- No business logic inside DAOs
- All file paths computed by `FileStorageService`; never hard-coded elsewhere

### 3.5 Infrastructure Layer

**Responsibilities:**
- `ImageProcessingService`: apply filters/crop/rotate in memory at render time
- `SearchService`: build and query search index
- `AppLogger`: structured logging via `dart:developer`

**Rules:**
- No dependencies on Flutter widgets
- Stateless where possible; stateful services are singletons injected at startup

---

## 4. State Management

### 4.1 Pattern

**MVVM + ChangeNotifier.** Manual constructor-based dependency injection.

```
UserAction → ViewModel.method() → Repository → DB/File
                ↓ notifyListeners()
           ListenableBuilder rebuilds View
```

### 4.2 State Flow

Each ViewModel exposes one primary state sealed class:

```dart
sealed class AsyncState<T> {
  const AsyncState();
}
final class Idle<T>    extends AsyncState<T> { const Idle(); }
final class Loading<T> extends AsyncState<T> { const Loading(); }
final class Success<T> extends AsyncState<T> { const Success(this.data); final T data; }
final class Failure<T> extends AsyncState<T> { const Failure(this.message); final String message; }
```

Switch on this at the widget layer — exhaustive, no `default` wildcard.

### 4.3 ViewModel Lifecycle

- Created by screen widget, passed down via `InheritedWidget` or `provider`
- Disposed when screen is removed from navigation stack
- Repositories are not disposed by ViewModel (app-lifetime singletons)

---

## 5. Navigation

### 5.1 Route Table

`go_router` with `ShellRoute` for bottom nav.

| Route | Path | Screen |
|---|---|---|
| Library (shell) | `/` | `LibraryScreen` |
| Settings (shell) | `/settings` | `SettingsScreen` |
| Appearance | `/settings/appearance` | `AppearanceScreen` |
| Add Notation | `/capture` | `CaptureEntrySheet` (bottom sheet) |
| Page Editor | `/capture/editor` | `PageEditorScreen` |
| Metadata Form | `/capture/metadata` | `MetadataFormScreen` |
| Notation Detail | `/notation/:id` | `NotationDetailScreen` |
| Player | `/notation/:id/player` | `PlayerScreen` |
| Tags | `/settings/tags` | `TagsScreen` |
| Instruments | `/settings/instruments` | `InstrumentsScreen` |
| Instrument Detail | `/settings/instruments/:id` | `InstrumentDetailScreen` |
| Trash | `/settings/trash` | `TrashScreen` |
| Custom Fields | `/settings/custom-fields` | `CustomFieldsScreen` |

### 5.2 Deep Links

- Not required for v1 (single-user, no sharing)
- Route structure is deep-link-ready for v2 if needed

---

## 6. Core Services

### 6.1 Database Service

- **Engine:** Drift (type-safe SQLite wrapper)
- **Location:** `AppDatabase` singleton; passed to all DAOs
- **Migration:** Drift `MigrationStrategy` with numbered schema versions
- **FTS:** SQLite FTS5 virtual table on `notations(title, artists, notes)`

### 6.2 File Storage Service

- **Root:** `getApplicationDocumentsDirectory()` via `path_provider`
- **Structure:**
  ```
  <appDocDir>/
  └── notations/
      └── <notation_id>/
          ├── page_1_original.jpg
          ├── page_2_original.jpg
          └── ...
  ```
- **Rules:**
  - Original images never mutated after write
  - Thumbnail cache managed separately (v2)
  - On notation delete (soft): files retained; on trash purge: files deleted

### 6.3 Image Processing Service

- Applies non-destructive transforms at render time (filter, crop, rotate)
- Input: original image `Uint8List` + per-page `RenderParams`
- Output: transformed `Uint8List` for display
- Runs on isolate via `compute()` to avoid UI jank
- **Library:** `image` (pub.dev) for filter/crop/rotate operations

**Two rendering contexts:**

| Context | Strategy | Reason |
|---|---|---|
| Page Editor preview | `ColorFiltered` widget (GPU) for simple filters; `image` package + `compute()` for crop/rotate | Fast interactive preview; no full decode for filter-only changes |
| Notation Player | `ImageProcessingService.apply()` via `compute()` always — full RenderParams applied | Player needs final pixel-accurate output; GPU widget not sufficient for composite transforms |

Simple filters (B&W, grayscale, tint) in the Editor never call `ImageProcessingService`; they use `ColorFiltered` for zero-decode cost. In the Player, all pages are fully decoded and all RenderParams applied before display.

### 6.4 Search Service

**Two-phase search:**

| Phase | Mechanism | When |
|---|---|---|
| FTS | SQLite FTS5 full-text on title, artists, notes | Primary text search |
| In-memory filter | Dart-side predicate on returned list | Tags, language, time sig, key sig, date range |

Search pipeline:

```
query → FTS5 query → result set → apply metadata filters → sort → emit
```

**Performance target:** < 200 ms on 1000 notations.

### 6.5 Logging Service

```dart
// Wrapper around dart:developer log()
// Never use print() in production code
AppLogger.info(tag, message, {Object? error, StackTrace? stackTrace});
AppLogger.warn(...);
AppLogger.error(...);
```

Log levels: `debug | info | warn | error`
Sensitive data (file paths with personal content): logged at `debug` only, stripped in release builds.

---

## 7. Data Flow — Critical Paths

### 7.1 Capture & Save Notation

```
FAB tap
  → bottom sheet: Gallery / Camera
  → [Gallery] system photo picker → multi-select
  → [Camera] record timestamp → launch camera intent
             → user returns → MediaStore query (date_added ≥ timestamp)
             → selection screen
  → selected images → PageEditorScreen
      ├── per-page: filter / crop / rotate stored as RenderParams (not baked in)
      ├── reorder / add page / delete page
      └── Save (top bar)
  → MetadataFormScreen
      └── fill required (Title) + optional fields
      └── Save
  → NotationRepository.create(notation, pages)
      ├── DB: insert Notation row
      ├── DB: insert NotationPage rows
      ├── FileStorageService: copy originals to <appDocDir>/notations/<id>/
      └── DB: insert Tag associations
  → navigate to LibraryScreen (pop to root)
  → LibraryViewModel reloads list
```

### 7.2 Library Load + Search

```
LibraryScreen mounts
  → LibraryViewModel.init()
  → NotationRepository.watchAll()  ← Drift reactive stream
  → stream emits List<Notation> sorted by default_sort
  → ListenableBuilder rebuilds list

User types in search bar (debounce 200 ms)
  → LibraryViewModel.search(query, filters)
  → SearchService.query(query, filters)
      ├── FTS5 match on (title, artists, notes)
      └── Dart filter: tags ∩, languages ∩, date range, time_sig, key_sig
  → emit filtered + sorted List<Notation>
  → rebuild list
```

### 7.3 Player Launch

```
NotationDetailScreen → Play button
  → navigate to /notation/:id/player
  → PlayerViewModel.init(notationId)
  → NotationPageRepository.getPagesForNotation(id)  → List<NotationPage>
  → for each page:
      FileStorageService.readOriginal(page.imagePath)  → Uint8List
      ImageProcessingService.apply(bytes, page.renderParams)  → Uint8List
         [runs on isolate via compute()]
  → pages ready → PageView renders
  → NotationRepository.incrementPlayCount(id)
     + NotationRepository.setLastPlayedAt(id, now)
```

---

## 8. Technology Selection

### 8.1 Local Database

| Option | Pros | Cons |
|---|---|---|
| `sqflite` (raw SQLite) | Minimal deps | No type safety; verbose queries |
| **`drift`** (type-safe SQLite) | Type-safe; reactive streams; migrations; FTS5 | Code-gen step |
| `isar` | Fast; NoSQL; Dart-native | No SQL joins; less relational |
| `objectbox` | High perf NoSQL | License; no SQL |

**Decision: `drift`.** Relational data, complex filter queries, FTS5, migration support. Code-gen cost is acceptable.

### 8.2 Image Storage

**Decision: App-private `getApplicationDocumentsDirectory()`.** Files survive app updates; not visible to other apps; no permissions needed (Android 10+).

### 8.3 State Management

**Decision: `ChangeNotifier` + `provider` package.** Matches PRD constraint. Simple, auditable, no code-gen. `provider` used only for ViewModel injection — not for global state sharing.

### 8.4 Navigation

**Decision: `go_router`.** Declarative; supports `ShellRoute` for bottom nav; path-based; deep-link-ready.

### 8.5 Image Rendering & Filters

| Option | Pros | Cons |
|---|---|---|
| **`image` package** | Pure Dart; no native code; isolate-safe | Slower than native for large images |
| `flutter_image_compress` | Fast (native) | Destructive — not suitable for non-destructive pipeline |
| Custom `dart:ui` / `Canvas` | Full control | High complexity |

**Decision: `image` package for filter/crop/rotate transforms.** Non-destructive pipeline runs on isolate via `compute()`. For display, use `ColorFiltered` + `ClipRect` widgets where GPU-accelerated is sufficient (B&W, tint filters → `ColorFilter`; crop → `ClipRect`; rotate → `Transform.rotate`).

Hybrid approach:
- Simple filters (B&W, tint, grayscale): `ColorFiltered` widget — zero decode cost
- Crop / rotate: `image` package + `compute()` — stored as `RenderParams`, applied lazily

### 8.6 Camera Integration

**Decision (D-09):** Device camera intent + `MediaStore` timestamp query.

- `android_intent_plus` or direct `MethodChannel` for camera intent
- `photo_manager` or direct `ContentResolver` query for MediaStore
- Implementation detail deferred to capture feature task (D-17)

---

## 9. Non-Functional Design

### 9.1 Performance

| Target | Strategy |
|---|---|
| Cold start < 2 s | Lazy-init repositories; defer non-critical services |
| Library load < 500 ms | Drift reactive stream; paginate at 50 items; thumbnails async |
| Image display < 300 ms | Pre-decode on isolate; simple filters via `ColorFiltered` widget |
| Search < 200 ms | FTS5 index + Dart-side filter; debounce 200 ms |

**Pagination:** `LibraryScreen` loads first 50 notations; auto-loads more on scroll (infinite scroll via `SliverList`).

**Thumbnail strategy (v1):** Render originals at reduced resolution using Flutter's `ResizeImage`. No separate thumbnail file.

### 9.2 Offline Guarantee

- Zero network calls. No `http`, `dio`, or any network package in dependency tree.
- `NetworkImage` never used — all images loaded from disk via `FileImage`.

### 9.3 Orientation Support

- `MaterialApp` supports both orientations globally
- `PlayerScreen` allows forced orientation toggle (portrait ↔ landscape) via `SystemChrome.setPreferredOrientations()`
- Layouts use `LayoutBuilder` for responsive breakpoints where needed

### 9.4 Accessibility

- All interactive elements wrapped in `Semantics` with `label`
- `Semantics.button: true` on FAB and action buttons
- Minimum 4.5:1 contrast enforced via Catppuccin token selection
- TalkBack tested on Samsung Galaxy S25

---

## 10. Risks & Open Questions

### 10.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Camera intent + MediaStore query unreliable on One UI | Medium | High | Spike: test on S25 early; fallback to `image_picker` |
| `image` package too slow for large scans on isolate | Low | Medium | Benchmark on S25; fallback to `flutter_image_compress` for crop/rotate |
| Drift code-gen adds friction | Low | Low | One-time setup; `build_runner watch` in dev |
| FTS5 search slow on 1000+ notations | Low | Medium | Add index; measure; paginate search results |
| Non-destructive filter pipeline complex to implement | Medium | Medium | Define `RenderParams` schema clearly; isolate behind `ImageProcessingService` |

### 10.2 Open Questions

| ID | Question | Owner | Resolution Path |
|---|---|---|---|
| AQ-01 | Camera integration: `android_intent_plus` vs raw `MethodChannel`? | Architect | Spike on S25 before capture feature starts |
| AQ-02 | Instrument reference integrity on notation delete? (D-30) | Architect | Decision needed: RESTRICT vs SET NULL vs soft-link |
| AQ-03 | Thumbnail caching strategy for library performance? | Architect | Benchmark with `ResizeImage` on 100 notations; decide before implementation |
| AQ-04 | FTS5 porter stemmer for multilingual (Hindi, Bengali) support? | Architect | FTS5 `unicode61` tokenizer may suffice; test with sample data |

---

## 11. Architecture Decision Records

### ADR-01: Drift (type-safe SQLite) as local database

- **Status:** Accepted
- **Context:** Relational data model (Notation → NotationPage, M:N Tags, M:N Instruments), complex filter queries, FTS5 text search, migration support required.
- **Decision:** Use `drift` package.
- **Options considered:** `sqflite` (raw), `isar` (NoSQL), `objectbox` (NoSQL).
- **Tradeoffs:** Code-gen overhead accepted for type safety and reactive streams.

---

### ADR-02: ChangeNotifier MVVM (no Riverpod/BLoC)

- **Status:** Accepted (PRD constraint D-02)
- **Context:** PRD mandates ChangeNotifier / ValueNotifier + MVVM.
- **Decision:** `ChangeNotifier` ViewModels; `provider` for injection only.
- **Tradeoffs:** Less reactive power than Riverpod; simpler mental model.

---

### ADR-03: Non-destructive image pipeline via RenderParams

- **Status:** Accepted (PRD constraint D-06)
- **Context:** Filters, crop, rotate must not mutate originals.
- **Decision:** Store `RenderParams` (filter enum, crop rect, rotation) per `NotationPage`; apply at render time via `ImageProcessingService` on isolate.
- **Tradeoffs:** CPU cost per page view; offset by `ColorFiltered` widget for simple filters.

---

### ADR-04: go_router with ShellRoute

- **Status:** Accepted
- **Context:** Bottom nav (Library + Settings), nested routes, future deep-link readiness.
- **Decision:** `go_router` with `ShellRoute` for bottom nav shell.
- **Tradeoffs:** More setup than `Navigator.push`; gains declarative routing.

---

### ADR-05: App-private document directory for image storage

- **Status:** Accepted (PRD §8)
- **Context:** Images must be private, survive app updates, require no permissions on Android 10+.
- **Decision:** `getApplicationDocumentsDirectory()` via `path_provider`.
- **Tradeoffs:** Not accessible to gallery apps; acceptable (images are app-managed).

---

### ADR-06: Feature-based module organization

- **Status:** Accepted
- **Context:** Multiple distinct feature areas (library, capture, player, instruments, tags, trash, settings). Each has its own screen, ViewModel, and widgets.
- **Decision:** `features/<feature>/` grouping with `screens/`, `viewmodels/`, `widgets/` sub-dirs. Shared code in `shared/`.
- **Tradeoffs:** Slight duplication of small widgets; gains clear ownership boundaries.

---

### ADR-07: Hybrid filter rendering (ColorFiltered widget + image package)

- **Status:** Accepted
- **Context:** Six filter types required; some map to GPU-accelerated widget transforms; others require pixel-level processing.
- **Decision:** Simple filters (B&W, grayscale, tint) → `ColorFiltered` widget. Crop/rotate → `image` package on isolate.
- **Tradeoffs:** Two code paths; isolates required for crop/rotate path.
