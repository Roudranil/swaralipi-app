# UI Fix Tasks — FAB Label, Page Editor, Search Bar, Nav Bar, Tags

---

## Task 1 — FAB label: "Capture" → "Add notation"

**Parent Story:** N/A

**What:**
In `lib/app.dart`, inside `_AppShell.build`, the `FloatingActionButton.extended`
has `label: const Text('Capture')` (line 536) and
`semanticsLabel: 'Capture new notation'` (line 530).
Change both:
- label → `const Text('Add notation')`
- semanticsLabel → `'Add notation'`

**Definition of Done:**
- [ ] FAB label reads "Add notation" on Library screen
- [ ] Semantics label updated
- [ ] Tests written and passing
- [ ] Coverage ≥ 80%
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/app.dart` — `_AppShell.build` FAB widget](../../lib/app.dart)

**Priority:** p2

**Notes:** Trivial one-liner. Do this first.

---

## Task 2 — Page Editor: animated Filters side panel

**Parent Story:** N/A

**What:**
Remove the inline `_FilterChipRow` from the `_EditorBody` column (currently line 247
in `lib/features/capture/screens/page_editor_screen.dart`).

Replace with an animated side panel:
1. Convert `_EditorBody` from `StatelessWidget` to `StatefulWidget`.
   Add `bool _filtersExpanded = false` local state.
2. Wrap `Expanded(_ActivePagePreview)` in a `Stack`:
   ```dart
   Stack(children: [
     Expanded(child: _ActivePagePreview(...)),
     Positioned(
       top: 0, bottom: 0, right: 0,
       child: AnimatedContainer(
         duration: Duration(milliseconds: 250),
         curve: Curves.easeInOut,
         width: _filtersExpanded ? 180 : 0,
         decoration: BoxDecoration(
           color: colorScheme.surfaceContainerHigh,
           borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
         ),
         child: _filtersExpanded ? _FilterPanel(...) : const SizedBox.shrink(),
       ),
     ),
   ])
   ```
3. `_FilterPanel` is a new private widget: vertical `ListView` of the existing
   filter options from `_kFilterLabels` / `_kFilterMatrices` (lines 68–117).
   Tapping a filter calls `vm.setFilter(filter)` then `setState(() => _filtersExpanded = false)`.
4. Add a **Filters** `IconButton(icon: Icon(Icons.tune_outlined))` to `_PageActionBar`
   toolbar, alongside the existing Crop/Rotate/Reset buttons.
   It calls `setState(() => _filtersExpanded = !_filtersExpanded)` on the parent.
   Use a callback parameter `onToggleFilters` passed from `_EditorBody`.
5. Tapping outside the panel (on the image preview) collapses it:
   wrap `_ActivePagePreview` in a `GestureDetector` that sets `_filtersExpanded = false`.

**Definition of Done:**
- [ ] No filter chip row visible inline in editor
- [ ] Filters `IconButton` in toolbar; tapping opens/closes side panel
- [ ] Panel animates in/out from the right with 250 ms ease
- [ ] Tapping a filter applies it and closes the panel
- [ ] Tapping outside the panel closes it
- [ ] Tests written and passing
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/features/capture/screens/page_editor_screen.dart` lines 68–117 — filter constants](../../lib/features/capture/screens/page_editor_screen.dart)
- [`lib/features/capture/screens/page_editor_screen.dart` lines 221–257 — `_EditorBody` column](../../lib/features/capture/screens/page_editor_screen.dart)
- [`lib/features/capture/screens/page_editor_screen.dart` lines 327–358 — `_FilterChipRow`](../../lib/features/capture/screens/page_editor_screen.dart)
- [`lib/features/capture/screens/page_editor_screen.dart` lines 366–451 — `_PageActionBar`](../../lib/features/capture/screens/page_editor_screen.dart)

**Priority:** p1

---

## Task 3 — Page Editor "Next" button navigates to MetadataFormScreen

**Parent Story:** N/A

**What:**
In `lib/app.dart`, inside `_AppShell._openCaptureSheet`, the `PageEditorScreen`
is constructed with `onNext: (_) {}` (empty callback — line 514).

Replace with a real implementation:
```dart
onNext: (ctx) {
  final session = ctx.read<CaptureSessionViewModel>();
  final pageVm  = ctx.read<PageEditorViewModel>();
  Navigator.of(ctx).push(
    MaterialPageRoute<void>(
      builder: (_) => MultiProvider(
        providers: [
          ChangeNotifierProvider<CaptureSessionViewModel>.value(value: session),
          ChangeNotifierProvider<PageEditorViewModel>.value(value: pageVm),
          ChangeNotifierProvider<MetadataFormViewModel>(
            create: (_) => MetadataFormViewModel(
              // confirm exact param names from metadata_form_view_model.dart
              notationRepository: _notationRepository!,
              tagRepository: _tagRepository,
              instrumentRepository: _instrumentRepository,
              customFieldRepository: _customFieldRepository,
              storageService: _storageService!,
            ),
          ),
        ],
        child: const MetadataFormScreen(),
      ),
    ),
  );
},
```

Read `lib/features/capture/viewmodels/metadata_form_view_model.dart` and
`lib/features/capture/screens/metadata_form_screen.dart` to confirm exact
constructor signatures before coding. Pattern reference:
`lib/features/edit/screens/edit_notation_screen.dart` lines 234–268.

