<!-- testing-strategy.md — Swaralipi testing strategy: pyramid, scope, tooling, TDD workflow, coverage targets -->

# Swaralipi — Testing Strategy

## Table of Contents

- [1. Principles](#1-principles)
- [2. Testing Pyramid](#2-testing-pyramid)
- [3. Tooling](#3-tooling)
- [4. Directory Layout](#4-directory-layout)
- [5. Unit Tests](#5-unit-tests)
  - [5.1 Repository Layer](#51-repository-layer)
  - [5.2 ViewModel Layer](#52-viewmodel-layer)
  - [5.3 Service Layer](#53-service-layer)
  - [5.4 Domain Models](#54-domain-models)
- [6. Widget Tests](#6-widget-tests)
  - [6.1 Scope](#61-scope)
  - [6.2 Per-Feature Coverage](#62-per-feature-coverage)
  - [6.3 Shared Widget Tests](#63-shared-widget-tests)
- [7. Integration Tests](#7-integration-tests)
  - [7.1 Critical Flows](#71-critical-flows)
  - [7.2 Setup](#72-setup)
- [8. Mocking Strategy](#8-mocking-strategy)
  - [8.1 What to Mock](#81-what-to-mock)
  - [8.2 Mockito Setup](#82-mockito-setup)
  - [8.3 Drift In-Memory DB](#83-drift-in-memory-db)
- [9. TDD Workflow](#9-tdd-workflow)
- [10. Coverage Targets](#10-coverage-targets)
- [11. Test Naming & Structure](#11-test-naming--structure)
- [12. What Not to Test](#12-what-not-to-test)

---

## 1. Principles

- RED → GREEN → REFACTOR. No implementation before a failing test.
- Test **behaviour**, not implementation details.
- Mock only at layer boundaries — never mock what you own.
- Aim for fast, deterministic, isolated tests at every level.
- 80 % minimum line coverage; 100 % on all repository interfaces.

---

## 2. Testing Pyramid

```
            ┌──────────────┐
            │  Integration │  ~10 %  (critical user flows, real DB)
            ├──────────────┤
            │    Widget    │  ~30 %  (screens, key UI states)
            ├──────────────┤
            │     Unit     │  ~60 %  (repos, VMs, services, models)
            └──────────────┘
```

| Layer | Speed | Isolation | Realistic |
|---|---|---|---|
| Unit | Fast (< 1 ms each) | Full | Low |
| Widget | Medium (< 100 ms each) | Partial | Medium |
| Integration | Slow (seconds) | None | High |

---

## 3. Tooling

| Package | Role |
|---|---|
| `flutter_test` (SDK) | All unit + widget test harness |
| `integration_test` (SDK) | On-device integration tests |
| `mockito ^5.4.4` | Mock generation (`@GenerateMocks`) |
| `build_runner` | Runs `mockito` code-gen |
| `drift` in-memory mode | Real DB for repository tests |

Run tests:

```bash
# Unit + widget
flutter test

# Integration (connected device required)
flutter test integration_test/

# Coverage report
flutter test --coverage && genhtml coverage/lcov.info -o coverage/html
```

---

## 4. Directory Layout

```
test/
├── unit/
│   ├── core/
│   │   ├── database/        # DAO unit tests (in-memory Drift)
│   │   ├── storage/         # FileStorageService tests
│   │   ├── image/           # ImageProcessingService tests
│   │   └── search/          # SearchService tests
│   ├── features/
│   │   ├── library/         # LibraryViewModel, LibraryRepository
│   │   ├── capture/         # CaptureViewModel, CaptureRepository
│   │   ├── player/          # PlayerViewModel
│   │   ├── notation_detail/ # NotationDetailViewModel
│   │   ├── trash/           # TrashViewModel, TrashRepository
│   │   ├── tags/            # TagsViewModel, TagsRepository
│   │   ├── instruments/     # InstrumentsViewModel
│   │   └── custom_fields/   # CustomFieldsViewModel
│   └── shared/
│       └── models/          # copyWith, equality, serialisation
│
├── widget/
│   ├── library/
│   ├── capture/
│   ├── player/
│   ├── notation_detail/
│   └── shared/
│
├── integration_test/
│   ├── capture_flow_test.dart
│   ├── library_search_test.dart
│   └── player_flow_test.dart
│
└── helpers/
    ├── mocks.dart           # @GenerateMocks declarations + mocks.mocks.dart
    ├── fakes.dart           # Fake in-memory implementations
    └── fixtures.dart        # Shared test data builders
```

---

## 5. Unit Tests

### 5.1 Repository Layer

- Use in-memory Drift database — **never** mock the database itself.
- One test file per repository; one `group` per public method.
- Cover: happy path, empty result, constraint violations, soft-delete, restore.

```dart
// test/unit/features/library/notation_repository_test.dart
void main() {
  late AppDatabase db;
  late NotationRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = NotationRepositoryImpl(db.notationDao);
  });

  tearDown(() => db.close());

  group('NotationRepository.save', () {
    test('persists notation and returns generated id', () async { ... });
    test('throws StorageException on duplicate title+date', () async { ... });
  });

  group('NotationRepository.findAll', () {
    test('returns empty list when no notations exist', () async { ... });
    test('excludes soft-deleted rows by default', () async { ... });
    test('includes soft-deleted rows when includeDeleted = true', () async { ... });
  });
}
```

### 5.2 ViewModel Layer

- Mock all repository interfaces with `mockito`.
- Test `AsyncState` transitions: `initial → loading → data / error`.
- Verify `notifyListeners()` is called via `addListener` spy — never cast to implementation.
- Test each public method + every state branch.

```dart
// test/unit/features/library/library_viewmodel_test.dart
@GenerateMocks([NotationRepository, SearchService])
void main() {
  late MockNotationRepository mockRepo;
  late LibraryViewModel vm;

  setUp(() {
    mockRepo = MockNotationRepository();
    vm = LibraryViewModel(mockRepo);
  });

  tearDown(() => vm.dispose());

  test('loadNotations transitions through loading to data', () async {
    when(mockRepo.watchAll()).thenAnswer((_) => Stream.value(fixtures.notations));
    int notifyCount = 0;
    vm.addListener(() => notifyCount++);

    await vm.loadNotations();

    expect(vm.state, isA<Success<List<Notation>>>());
    expect(notifyCount, greaterThanOrEqualTo(2)); // loading + data
  });

  test('loadNotations emits Failure on repository error', () async {
    when(mockRepo.watchAll()).thenAnswer(
      (_) => Stream.error(StorageException('db error')),
    );

    await vm.loadNotations();

    expect(vm.state, isA<Failure>());
  });
}
```

### 5.3 Service Layer

#### 5.3.1 SearchService

- Feed synthetic `List<Notation>` — no DB required.
- Test: empty query returns all, FTS match, metadata filter, compound filter, case-insensitivity.
- Performance assertion: < 200 ms for 1 000-notation dataset.

#### 5.3.2 ImageProcessingService

- Supply known `Uint8List` fixture images.
- Assert pixel dimensions and channel values after rotate / crop / filter.
- Verify `compute()` isolate boundary is exercised (no UI thread block).

#### 5.3.3 FileStorageService

- Mock `path_provider` via dependency injection (`DirectoryResolver` abstraction).
- Use `Directory.systemTemp` for actual I/O in tests; clean up in `tearDown`.
- Cover: save, read, delete, missing-file error.

### 5.4 Domain Models

- Every model with `copyWith`: assert original unchanged + new fields applied.
- Every model with `fromJson`/`toJson`: round-trip identity test.
- `RenderParams` defaults + merge tests.

---

## 6. Widget Tests

### 6.1 Scope

Widget tests use `flutter_test`'s `WidgetTester`. Each test:

1. Pumps the widget under test wrapped in `MaterialApp` (or `MaterialApp.router`).
2. Provides a mock ViewModel via the same DI path used in production.
3. Asserts rendered output and user interaction outcomes — never internal state.

### 6.2 Per-Feature Coverage

| Feature | Must Test |
|---|---|
| **Library** | Empty state, list renders n items, filter chip tap triggers filter, search input debounce |
| **Capture** | Camera placeholder, metadata form validation errors, save button disabled when invalid, save success snackbar |
| **Notation Detail** | Title + metadata rendered, edit navigation tap |
| **Player** | Page displayed, swipe between pages, pinch-zoom gesture, chrome fade on inactivity, orientation lock toggle |
| **Trash** | Empty state, item restore tap, purge confirmation dialog |
| **Tags** | Tag list, add tag inline field, delete confirmation |
| **Instruments** | Class list, instance accordion expand, add instance tap |
| **Settings** | Theme toggle, scroll speed default displayed |

### 6.3 Shared Widget Tests

| Widget | Test |
|---|---|
| `AsyncStateBuilder` | Renders loading, data, error slots correctly |
| `NotationCard` | Title, artist, page count; tap navigates |
| `MetadataForm` | All fields present; required-field validation |
| `ConfirmationDialog` | Confirm + cancel callbacks invoked |
| `EmptyStateView` | Icon + message rendered |

---

## 7. Integration Tests

### 7.1 Critical Flows

| Test File | Flow | Assertions |
|---|---|---|
| `capture_flow_test.dart` | Gallery import → fill metadata → save → appears in library | Row in DB, file on disk, library list updated |
| `library_search_test.dart` | Type query → results filtered → clear → all restored | Correct subset rendered; 0 results empty state |
| `player_flow_test.dart` | Open notation from library → player opens → scroll starts | Player screen visible; scroll indicator active |

### 7.2 Setup

```dart
// integration_test/capture_flow_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture and save notation appears in library', (tester) async {
    await tester.pumpWidget(SwaralipiApp());
    // ... drive UI, assert end state
  });
}
```

- Integration tests run on a **physical Samsung Galaxy S25** (primary device) and Android emulator (CI).
- No mocking — real Drift DB, real file system, real `path_provider`.
- Each test creates an isolated DB instance; `tearDown` purges all rows and files.

---

## 8. Mocking Strategy

### 8.1 What to Mock

| Mock | Real in |
|---|---|
| `NotationRepository` | Unit: ViewModel tests (LibraryViewModel, CaptureViewModel, NotationDetailViewModel) |
| `SearchService` | Unit: LibraryViewModel tests |
| `FileStorageService` | Unit: service consumer tests |
| `ImageProcessingService` | Unit: CaptureViewModel tests |

**Never mock:**

- `AppDatabase` — use Drift in-memory instead.
- Domain models — use real instances from `fixtures.dart`.
- `ChangeNotifier` subclasses — test them directly.

### 8.2 Mockito Setup

```dart
// test/helpers/mocks.dart
import 'package:mockito/annotations.dart';
import 'package:swaralipi_app/shared/repositories/notation_repository.dart';
import 'package:swaralipi_app/core/search/search_service.dart';
// ... other imports

@GenerateMocks([
  NotationRepository,
  TrashRepository,
  TagsRepository,
  InstrumentsRepository,
  SearchService,
  FileStorageService,
  ImageProcessingService,
])
void main() {}
```

Regenerate after changes:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 8.3 Drift In-Memory DB

```dart
// test/helpers/fakes.dart
AppDatabase createTestDatabase() =>
    AppDatabase(NativeDatabase.memory(logStatements: false));
```

---

## 9. TDD Workflow

```
1. Write failing test  →  flutter test (expect RED)
2. Write minimal impl  →  flutter test (expect GREEN)
3. Refactor             →  flutter test (still GREEN)
4. Check coverage       →  flutter test --coverage
5. Commit               →  only when GREEN + coverage ≥ 80 %
```

- Use **tdd-guide** agent for any new feature or bug fix.
- Never commit a failing test.
- Never skip the RED step — if the test passes before implementation, the test is wrong.

---

## 10. Coverage Targets

| Scope | Target |
|---|---|
| Overall line coverage | ≥ 80 % |
| Repository interfaces | 100 % |
| ViewModel public methods | ≥ 90 % |
| Core services | ≥ 85 % |
| Shared widgets | ≥ 75 % |
| Generated files (`*.g.dart`, `*.mocks.dart`) | Excluded |

Exclude generated files in `coverage/`:

```yaml
# .coveragerc equivalent — add to flutter_test options
# Exclude from lcov report:
#   lib/**/*.g.dart
#   lib/**/*.mocks.dart
#   lib/**/*.freezed.dart
```

CI fails the build if overall coverage drops below 80 %.

---

## 11. Test Naming & Structure

**File names:** `<subject>_test.dart` — mirrors lib path exactly.

**Test name format:**

```
'<method/widget> <condition> <expected outcome>'
```

Examples:

```dart
test('loadNotations emits AsyncError when repository throws StorageException');
test('returns empty list when no notations match the FTS query');
testWidgets('save button is disabled when title field is empty');
testWidgets('filter chip tap calls onFilter with selected tag');
```

**AAA structure** inside every test:

```dart
test('...', () async {
  // Arrange
  when(mockRepo.watchAll()).thenAnswer(...);

  // Act
  await vm.loadNotations();

  // Assert
  expect(vm.state, isA<AsyncData<List<Notation>>>());
});
```

---

## 12. What Not to Test

| Skip | Reason |
|---|---|
| Generated Drift DAOs | Drift-maintained; tested upstream |
| `*.g.dart` serialisation glue | Generated; covered by model round-trip tests |
| Flutter framework widgets (`Text`, `Icon`) | Framework responsibility |
| `ThemeData` token values | No logic |
| `AppLogger` calls | Side effects; assert presence via log capture only in error-path tests |
| Private helper methods | Test through public surface |
