# Library Shell — UI Fix Tasks

Sprint-zero cleanup: fix the global shell and Library screen to match the UI spec.
All tasks are a single PR.

---

## 1. Global Shell — NavigationBar + FAB

**File:** `lib/app.dart`

- Replace the single `/` `GoRoute` with a `ShellRoute` that wraps Library and Settings.
- Shell scaffold renders a `NavigationBar` at the bottom with two destinations:
  - Index 0 — Library (`Icons.library_music_outlined` / `Icons.library_music`, route `/`)
  - Index 1 — Settings (`Icons.settings_outlined` / `Icons.settings`, route `/settings`)
- `indicatorColor: colorScheme.secondaryContainer`
- `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`
- NavigationBar visible on: Library, Settings, and all settings sub-screens.
- NavigationBar hidden on: Player, PageEditor, MetadataForm.
- FAB (`FloatingActionButton.extended`) lives in the shell scaffold:
  - Icon: `Icons.add_a_photo_outlined`
  - Label: "Capture"
  - Color: `colorScheme.primaryContainer` bg / `colorScheme.onPrimaryContainer` fg
  - Position: `FloatingActionButtonLocation.endFloat`
  - Semantics label: "Capture new notation"
  - Pressing it should open the `CaptureEntrySheet` (bottom sheet).
  - FAB hidden on Settings and sub-screens — only visible on Library.

---

## 2. Library AppBar — SliverAppBar with greeting

**File:** `lib/features/library/screens/library_screen.dart`

- Replace `AppBar` with `SliverAppBar(pinned: true, floating: false)` inside a `CustomScrollView`.
- Title: "Hi, \<name\>" — read from `SettingsViewModel` / `PreferencesRepository`. Fallback: "Hi there".
- Title style: `displaySmall`, `fontWeight: FontWeight.w700`, color `colorScheme.onSurface`.
- Actions: single `IconButton(icon: Icon(Icons.sort_outlined))` that opens the sort bottom sheet.

---

## 3. Sort Control — Modal Bottom Sheet

**File:** `lib/features/library/screens/library_screen.dart`  
**New widget:** `lib/features/library/widgets/sort_bottom_sheet.dart`

- Remove the `SegmentedButton` (`_SortControl`) from the AppBar `bottom` slot entirely.
- Sort is triggered by the sort `IconButton` in AppBar actions.
- Sheet: `showModalBottomSheet` with drag handle.
- Sheet content: "Sort by" `titleMedium` heading + `Divider` + `ListView` of sort options:
  - Title (A-Z / Z-A)
  - Date written (Newest first / Oldest first)
  - Date added (Newest first / Oldest first)
  - Play count (Most first / Least first)
  - Last played (Most recent / Least recent)
- Active option: `ListTile(selected: true)`, trailing direction icon.
- Re-tapping active option toggles ASC/DESC.
- The `LibrarySort` enum in `library_view_model.dart` needs to be expanded to cover all options above.

---

## 4. Library Layout — CustomScrollView with Slivers

**File:** `lib/features/library/screens/library_screen.dart`

Current layout is a flat `Column`. Replace with `CustomScrollView` containing:
1. `SliverAppBar` (from task 2)
2. `SliverToBoxAdapter` — `SearchBar` (16dp h-padding, 8dp vertical)
3. `SliverToBoxAdapter` (conditional, if tags exist) — `TagFilterRow` horizontal scroll
4. `SliverToBoxAdapter` (conditional, if recently played) — "Recently Played" label + carousel
5. `SliverPadding` wrapping `SliverList.builder` — notation rows
6. Empty / loading / error states as `SliverFillRemaining`

---

## Acceptance Criteria

- [ ] Bottom `NavigationBar` visible on Library and Settings screens.
- [ ] FAB "Capture" visible on Library; hidden on Settings and sub-screens.
- [ ] Library app bar greets "Hi, \<name\>" (or "Hi there") in `displaySmall` bold.
- [ ] Sort icon in AppBar opens a bottom sheet; no SegmentedButton anywhere.
- [ ] Layout is `CustomScrollView` / slivers; no flat `Column`.
- [ ] `flutter analyze` passes with zero errors.
- [ ] `dart format` clean.
- [ ] Existing widget tests still pass (update if needed).