**Definition of Done:**
- [ ] Tapping Next on Page Editor opens MetadataFormScreen
- [ ] All required providers available on the new route
- [ ] `context.mounted` checked before push
- [ ] Tests written and passing
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/app.dart` line 514 — empty `onNext` callback](../../lib/app.dart)
- [`lib/features/capture/screens/metadata_form_screen.dart`](../../lib/features/capture/screens/metadata_form_screen.dart)
- [`lib/features/capture/viewmodels/metadata_form_view_model.dart`](../../lib/features/capture/viewmodels/metadata_form_view_model.dart)
- [`lib/features/edit/screens/edit_notation_screen.dart` lines 234–268 — navigation pattern](../../lib/features/edit/screens/edit_notation_screen.dart)

**Priority:** p0

**Notes:** None.

---

## Task 4 — Search bar moves into AppBar as SearchAnchor icon

**Parent Story:** N/A

**What:**
In `lib/features/library/screens/library_screen.dart`:

1. Remove `SearchController _searchController` field, its `dispose()` call, and the
   `SliverToBoxAdapter` containing `_LibrarySearchBar` from the sliver list.
2. Delete the `_LibrarySearchBar` widget class.
3. In `SliverAppBar.actions`, add a `SearchAnchor` **before** the sort `IconButton`:

```dart
SearchAnchor(
  viewOnChanged: (query) => vm.setSearchQuery(query),
  viewOnSubmitted: (_) {},
  viewLeading: const BackButton(),
  viewTrailing: [],
  builder: (context, controller) => Semantics(
    label: 'Search notations',
    child: IconButton(
      icon: const Icon(Icons.search_outlined),
      onPressed: () => controller.openView(),
    ),
  ),
  suggestionsBuilder: (context, controller) => const [],
),
```

When the search overlay closes without a query, call `vm.clearSearch()`.
Use `SearchAnchor`'s `viewOnChanged` for live filtering — the existing
debounced `vm.setSearchQuery` in the ViewModel handles debounce internally.

**Definition of Done:**
- [ ] No standalone search bar below the AppBar
- [ ] Search icon appears in AppBar, left of the sort icon
- [ ] Tapping search icon opens M3 full-screen search overlay
- [ ] Typing in overlay filters the notation list live
- [ ] Closing overlay without query clears the filter
- [ ] Tests written and passing
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/features/library/screens/library_screen.dart` lines 235–265 — `SliverAppBar` and `_LibrarySearchBar` sliver](../../lib/features/library/screens/library_screen.dart)
- [`lib/features/library/viewmodels/library_view_model.dart` lines 449–472 — `setSearchQuery` / `clearSearch`](../../lib/features/library/viewmodels/library_view_model.dart)

**Priority:** p2

---

## Task 5 — NavigationBar distinct surface color (Material 3)

**Parent Story:** N/A

**What:**
In `lib/app.dart`, `_buildTheme(ColorScheme scheme)` (line 320) currently returns
`ThemeData(useMaterial3: true, colorScheme: scheme)` with no navigation bar
theming, causing the nav bar to blend into the page background.

Add `NavigationBarThemeData` to the returned `ThemeData`:
```dart
ThemeData _buildTheme(ColorScheme scheme) => ThemeData(
  useMaterial3: true,
  colorScheme: scheme,
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: scheme.surfaceContainer,
    indicatorColor: scheme.secondaryContainer,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  ),
);
```

Then remove the now-redundant `indicatorColor` and `labelBehavior` properties
from the inline `NavigationBar` widget (lines 541–559) since they are covered
by the theme.

**Definition of Done:**
- [ ] NavigationBar visually distinct from page background on both light and dark themes
- [ ] `backgroundColor` is `colorScheme.surfaceContainer`
- [ ] No duplicate properties between inline widget and theme
- [ ] Tests written and passing
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/app.dart` line 320 — `_buildTheme`](../../lib/app.dart)
- [`lib/app.dart` lines 541–559 — `NavigationBar` widget](../../lib/app.dart)

**Priority:** p1

---

## Task 6 — Remove tag pre-seeding on fresh install

**Parent Story:** N/A

**What:**

**Step 1 — Remove DB-level tag seeding:**
In `lib/core/database/app_database.dart`, `_seedInitialData()` (lines 679–706)
inserts 5 default tags on first install. Delete the 5 tag insertions (lines 686–705).
Keep only the `UserPreferencesTable` singleton row insert (lines 681–683).

**Step 2 — Migration to clean existing installs:**
Bump `schemaVersion`. Add a migration step that runs:
```sql
DELETE FROM tags_table
WHERE name IN ('Ragas', 'Bhajans', 'Bandishes', 'Thumri', 'Exercises');
```

**Step 3 — Remove dead code:**
In `lib/features/tags/data/tag_repository_impl.dart`, delete:
- The 5 default tag constants (lines 28–34)
- `seedDefaultTagsIfNeeded()` method (lines 129–159) — never called in production

If `seedDefaultTagsIfNeeded` is declared on the `TagRepository` abstract interface
in `lib/shared/repositories/tag_repository.dart`, remove it from there too.

**Definition of Done:**
- [ ] Fresh install: zero tags exist in the library
- [ ] Existing install: pre-seeded tags removed by migration
- [ ] `schemaVersion` bumped; migration tested
- [ ] Dead `seedDefaultTagsIfNeeded` code removed from impl and interface
- [ ] Tests written and passing
- [ ] `flutter analyze` clean
- [ ] `dart format` applied
- [ ] PR opened and linked

**References:**
- [`lib/core/database/app_database.dart` lines 679–706 — `_seedInitialData`](../../lib/core/database/app_database.dart)
- [`lib/features/tags/data/tag_repository_impl.dart` lines 28–34, 129–159 — dead seed code](../../lib/features/tags/data/tag_repository_impl.dart)
- [`lib/shared/repositories/tag_repository.dart` — `TagRepository` interface](../../lib/shared/repositories/tag_repository.dart)

**Priority:** p1

**Notes:** Do this last — schema migrations interact with tests that use in-memory DBs.
