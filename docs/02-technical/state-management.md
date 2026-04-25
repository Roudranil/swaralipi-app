---
title: Swaralipi — State Management
version: 0.1.0
status: draft
owner: architect
date: 2026-04-23
---

# Swaralipi — State Management

## 1. Pattern Overview

**MVVM + ChangeNotifier + provider.**

```
View (StatelessWidget)
  └── ListenableBuilder / Consumer<ViewModel>
        ↑ rebuild on notifyListeners()
ViewModel (ChangeNotifier)
  └── calls Repository methods
        └── returns Future<T> or Stream<List<T>>
Repository (abstract class)
  └── implemented by DriftRepository
        └── calls Drift DAO
```

**No shared global state.** Each screen owns its ViewModel. State does not flow upward between screens. Cross-screen updates are handled by Drift reactive streams (both screens listen to the same DB table stream; DB write triggers both).

---

## 2. AsyncState Sealed Class

Defined once in `lib/shared/models/async_state.dart`; used by all ViewModels.

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

final class Idle<T> extends AsyncState<T> {
  const Idle();
}

final class Loading<T> extends AsyncState<T> {
  const Loading();
}

final class Success<T> extends AsyncState<T> {
  const Success(this.data);
  final T data;
}

final class Failure<T> extends AsyncState<T> {
  const Failure(this.message, {this.error});
  final String message;
  final Object? error;
}
```

**Switch at widget layer — exhaustive, no default:**

```dart
switch (state) {
  case Idle() => const SizedBox.shrink(),
  case Loading() => const CircularProgressIndicator(),
  case Success(:final data) => NotationList(items: data),
  case Failure(:final message) => ErrorView(message: message),
}
```

---

## 3. ViewModel Contract

All ViewModels follow this structure:

| Member | Type | Purpose |
|---|---|---|
| `state` | `AsyncState<T>` | Primary UI state |
| `init()` | `Future<void>` | Called once on screen mount |
| `dispose()` | `void` | Called by `provider` on screen removal |
| `_setState(AsyncState<T>)` | private | Updates `state` + calls `notifyListeners()` |

**Error handling inside ViewModels:**

```
try {
  _setState(Loading());
  final result = await repository.method();
  _setState(Success(result));
} on SpecificException catch (e, st) {
  AppLogger.error('ViewModel', e.toString(), error: e, stackTrace: st);
  _setState(Failure('User-facing message'));
}
```

Never bare `catch (e)`. Always name the exception type. Always log with stack trace. User-facing message is distinct from internal error.

---

## 4. Dependency Injection

Repositories are app-lifetime singletons. Injected at `main.dart` root via `MultiProvider`.

```dart
// main.dart
runApp(
  MultiProvider(
    providers: [
      Provider<AppDatabase>(create: (_) => AppDatabase()),
      Provider<NotationRepository>(
        create: (ctx) => DriftNotationRepository(ctx.read<AppDatabase>()),
      ),
      Provider<TagRepository>(
        create: (ctx) => DriftTagRepository(ctx.read<AppDatabase>()),
      ),
      // ... all repositories
    ],
    child: const SwaralipiApp(),
  ),
);
```

ViewModels are created per-screen, **not** in `MultiProvider`. Each screen creates its ViewModel and provides it locally:

```dart
ChangeNotifierProvider(
  create: (ctx) => LibraryViewModel(
    notationRepository: ctx.read<NotationRepository>(),
    tagRepository: ctx.read<TagRepository>(),
  ),
  child: const LibraryScreen(),
)
```

---

## 5. ViewModel Catalog

### 5.1 LibraryViewModel

**State type:** `AsyncState<LibraryState>`

```
LibraryState {
  notations: List<NotationSummary>,
  recentlyPlayed: List<NotationSummary>,
  searchQuery: String,
  activeFilters: FilterSet,
  activeSort: SortOption,
  isSearchActive: bool,
}
```

**Methods:**

| Method | Trigger |
|---|---|
| `init()` | Screen mount |
| `search(String query)` | Search bar text change (debounced 200ms) |
| `applyFilters(FilterSet)` | Filter sheet confirm |
| `applySort(SortOption)` | Sort sheet selection |
| `clearSearch()` | Search bar clear |
| `clearFilters()` | Filter chip clear |

**DB stream:** Watches `notations` table via `NotationRepository.watchAll()`. Any DB write to `notations` automatically triggers a list refresh.

---

### 5.2 CaptureViewModel

**State type:** `AsyncState<CaptureState>`

```
CaptureState {
  pages: List<CapturePageDraft>,   // in-session pages with RenderParams
  isSaving: bool,
  editingNotationId: String?,      // null = new notation, set = edit mode
}
```

**Methods:**

| Method | Trigger |
|---|---|
| `addPagesFromGallery(List<XFile>)` | Gallery picker result |
| `addPagesFromCamera(List<XFile>)` | Camera result |
| `updateRenderParams(pageIndex, RenderParams)` | Page editor actions |
| `reorderPages(oldIndex, newIndex)` | Drag in thumbnail strip |
| `deletePage(pageIndex)` | Delete page action |
| `saveNotation(NotationMetadata)` | Metadata form Save tap |

**No DB stream** — ephemeral session state only.

---

### 5.3 NotationDetailViewModel

**State type:** `AsyncState<NotationDetail>`

```
NotationDetail {
  notation: Notation,
  pages: List<NotationPage>,
  tags: List<Tag>,
  instruments: List<InstrumentInstance>,
  customFields: List<CustomFieldValue>,
}
```

**Methods:**

| Method | Trigger |
|---|---|
| `init(notationId)` | Screen mount |
| `delete()` | Delete action → soft-delete |

---

### 5.4 PlayerViewModel

**State type:** `AsyncState<PlayerState>`

```
PlayerState {
  pages: List<RenderedPage>,   // decoded + filtered images
  currentPageIndex: int,
  isChromeVisible: bool,
  forcedOrientation: Orientation?,
}
```

**Methods:**

| Method | Trigger |
|---|---|
| `init(notationId)` | Screen mount; loads + processes pages |
| `goToPage(index)` | Swipe / thumbnail tap |
| `toggleChrome()` | Tap on screen |
| `forceOrientation(Orientation?)` | Toolbar button |

On `init`: increments play count + sets `last_played_at` after pages are loaded.

---

### 5.5 InstrumentsViewModel

**State type:** `AsyncState<InstrumentsState>`

```
InstrumentsState {
  classes: List<InstrumentClass>,
  instances: List<InstrumentInstance>,  // active only (deleted_at IS NULL)
}
```

---

### 5.6 TagsViewModel

**State type:** `AsyncState<List<Tag>>`

**Methods:** `init()`, `createTag(name, colorHex)`, `updateTag(id, name, colorHex)`, `deleteTag(id)`.

---

### 5.7 TrashViewModel

**State type:** `AsyncState<List<TrashedNotation>>`

**Methods:** `init()`, `restore(id)`, `purge(id)`, `purgeAll()`.

---

### 5.8 SettingsViewModel

**State type:** `AsyncState<UserPreferences>`

**Methods:** `init()`, `updateUserName(String)`, `updateDefaultSort(SortOption)`.

> **Note:** Theme mode and color scheme are managed by `AppearanceViewModel` (§5.9), not here.

---

### 5.9 AppearanceViewModel

**State type:** `AsyncState<AppearanceState>`

```
AppearanceState {
  themeMode: ThemeMode,                // light | dark | system
  colorSchemeMode: ColorSchemeMode,    // catppuccin | monet
  seedColor: Color?,                   // selected Catppuccin swatch; null = use default
}
```

**Methods:**

| Method | Trigger |
|---|---|
| `init()` | Screen mount |
| `updateThemeMode(ThemeMode)` | SegmentedButton selection |
| `updateColorSchemeMode(ColorSchemeMode)` | Radio button selection |
| `updateSeedColor(Color)` | Catppuccin swatch tap |

**DB stream:** Watches `user_preferences` via `PreferencesRepository.watch()`. Changes apply immediately to `MaterialApp.themeMode` and `ColorScheme`.

---

### 5.10 CustomFieldsViewModel

**State type:** `AsyncState<List<CustomFieldDefinition>>`

**Methods:** `init()`, `createField(name, type)`, `updateField(id, name, type)`, `deleteField(id)`.

**DB stream:** Watches `custom_field_definitions` table via `CustomFieldRepository.watchAll()`.

---

## 6. Widget Integration Pattern

```dart
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LibraryViewModel(
        notationRepository: ctx.read<NotationRepository>(),
      )..init(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();
    return switch (vm.state) {
      Idle() || Loading() => const _LoadingView(),
      Success(:final data) => _NotationList(state: data),
      Failure(:final message) => _ErrorView(message: message),
    };
  }
}
```

**Rule:** `context.watch<T>()` in build; `context.read<T>()` in callbacks. Never `watch` in a callback.

---

## 7. Reactive DB Streams

Drift emits a new `List<T>` whenever the relevant table changes. ViewModels subscribe in `init()` and cancel in `dispose()`.

```dart
StreamSubscription<List<NotationSummary>>? _sub;

@override
Future<void> init() async {
  _setState(Loading());
  _sub = _repo.watchAll().listen(
    (notations) => _setState(Success(_buildState(notations))),
    onError: (Object e, StackTrace st) {
      AppLogger.error('LibraryVM', 'Stream error', error: e, stackTrace: st);
      _setState(Failure('Failed to load notations'));
    },
  );
}

@override
void dispose() {
  _sub?.cancel();
  super.dispose();
}
```

---

## 8. Immutability Rules

- Domain models: plain Dart classes with `copyWith`. Never mutate fields.
- `CaptureState.pages`: use `List.unmodifiable()`; any modification returns new list.
- ViewModel internal state: replace the entire state object via `_setState()`; never mutate in place.
- `FilterSet`, `SortOption`, `RenderParams`: all immutable value objects with `copyWith`.
