# Swaralipi — UI Specification

## 1. Overview

### 1.1 Purpose

This document specifies the concrete UI implementation decisions for Swaralipi: widget choices, MD3 token assignments, layout measurements, interaction states, and component patterns. It is the reference document for writing Flutter widget code.

### 1.2 Related Documents

| Document | Role |
|----------|------|
| `docs/01-product/PRD.md` | Feature requirements and acceptance criteria |
| `docs/02-technical/ux-flows.md` | Screen-by-screen interaction flows |
| `docs/02-technical/navigation-structure.md` | Route registry and shell structure |
| `docs/02-technical/state-management.md` | ViewModel contracts |
| `docs/02-technical/data-model.md` | Entity fields and schema |

### 1.3 How to Read

- **Section 2** — design system tokens; read before implementing any screen
- **Section 3** — global chrome shared by all in-shell screens
- **Section 4** — screen-by-screen spec; each subsection is self-contained
- **Section 5** — reusable components referenced from Section 4
- **Section 6** — accessibility requirements applied everywhere
- **Section 7** — orientation handling

---

## 2. Design System — Material 3

### 2.1 ThemeData Configuration

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kDefaultSeedColor,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kDefaultSeedColor,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system, // overridden by Settings > Appearance
);
```

#### 2.1.1 Dynamic Color (Monet)

- Wrap `MaterialApp` with `DynamicColorBuilder` from `package:dynamic_color`
- `lightDynamic` / `darkDynamic` replace seed-based schemes when Monet is available
- Android 12+ only; no fallback needed (target device: Samsung Galaxy S25, Android 15)

#### 2.1.2 Default Seed Colors

| Theme mode | Default seed | Hex |
|-----------|-------------|-----|
| Dark | Catppuccin Mocha Mauve | `#CBA6F7` |
| Light | Catppuccin Latte Mauve | `#8839EF` |

---

### 2.2 Color System

#### 2.2.1 Color Role Assignments

All values accessed via `Theme.of(context).colorScheme`.

| UI Purpose | ColorScheme Token |
|-----------|------------------|
| Screen background | `surface` |
| App bar background | `surfaceContainer` |
| Bottom navigation background | `surfaceContainer` |
| FAB background | `primaryContainer` |
| FAB icon | `onPrimaryContainer` |
| Card fill (default) | `surfaceContainerLow` |
| Card border (outlined variant) | `outlineVariant` |
| Primary action button fill | `primary` |
| Primary action button text | `onPrimary` |
| Tonal button fill | `secondaryContainer` |
| Tonal button text | `onSecondaryContainer` |
| Swipe-left Edit badge | `secondaryContainer` |
| Swipe-left Delete badge | `errorContainer` |
| Search bar fill | `surfaceContainerHigh` |
| Active filter chip fill | `secondaryContainer` |
| Active filter chip text | `onSecondaryContainer` |
| Inactive chip fill | `surface` |
| Inactive chip border | `outline` |
| Snackbar background | `inverseSurface` |
| Snackbar text | `onInverseSurface` |
| Divider | `outlineVariant` |
| Secondary / caption text | `onSurfaceVariant` |
| Active filter banner | `tertiaryContainer` |
| Archived instrument badge | `errorContainer` |
| Destructive action text | `error` |

#### 2.2.2 Catppuccin Palette — In-App Usage

- **Tags** — color picked from Catppuccin; chip `backgroundColor` = Catppuccin color at 20% opacity (inactive), 100% at 15% opacity + outline (active)
- **Instrument instance** — Catppuccin color → 4dp left-border accent on list row
- **Appearance seed swatches** — full Catppuccin Latte (light) and Mocha (dark) palettes
- **No free-form color pickers anywhere in the app**

##### Catppuccin Mocha Colors (Dark Mode Swatches)

| Name | Hex |
|------|-----|
| Rosewater | `#F5E0DC` |
| Flamingo | `#F2CDCD` |
| Pink | `#F5C2E7` |
| Mauve | `#CBA6F7` |
| Red | `#F38BA8` |
| Maroon | `#EBA0AC` |
| Peach | `#FAB387` |
| Yellow | `#F9E2AF` |
| Green | `#A6E3A1` |
| Teal | `#94E2D5` |
| Sky | `#89DCEB` |
| Sapphire | `#74C7EC` |
| Blue | `#89B4FA` |
| Lavender | `#B4BEFE` |
| Text | `#CDD6F4` |

##### Catppuccin Latte Colors (Light Mode Swatches)

| Name | Hex |
|------|-----|
| Rosewater | `#DC8A78` |
| Flamingo | `#DD7878` |
| Pink | `#EA76CB` |
| Mauve | `#8839EF` |
| Red | `#D20F39` |
| Maroon | `#E64553` |
| Peach | `#FE640B` |
| Yellow | `#DF8E1D` |
| Green | `#40A02B` |
| Teal | `#179299` |
| Sky | `#04A5E5` |
| Sapphire | `#209FB5` |
| Blue | `#1E66F5` |
| Lavender | `#7287FD` |
| Text | `#4C4F69` |

---

### 2.3 Typography Scale

All values via `Theme.of(context).textTheme`.

| UI Element | TextTheme Token | Weight | Notes |
|-----------|----------------|--------|-------|
| Library greeting "Hi, \<name\>" | `displaySmall` | Bold (`w700`) | Hero text |
| App bar titles | `titleLarge` | Regular | |
| Notation title (Detail View) | `headlineMedium` | SemiBold (`w600`) | |
| Notation title (List row) | `titleMedium` | Medium (`w500`) | |
| Artist name | `bodyMedium` | Regular | `onSurfaceVariant` |
| Metadata labels (key / time / language) | `labelLarge` | Medium | |
| Metadata values | `bodySmall` | Regular | |
| Chip text | `labelMedium` | Medium | |
| Button text | `labelLarge` | Medium | |
| Snackbar text | `bodyMedium` | Regular | on `inverseSurface` |
| Caption / secondary info | `bodySmall` | Regular | `onSurfaceVariant` |
| Settings row title | `bodyLarge` | Regular | |
| Settings row subtitle | `bodySmall` | Regular | `onSurfaceVariant` |
| Recently Played section label | `labelLarge` | Medium | `onSurfaceVariant` |
| Filter / sort sheet title | `titleMedium` | Medium | |
| Empty state headline | `headlineSmall` | Regular | |
| Empty state body | `bodyMedium` | Regular | `onSurfaceVariant` |

---

### 2.4 Shape Tokens

All values as `BorderRadius.circular(X)` or `RoundedRectangleBorder`.

| Component | Corner Radius | MD3 Token |
|-----------|--------------|-----------|
| Cards | 12dp | `medium` |
| Notation row thumbnail | 8dp | `small` |
| Page Editor image preview | 12dp | `medium` |
| Recently Played carousel card | 12dp | `medium` |
| FAB | 16dp | `large` |
| Buttons (Filled, Outlined, Tonal, Text) | 9999dp | `full` |
| Chips (Filter, Input, Suggestion) | 9999dp | `full` |
| Dialogs | 28dp | `extra-large` |
| Bottom sheets | 28dp top, 0dp bottom | `extra-large` top |
| Snackbar | 4dp | `extra-small` |
| Search bar | 28dp | `full` (MD3 spec) |
| Instrument instance photo | 8dp | `small` |
| Catppuccin color picker circle | 9999dp | `full` |

---

### 2.5 Elevation

`Material(elevation: X)` with `useMaterial3: true` applies tonal color overlay automatically.

| Surface | Level | Tonal Offset |
|---------|-------|-------------|
| Screen background | 0 | None |
| Cards at rest | 1 | +5% primary |
| App bar (scrolled / elevated) | 2 | +8% primary |
| Navigation bar | 2 | +8% primary |
| FAB | 3 | +11% primary |
| Dialogs | 3 | +11% primary |
| Bottom sheets (modal) | 3 | +11% primary |
| Bottom sheets (standard) | 1 | +5% primary |
| Fanned page stack — bottom layers | 1 | +5% primary |

---

### 2.6 Motion & Transitions

#### 2.6.1 Screen Transitions (go_router)

| Transition | Curve | Duration |
|-----------|-------|---------|
| Screen push — enter | `Curves.easeInOutCubicEmphasized` (decelerate) | 400ms |
| Screen push — exit | `Curves.easeIn` | 200ms |
| Screen pop — enter | `Curves.easeOut` | 250ms |
| Screen pop — exit | `Curves.easeInOutCubicEmphasized` (accelerate) | 200ms |

#### 2.6.2 Component Motion

| Component | Behavior | Duration |
|-----------|---------|---------|
| Bottom sheet slide-up | `Curves.easeOutCubic` | 300ms |
| Bottom sheet dismiss | `Curves.easeInCubic` | 200ms |
| Player chrome fade | `AnimatedOpacity` | 300ms |
| Snackbar entry | `Curves.easeOutCubic` | 250ms |
| Snackbar exit | `Curves.easeInCubic` | 200ms |
| Filter chip toggle | `SpringSimulation(SpringDescription(mass: 1, stiffness: 800, damping: 80))` — or use `Curves.easeInOutCubicEmphasized` as approximation | ~300ms |
| Swipe action reveal | Linear (follows finger) | — |
| FAB collapse (scroll down) | `SpringDescription(mass: 1, stiffness: 800, damping: 80)` via `AnimationController` + `SpringSimulation` | ~250ms |
| FAB expand (scroll up) | Same spring | ~250ms |
| Active filter banner appear | `AnimatedSwitcher` | 200ms |

---

## 3. Global Shell

### 3.1 Bottom Navigation Bar

- **Widget:** `NavigationBar`
- **Destinations:** 2 tabs

| Index | Label | Unselected Icon | Selected Icon | Route |
|-------|-------|----------------|--------------|-------|
| 0 | Library | `Icons.library_music_outlined` | `Icons.library_music` | `/` |
| 1 | Settings | `Icons.settings_outlined` | `Icons.settings` | `/settings` |

- `indicatorColor: colorScheme.secondaryContainer`
- `labelBehavior: NavigationDestinationLabelBehavior.alwaysShow`
- **Visible on:** all in-shell screens (`LibraryScreen`, `NotationDetailScreen`, `SettingsScreen`, and all settings sub-screens)
- **Hidden on:** `PlayerScreen`, `PageEditorScreen`, `MetadataFormScreen`, `ErrorScreen`

---

### 3.2 App Bar Patterns

| Screen | Widget | Title | Title Style | Leading | Actions |
|--------|--------|-------|------------|---------|---------|
| Library | `SliverAppBar(pinned: true)` | "Hi, \<name\>" | `displaySmall` bold | — | Sort `IconButton(Icons.sort)` |
| Notation Detail | `AppBar` | _(none)_ | — | Back arrow (auto) | Edit `IconButton(Icons.edit_outlined)`, Delete `IconButton(Icons.delete_outline)` |
| Settings | `AppBar` | "Settings" | `titleLarge` | — | — |
| Tags | `AppBar` | "Tags" | `titleLarge` | Back arrow | `FilledButton.tonal("+ Create")` |
| Instruments | `AppBar` | "Instruments" | `titleLarge` | Back arrow | `FilledButton.tonal("+ New Class")` |
| Trash | `AppBar` | "Trash" | `titleLarge` | Back arrow | `TextButton("Empty Trash")` (error style) |
| Custom Fields | `AppBar` | "Custom Fields" | `titleLarge` | Back arrow | `FilledButton.tonal("+ Add Field")` |
| Page Editor | `AppBar` | _(none)_ | — | `TextButton("Discard")` | `FilledButton("Save")` |
| Metadata Form | `AppBar` | _(none)_ | — | `TextButton("← Editor")` | `FilledButton("Save")` (disabled if title empty) |
| Player | _(none — full-screen)_ | — | — | — | — |
| Appearance | `AppBar` | "Appearance" | `titleLarge` | Back arrow | — |
| Tag Form | `AppBar` | "New Tag" / "Edit Tag" | `titleLarge` | Back / Cancel | `FilledButton("Save")` |
| Instrument screens | `AppBar` | per screen | `titleLarge` | Back arrow | — |
| Camera Selection | `AppBar` | "Photos taken just now" | `titleMedium` | Back arrow | `FilledButton("Confirm")` |

---

### 3.3 FAB

- **Widget:** `FloatingActionButton.extended` at rest; `FloatingActionButton` when scrolling down (animated collapse via `AnimatedSwitcher`)
- **Icon:** `Icons.add_a_photo_outlined`
- **Label:** "Capture" (visible at rest)
- **Color:** `colorScheme.primaryContainer` background, `colorScheme.onPrimaryContainer` foreground
- **Position:** `floatingActionButtonLocation: FloatingActionButtonLocation.endFloat`; bottom padding accounts for `NavigationBar` height via `MediaQuery.of(context).padding`
- **Semantics label:** "Capture new notation"

---

## 4. Screens

### 4.1 Library — Home Screen

**Route:** `/` · In shell · `LibraryScreen`

#### 4.1.1 Layout Structure

```
CustomScrollView
  SliverAppBar (pinned: true, floating: false)
    title: "Hi, <name>"         ← displaySmall, bold
    actions: [Sort IconButton]
  SliverToBoxAdapter
    SearchBar                   ← 16dp h-padding, 8dp vertical
  SliverToBoxAdapter (if tags exist)
    Tag chip quick-filter row   ← horizontal scroll
  SliverToBoxAdapter (if recently played)
    "Recently Played" label
    Horizontal carousel
  SliverPadding(sliver: SliverList)
    Notation rows
Positioned (bottom-right)
  FAB
```

#### 4.1.2 Header

- Greeting text: "Hi, \<name\>" — name from `SettingsViewModel.userName`
- Fallback when name not set: "Hi there"
- `displaySmall`, `fontWeight: FontWeight.w700`, color `colorScheme.onSurface`

#### 4.1.3 Recently Played Carousel

- **Hidden when:** no notations have a non-null `last_played_at`
- **Max items:** 5 (ordered by `last_played_at DESC`)
- **Widget:** `SizedBox(height: 180)` wrapping `ListView.builder(scrollDirection: Axis.horizontal)`
- **Card dimensions:** 120dp width × 160dp height
- **Card widget:** `Card.filled(clipBehavior: Clip.antiAlias, shape: RoundedRectangleBorder(12dp))`
- **Card structure:** top 120dp = `Image.file(fit: BoxFit.cover, width: double.infinity)`; bottom 40dp = `Padding(8dp)` → title `bodySmall`, 1 line, `TextOverflow.ellipsis`
- **Gap between cards:** 12dp
- **Section label:** `labelLarge`, `onSurfaceVariant`; 16dp left, 4dp top, 8dp bottom
- **Tap:** navigate to `NotationDetailScreen(/notation/:id)`

#### 4.1.4 Notation List

- **Widget:** `SliverList.builder` (not `SliverList.separated` — divider rendered inside row widget)
- **Row widget:** custom `NotationListTile` (see §5.4)
- **Minimum row height:** 80dp
- **Tap:** navigate to `NotationDetailScreen(/notation/:id)`

#### 4.1.5 Search Bar

- **Widget:** `SearchBar`
- **Leading icon:** `Icons.search`, `onSurfaceVariant`
- **Trailing:** `IconButton(icon: Icons.format_quote_outlined)` for exact-match toggle; when active, icon color = `colorScheme.primary`
- **Height:** 56dp (MD3 default)
- **Padding:** 16dp horizontal, 8dp vertical
- **Elevation:** 0 (flush with surface; uses `surfaceContainerHigh` fill)
- **Live search:** updates list on each keystroke

#### 4.1.6 Sort Control

- **Trigger:** `IconButton(icon: Icons.sort_outlined)` in AppBar `actions`
- **Sheet:** `showModalBottomSheet` with drag handle
- **Sheet content:** `Column` with "Sort by" `titleMedium` heading + `Divider` + `ListView` of sort options
- **Sort options:**

| Label | Default Direction | Secondary Icon |
|-------|-----------------|---------------|
| Title | A-Z | `Icons.arrow_upward` / `Icons.arrow_downward` |
| Date written | Newest first | same |
| Date added | Newest first | same |
| Play count | Most first | same |
| Last played | Most recent first | same |

- **Active option:** `ListTile(selected: true)` with `selectedColor: colorScheme.primary`; trailing direction icon shown
- **Re-tap active:** toggles ASC/DESC
- **Persistence:** stored in `user_preferences` table via `PreferencesRepository`; survives restarts

#### 4.1.7 Tag Chip Quick-Filter Row

- **Hidden when:** no tags defined
- **Widget:** `SizedBox(height: 48)` wrapping `ListView.builder(scrollDirection: Axis.horizontal)`
- **Chip:** `FilterChip(label: Text(tag.name))`
- **Active state:** `selected: true`, `backgroundColor: colorScheme.secondaryContainer`, Catppuccin outline color
- **Inactive state:** `selected: false`, `side: BorderSide(color: colorScheme.outline)`
- **Padding:** 16dp leading, 8dp vertical, 8dp between chips
- **Multiple active:** AND logic

#### 4.1.8 Advanced Filter Drawer

- **Trigger:** filter icon in `SearchBar` trailing area (secondary action) or dedicated filter `IconButton`
- **Sheet:** `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` wrapping `DraggableScrollableSheet(initialChildSize: 0.8, maxChildSize: 0.95)`
- **Sheet structure:**

```
Drag handle
"Filter" titleMedium
Divider
Scrollable filter sections:
  Tags          — multi-select FilterChip grid
  Instruments   — multi-select FilterChip grid
  Language      — multi-select FilterChip row
  Key signature — TextField
  Time signature — TextField
  Date written  — DateRange (two TextFields with date pickers)
  Date added    — DateRange
  Play count    — RangeSlider
  Custom fields — per-type inputs
AND/OR SegmentedButton per group
Divider
Footer row:
  [Reset] TextButton  [Save Preset] OutlinedButton  [Apply] FilledButton
```

- **Active filter state:** when applied, banner replaces tag chip row: `Container(color: colorScheme.tertiaryContainer)` → "Filtered" `labelLarge` + `[Clear] TextButton`

#### 4.1.9 Swipe Actions

- **Direction:** `DismissDirection.endToStart` (left-swipe reveals actions on right)
- **Implementation:** custom `SlideActionRow` widget (partial reveal, not full dismiss)
- **Edit badge:** `colorScheme.secondaryContainer` fill, `Icons.edit_outlined`, "Edit" `labelSmall`
- **Delete badge:** `colorScheme.errorContainer` fill, `Icons.delete_outline`, "Delete" `labelSmall`
- **Badge width:** 72dp each
- **Swipe-right or tap elsewhere:** dismiss badges

#### 4.1.10 Context Menu (Long Press)

- **Widget:** `showMenu` positioned at tap coordinates (`RelativeRect.fromLTRB`)
- **Items:** 4 `PopupMenuItem`s with leading icon + label

| Label | Icon |
|-------|------|
| Edit | `Icons.edit_outlined` |
| Delete | `Icons.delete_outline` |
| Add Tag | `Icons.label_outline` |
| Duplicate | `Icons.copy_all_outlined` |

#### 4.1.11 Empty States

| Condition | Icon | Headline | Body | CTA |
|-----------|------|---------|------|-----|
| No notations | `Icons.music_note` (72dp, `colorScheme.primary`) | "No notations yet" | "Tap + to capture your first notation" | `FilledButton("Capture")` → opens capture sheet |
| Search returns nothing | `Icons.search_off` (72dp, `onSurfaceVariant`) | "No results" | "Try a different search term" | `TextButton("Clear search")` |
| All filtered out | `Icons.filter_alt_off` (72dp, `onSurfaceVariant`) | "No matches" | "Try adjusting your filters" | `TextButton("Clear filters")` |

---

### 4.2 Notation Detail View

**Route:** `/notation/:notationId` · In shell · `NotationDetailScreen`

#### 4.2.1 Layout

```
AppBar
  leading: back arrow
  actions: [Edit IconButton, Delete IconButton]
─────────────────────────────────
Expanded scrollable body:
  FannedPageStack widget          ← center, 240×320dp, tappable → Player
  SizedBox(height: 24)
  Metadata block (Column):
    Title          — headlineMedium, w600
    Artist(s)      — bodyLarge, onSurfaceVariant
    SizedBox(8)
    Row: Date written · Language  — labelLarge chips or plain text
    Row: Key sig · Time sig       — labelLarge
    SizedBox(8)
    Wrap of tag chips             — display only (§5.6)
─────────────────────────────────
Bottom pinned:
  Padding(16dp):
    FilledButton("Play", full width, height 56dp)
```

#### 4.2.2 Fanned Paper Stack

- **Widget:** `FannedPageStack` (custom, see §5.5)
- **Dimensions:** 240×320dp; centered horizontally
- **Tap target:** entire stack; `Semantics(label: "View pages of <title>, <N> pages")`
- **Tap action:** navigate to `PlayerScreen`, increment `play_count`, set `last_played_at`

#### 4.2.3 Metadata Block

- **Title:** `Text(style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600))`
- **Artist(s):** comma-joined; `bodyLarge`, `onSurfaceVariant`
- **Date written:** formatted `dd MMM yyyy`; `labelLarge`
- **Language:** comma-joined; `labelLarge`
- **Key / Time sig:** displayed as `"Key: Yaman · Time: 6/8"`; `labelLarge`
- **Tags:** `Wrap(spacing: 6, runSpacing: 6)` of display-only tag chips (§5.6); shown only if tags present

#### 4.2.4 Play Button

- `FilledButton.icon(icon: Icon(Icons.play_circle_outline, size: 24), label: Text("Play"))`
- `style: FilledButton.styleFrom(minimumSize: Size(double.infinity, 56))`
- Bottom margin: 24dp; side margin: 16dp

---

### 4.3 Notation Player

**Route:** `/notation/:notationId/player` · Out-of-shell · `PlayerScreen`

#### 4.3.1 Layout

```
Scaffold(
  backgroundColor: Colors.black,
  body: Stack [
    PageView                        ← full-screen; each page is InteractiveViewer
    AnimatedOpacity (chrome layer):
      Top overlay:
        title text (bodyLarge, white)
      Bottom overlay:
        page indicator "2 / 5" (labelLarge, white)
        toolbar row (4 IconButtons)
  ]
)
```

- **System UI:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` on enter; restore on exit
- **Page widget:** `InteractiveViewer(minScale: 0.5, maxScale: 4.0)` wrapping `Image.file(fit: BoxFit.contain)`

#### 4.3.2 Chrome Fade

- `AnimatedOpacity(opacity: _chromeVisible ? 1.0 : 0.0, duration: Duration(milliseconds: 300))`
- **Visible on entry:** true
- **Auto-hide:** managed by `PlayerViewModel.scheduleChromeHide()` which starts a 2-second `Timer`; ViewModel cancels it in `dispose()`. Widget reads `viewModel.isChromeVisible` via `ListenableBuilder` — no `setState` in the widget.
- **Tap to restore:** `GestureDetector(onTap: viewModel.showChrome)` overlaid on entire screen

#### 4.3.3 Top Overlay

- `Positioned(top: 0, left: 0, right: 0)`: `Container(color: colorScheme.surfaceContainerHighest.withOpacity(0.7), padding: EdgeInsets.fromLTRB(16, statusBarHeight + 8, 16, 8))`
- Title: `textTheme.bodyLarge` in white

#### 4.3.4 Bottom Overlay

- `Positioned(bottom: 0, left: 0, right: 0)`: same container style
- Row 1: page indicator `"N / total"`, centered, `labelLarge` white
- Row 2: 4 `IconButton`s in `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)`

| Icon | Action |
|------|--------|
| `Icons.width_normal_outlined` | Fit to width: `InteractiveViewer` scale reset to fill width |
| `Icons.height_outlined` | Fit to height |
| `Icons.fit_screen_outlined` | Fit to screen (contain) |
| `Icons.screen_rotation_outlined` | Toggle orientation lock |

#### 4.3.5 Orientation Lock

- `SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])` → lock portrait
- `SystemChrome.setPreferredOrientations(DeviceOrientation.values)` → unlock
- Toolbar icon active state reflects current lock status

---

### 4.4 Capture Entry Bottom Sheet

- **Trigger:** FAB tap
- **Widget:** `showModalBottomSheet(context: context, builder: ...)`
- **Content:**

```
Column:
  Drag handle (centered, 4×40dp, surfaceContainerHighest, rounded)
  Padding(16dp):
    Text("Add notation", style: titleMedium)
  Divider
  ListTile(
    leading: Icon(Icons.photo_library_outlined),
    title: Text("Gallery"),
    onTap: → gallery flow,
  )
  ListTile(
    leading: Icon(Icons.camera_alt_outlined),
    title: Text("Camera"),
    onTap: → camera flow,
  )
  SizedBox(height: safeAreaBottom)
```

---

### 4.5 Camera Selection Screen

**Not in route registry** — presented as a full-screen route after camera intent returns.

#### 4.5.1 Layout

```
AppBar: "Photos taken just now" — titleMedium
  actions: [FilledButton("Confirm")] (disabled until ≥ 1 selected)
Body:
  GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
    ),
    itemBuilder: → PhotoSelectCell
  )
```

#### 4.5.2 Photo Select Cell

- `Stack`:
  - `Image.file(fit: BoxFit.cover, width: double.infinity, height: double.infinity)`
  - `Positioned(top: 4, right: 4)`: `Checkbox(value: isSelected, ...)`
- Selected: `DecoratedBox(decoration: BoxDecoration(border: Border.all(color: colorScheme.primary, width: 3)))`

#### 4.5.3 Empty State

```
Column (centered):
  Icon(Icons.no_photography_outlined, size: 72, color: onSurfaceVariant)
  Text("No photos found", style: headlineSmall)
  SizedBox(height: 8)
  Text("Try opening the gallery instead", style: bodyMedium, color: onSurfaceVariant)
  SizedBox(height: 16)
  Row:
    OutlinedButton("Retry Camera")
    SizedBox(width: 8)
    FilledButton("Open Gallery")
```

---

### 4.6 Page Editor

**Route:** `/capture/editor` · Out-of-shell · `PageEditorScreen`

#### 4.6.1 Layout

```
Scaffold:
  AppBar:
    leading: TextButton("Discard")
    actions: [FilledButton("Save")]
  body: Column:
    Expanded:
      ActivePagePreview             ← fills available space
    PerPageToolbar                  ← 56dp fixed height
    ThumbnailStrip                  ← 88dp fixed height
```

#### 4.6.2 Active Page Preview

- `LayoutBuilder` → fill available `constraints.maxHeight`
- `Center` → `AspectRatio(aspectRatio: 3/4)` (portrait default; ignored in landscape)
- `ClipRRect(borderRadius: BorderRadius.circular(12))`
- `Image.file(fit: BoxFit.contain)` wrapped with `ColorFiltered` when filter ≠ Original
- **Optimization:** when `filter == FilterOption.original`, omit `ColorFiltered` entirely — do not wrap in a no-op `ColorFilter.mode(Colors.transparent, BlendMode.multiply)`. Conditional: `filter == original ? Image.file(...) : ColorFiltered(colorFilter: ..., child: Image.file(...))`

##### Filter ColorMatrix Values

| Filter | ColorFilter |
|--------|------------|
| Original | `ColorFilter.mode(Colors.transparent, BlendMode.multiply)` (no-op) |
| B&W | `ColorFilter.matrix([0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0.21,0.72,0.07,0,0, 0,0,0,1,0])` |
| Grayscale | same as B&W at reduced contrast |
| Enhanced | `ColorFilter.matrix` with +20 brightness, +30 contrast |
| Warm | `ColorFilter.mode(Color(0x33FF8C00), BlendMode.softLight)` |
| Cool | `ColorFilter.mode(Color(0x330080FF), BlendMode.softLight)` |

#### 4.6.3 Per-Page Toolbar

- `Container(height: 56, color: colorScheme.surfaceContainerLow)`
- `Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly)` of 5 action items
- Each item: `Column` → `IconButton` (36dp) + `Text(label, style: labelSmall)` below

| Action | Icon | Active State |
|--------|------|-------------|
| Filter | `Icons.filter_outlined` | sheet opens |
| Crop | `Icons.crop_outlined` | crop UI opens |
| Rotate | `Icons.rotate_90_degrees_cw_outlined` | taps cycle 90°; no toggle |
| Auto-straighten | `Icons.straighten_outlined` | toggle; active = `colorScheme.primary` icon |
| Delete page | `Icons.delete_outline` | `colorScheme.error` color always |

#### 4.6.4 Thumbnail Strip

- `Container(height: 88, color: colorScheme.surfaceContainer)`
- `ReorderableListView.builder(scrollDirection: Axis.horizontal)` or `ListView.builder` with long-press drag
- **Add cell:** `SizedBox(width: 64)` → `OutlinedButton(icon: Icon(Icons.add), label: Text("Add"))` in vertical layout
- **Thumb cell:** `SizedBox(width: 64, height: 80)` → `ClipRRect(8dp)` → `Image.file(fit: BoxFit.cover)` + border when active
- **Active thumb:** `Border.all(color: colorScheme.primary, width: 3)`
- **Padding:** 8dp horizontal, 4dp vertical

#### 4.6.5 Filter Picker Sheet

- `showModalBottomSheet` at ~220dp height
- `Column`:
  - "Filter" `titleMedium` + drag handle
  - `SizedBox(height: 140)` → `ListView.builder(scrollDirection: Axis.horizontal)` of filter preview cells
  - `TextButton("Apply to all")` at bottom
- **Filter cell:** 80dp wide × 100dp — thumbnail with filter + label `labelSmall` below
- **Selected:** `Border.all(colorScheme.primary, 2dp)` on thumbnail container

#### 4.6.6 Crop UI

- Presented as full-screen overlay route or `showGeneralDialog`
- **Background:** `Colors.black87`
- **Crop preview:** centered `Image.file` with `CustomPaint` overlay for crop handles
- **Handles:** 4 corner handles (white circles 24dp) + 4 edge handles (white rectangles); `GestureDetector` on each
- **Crop mask:** `ClipPath` with `Path` cut from overlay outside crop rect
- **Toolbar:** bottom `Row`: `Switch(label: "Lock aspect")` + spacer + `TextButton("Cancel")` + `FilledButton("Confirm")`
- **Aspect options (when locked):** `SegmentedButton` with Free / 1:1 / 4:3 / 16:9

#### 4.6.7 Discard Confirmation

- `AlertDialog`:
  - title: "Discard pages?"
  - content: "All captured pages will be lost."
  - actions: `TextButton("Cancel")`, `FilledButton("Discard", style: error color)`

---

### 4.7 Metadata Form

**Route:** `/capture/metadata` · Out-of-shell · `MetadataFormScreen`

#### 4.7.1 Layout

```
Scaffold:
  AppBar:
    leading: TextButton("← Editor")
    actions: [FilledButton("Save")] — disabled when title.isEmpty
  body: SingleChildScrollView:
    Padding(16dp all):
      Column(spacing: 16):
        [form fields in order]
        SizedBox(height: safeAreaBottom)
```

#### 4.7.2 Field Specifications

| Field | Widget | Keyboard | Required | Notes |
|-------|--------|---------|---------|-------|
| Title | `TextField(decoration: OutlineInputBorder, labelText: "Title *")` | text | Yes | `errorText` shown on empty save attempt |
| Artist(s) | `ChipInputField` (§5.2) | text | No | Comma or Enter adds chip |
| Date written | `TextField` read-only + `showDatePicker` on tap, `suffixIcon: Icons.calendar_today_outlined` | none | No | Format: `dd MMM yyyy`; default today |
| Time signature | `TextField(OutlineInputBorder, labelText: "Time Signature")` | text | No | Hint text: "e.g. 4/4, 6/8, free" |
| Key signature | `TextField(OutlineInputBorder, labelText: "Key Signature")` | text | No | Hint text: "e.g. C major, Yaman" |
| Language | `Wrap` of 5 `FilterChip`s | — | No | Options: Hindi · Bengali · English · Sanskrit · Other |
| Tags | `ChipInputField` with tag suggestions (§5.2) | text | No | Type = filter existing; Enter = create new inline |
| Instruments | `Wrap` of `FilterChip`s from instrument list | — | No | Hidden if no instruments defined |
| Personal notes | `TextField(maxLines: 4, OutlineInputBorder, labelText: "Personal Notes")` | multiline | No | |
| Custom fields | per-type (see below) | varies | No | Section shown only if custom fields defined |

##### Custom Field Inputs by Type

| Type | Widget |
|------|--------|
| Text | `TextField(OutlineInputBorder)` |
| Number | `TextField(keyboardType: TextInputType.number)` |
| Date | Same as Date written field pattern |
| Boolean | `SwitchListTile(title: Text(fieldName))` |

#### 4.7.3 Save Gate

- `FilledButton("Save")` in AppBar: `onPressed: title.isEmpty ? null : _save`
- On empty title + save attempt: `setState(() => _showTitleError = true)` → `errorText: "Title is required"` on Title field
- Save sequence (from `CaptureViewModel`):
  1. Write image files via `FileStorageService`
  2. Insert `Notation` + `NotationPage` rows
  3. `context.go('/')` → Library

---

### 4.8 Settings Screen

**Route:** `/settings` · In shell · `SettingsScreen`

#### 4.8.1 Layout

- `ListView` with `ListTile`s; grouped by `Divider(indent: 0)`
- No section headers
- `ListTile(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4))`

#### 4.8.2 Row Specifications

| Row | Title Style | Subtitle | Trailing | Tap Action |
|-----|------------|---------|---------|-----------|
| Appearance | `bodyLarge` | — | `Icons.chevron_right` | `context.push('/settings/appearance')` |
| Tags | `bodyLarge` | — | `Icons.chevron_right` | `context.push('/settings/tags')` |
| Instruments | `bodyLarge` | — | `Icons.chevron_right` | `context.push('/settings/instruments')` |
| Library — Default sort | `bodyLarge` | current sort value `bodySmall onSurfaceVariant` | `Icons.chevron_right` | inline picker bottom sheet |
| Custom Fields | `bodyLarge` | — | `Icons.chevron_right` | `context.push('/settings/custom-fields')` |
| Your Name | `bodyLarge` | current name `bodySmall onSurfaceVariant` | `Icons.edit_outlined` | `showDialog` with TextField |
| Trash | `bodyLarge` | item count `bodySmall onSurfaceVariant` | `Icons.chevron_right` | `context.push('/settings/trash')` |
| About | `bodyLarge` | version string `bodySmall onSurfaceVariant` | — | no-op or expand |
| Open Source Licenses | `bodyLarge` | — | `Icons.chevron_right` | `showLicensePage()` |

#### 4.8.3 Your Name Dialog

```
AlertDialog(
  title: Text("Your name"),
  content: TextField(controller: ..., autofocus: true, decoration: OutlineInputBorder),
  actions: [TextButton("Cancel"), FilledButton("Save")],
)
```

---

### 4.9 Appearance & Theming

**Route:** `/settings/appearance` · In shell · `AppearanceScreen`

#### 4.9.1 Layout

```
AppBar: "Appearance"
ListView:
  Padding(16dp):
    Text("Theme", style: titleSmall, color: onSurfaceVariant)
  ListTile:
    title: Text("Mode", style: bodyLarge)
    trailing: SegmentedButton (3 options)
  Divider
  Padding(16dp):
    Text("Color scheme", style: titleSmall, color: onSurfaceVariant)
  RadioListTile(title: "Dynamic (Monet)", ...)
  RadioListTile(title: "Seed color", ...)
  AnimatedSwitcher → CatppuccinSwatchPicker (shown when Seed selected)
```

#### 4.9.2 Theme Mode Toggle

- `SegmentedButton<ThemeMode>` with 3 segments: Light / Dark / System
- `selected: {currentMode}`, `onSelectionChanged: _applyMode`
- Apply immediately via `AppearanceViewModel`; persist to `user_preferences` table via `PreferencesRepository`

#### 4.9.3 Catppuccin Swatch Picker

- `Padding(16dp all)` → `Wrap(spacing: 10, runSpacing: 10)` of swatch circles
- **Circle widget:** `GestureDetector(onTap: _selectSeed)` → `AnimatedContainer(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: catColor, border: isSelected ? Border.all(white, 2) : null))`
- **Selected overlay:** `Icon(Icons.check, color: Colors.white, size: 18)` centered via `Stack`
- Swatches shown: 15 Mocha in dark mode, 15 Latte in light mode
- Selecting swatch: `colorScheme = ColorScheme.fromSeed(seedColor: tapped, brightness: current)` applied immediately

---

### 4.10 Tags

#### 4.10.1 Tag List

**Route:** `/settings/tags` · In shell · `TagsScreen`

```
AppBar: "Tags"  actions: [FilledButton.tonal("+ Create")]
ListView.builder:
  each row → TagListRow
```

##### TagListRow Widget

- `ListTile`:
  - `leading`: display-only tag chip (§5.6) 
  - `title`: `Text(tag.name, style: bodyLarge)`
  - `trailing`: `Row` → `IconButton(Icons.edit_outlined)` + `IconButton(Icons.delete_outline, color: colorScheme.error)`

##### Pre-seeded Tags

- `practice` · `raag` · `song` · `classical` · `piece`
- Editable, not locked; shown at top of list

#### 4.10.2 Tag Form

**Routes:** `/settings/tags/new` · `/settings/tags/:tagId/edit` · `TagFormScreen`

```
AppBar: "New Tag" / "Edit Tag"
  actions: [FilledButton("Save")]
Padding(16dp):
  Column:
    TextField(labelText: "Name", OutlineInputBorder)
    SizedBox(16)
    Text("Color", style: labelLarge)
    SizedBox(8)
    CatppuccinColorPicker (§5.1)
```

- Save disabled when name is empty
- Color required; no default; user must pick

#### 4.10.3 Delete Tag Confirmation

```
AlertDialog:
  title: "Delete tag?"
  content: "This tag will be removed from all notations."
  actions: [TextButton("Cancel"), TextButton("Delete", style: error color)]
```

---

### 4.11 Instruments

#### 4.11.1 Instrument List

**Route:** `/settings/instruments` · In shell · `InstrumentsScreen`

```
AppBar: "Instruments"  actions: [FilledButton.tonal("+ New Class")]
ListView:
  for each class → ExpansionTile:
    title: Text(class.name, style: titleMedium)
    trailing: [TextButton("+ Add Instance"), expand/collapse icon]
    children: [InstrumentInstanceRow per instance]
```

##### InstrumentInstanceRow

- `ListTile`:
  - `leading`: Stack → 56×56dp `ClipRRect(8dp)` photo (or `Icon(Icons.music_note_outlined)` placeholder) + 4dp left-border accent (Catppuccin color)
  - `title`: `Text("${class.name}", style: titleSmall)` — shows class name as label
  - `subtitle`: `Text("${brand} ${model}", style: bodySmall)` `onSurfaceVariant`
  - `trailing`: archived badge if archived: `Chip(label: Text("Archived"), backgroundColor: errorContainer)`

#### 4.11.2 Instrument Class Form

- Presented as `showDialog` (simple single-field form) or `InstrumentClassFormScreen`
- Content: `TextField(labelText: "Instrument name", OutlineInputBorder, autofocus: true)`
- Actions: `TextButton("Cancel")`, `FilledButton("Save")`

#### 4.11.3 Instrument Instance Form

**Routes:** `/settings/instruments/instance/new` · `/settings/instruments/instance/:id/edit`

```
AppBar: "New Instrument" / "Edit Instrument"
  actions: [FilledButton("Save")]
SingleChildScrollView → Padding(16dp) → Column(spacing: 16):
  DropdownMenu<InstrumentClass>(label: "Instrument class *")
  TextField(label: "Brand")
  TextField(label: "Model")
  Row:
    Text("Color", style: labelLarge)
    CatppuccinColorPicker (§5.1)
  TextField(label: "Price (₹)", keyboardType: number, prefixText: "₹ ")
  PhotoPickerCard (see below)
  TextField(label: "Notes", maxLines: 4, OutlineInputBorder)
```

##### PhotoPickerCard

- `InkWell(onTap: _pickPhoto, child: Card.outlined(...))`
- **No photo:** `Column(Icon(Icons.add_photo_alternate_outlined, 48dp), Text("Add photo"))`
- **Has photo:** `Image.file(fit: BoxFit.cover, height: 200, width: double.infinity)` + `TextButton("Change")` overlay

#### 4.11.4 Instrument Instance Detail

**Route:** `/settings/instruments/instance/:instanceId`

```
AppBar: class.name  actions: [IconButton(Icons.edit_outlined) → edit route]
SingleChildScrollView → Padding(16dp):
  PhotoDisplay (200dp height card or placeholder)
  SizedBox(16)
  DetailRow("Instrument class", instance.className)
  DetailRow("Brand", instance.brand)
  DetailRow("Model", instance.model)
  ColorRow("Color", catColor)
  DetailRow("Price", "₹ ${instance.price}")
  DetailRow("Notes", instance.notes, multiline: true)
  SizedBox(24)
  Row:
    Expanded: FilledButton.tonal("Edit")
    SizedBox(8)
    OutlinedButton("Archive")
```

##### DetailRow Widget

- `Padding(vertical: 8)` → `Column`: `Text(label, style: labelLarge onSurfaceVariant)` + `Text(value, style: bodyLarge)` + `Divider`
- Omit row if value is null/empty

#### 4.11.5 Archive Confirmation

```
AlertDialog:
  title: "Archive instrument?"
  content: "It will no longer appear in notation pickers."
  actions: [TextButton("Cancel"), FilledButton.tonal("Archive")]
```

---

### 4.12 Trash

**Route:** `/settings/trash` · In shell · `TrashScreen`

#### 4.12.1 Layout

```
AppBar: "Trash"
  actions: [TextButton("Empty Trash", style: error color)] — hidden when empty
ListView.builder:
  each row → TrashNotationRow
```

#### 4.12.2 TrashNotationRow

- `ListTile`:
  - `leading`: 56×56dp rounded thumbnail
  - `title`: `Text(notation.title, style: titleMedium)`
  - `subtitle`: `Text("Deleted ${daysAgo} day(s) ago", style: bodySmall)` `onSurfaceVariant`
  - `trailing`: `Row` → `TextButton("Restore")` + `TextButton("Delete", style: error)`

#### 4.12.3 Empty State

```
Center:
  Column:
    Icon(Icons.delete_outline, size: 72, color: onSurfaceVariant)
    SizedBox(16)
    Text("Trash is empty", style: headlineSmall)
```

#### 4.12.4 Confirmation Dialogs

- **Delete permanently:** title "Delete permanently?", content "This cannot be undone.", actions: Cancel / Delete (error)
- **Empty trash:** title "Empty Trash?", content "All items will be permanently deleted.", actions: Cancel / Empty (error)

---

### 4.13 Custom Fields

**Route:** `/settings/custom-fields` · In shell · `CustomFieldsScreen`

#### 4.13.1 Layout

```
AppBar: "Custom Fields"  actions: [FilledButton.tonal("+ Add Field")]
ListView.builder:
  each row → CustomFieldRow
```

#### 4.13.2 CustomFieldRow

- `ListTile`:
  - `title`: `Text(field.name, style: bodyLarge)`
  - `trailing`: `Row` → `Chip(label: Text(field.type), backgroundColor: surfaceContainerHigh)` + `IconButton(Icons.edit_outlined)` + `IconButton(Icons.delete_outline, color: error)`

#### 4.13.3 Create/Edit Custom Field Sheet

```
showModalBottomSheet → Column:
  Drag handle
  Padding(16dp):
    Text("Add custom field" / "Edit custom field", style: titleMedium)
  Divider
  Padding(16dp):
    TextField(labelText: "Field name", OutlineInputBorder)
    SizedBox(16)
    Text("Type", style: labelLarge)
    SizedBox(8)
    SegmentedButton<CustomFieldType>(
      segments: [Text / Number / Date / Boolean],
    )
  Divider
  Padding(16dp):
    Row:
      TextButton("Cancel")  FilledButton("Save")
```

#### 4.13.4 Delete Confirmation

- `AlertDialog`:
  - title: "Delete field?"
  - content: "Data for this field in all notations will be lost."
  - actions: Cancel / Delete (error)

---

## 5. Component Patterns

### 5.1 Catppuccin Color Picker

**Widget:** `CatppuccinColorPicker`

```dart
Wrap(
  spacing: 10,
  runSpacing: 10,
  children: catColors.map((color) => _ColorCircle(
    color: color,
    selected: color == selectedColor,
    onTap: () => onColorSelected(color),
  )).toList(),
)
```

- **Circle dimensions:** 36×36dp
- **`_ColorCircle`:** `GestureDetector` → `AnimatedContainer(decoration: BoxDecoration(shape: circle, color: catColor, border: selected ? Border.all(Colors.white, 2) : null))`
- **Selected indicator:** `Stack` → `Icon(Icons.check, color: Colors.white, size: 18)` centered
- **Semantics:** `Semantics(label: "${colorName}, ${selected ? 'selected' : 'not selected'}")`

---

### 5.2 Chip Input Field

**Widget:** `ChipInputField`

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(colorScheme.outline),
    borderRadius: BorderRadius.circular(4),
  ),
  padding: EdgeInsets.all(8),
  child: Wrap(
    spacing: 4, runSpacing: 4,
    children: [
      ...values.map((v) => InputChip(
        label: Text(v),
        onDeleted: () => onRemove(v),
        deleteIcon: Icon(Icons.close, size: 16),
      )),
      IntrinsicWidth(child: TextField(
        controller: _inputController,
        decoration: InputDecoration.collapsed(hintText: hintText),
        onSubmitted: _addChip,
        onChanged: _onTextChanged,
      )),
    ],
  ),
)
```

- **Tag mode:** `onChanged` fires fuzzy match against tag list → shows `Overlay` with `SuggestionChip`s
- **Adding:** comma character or `TextInputAction.done` → `_addChip(input)`
- **Focus:** `FocusNode` on container; tapping container focuses internal `TextField`
- **Error border:** `colorScheme.error` outline when field is required + empty

---

### 5.3 Notation Card (Recently Played Carousel)

```dart
GestureDetector(
  onTap: onTap,
  child: SizedBox(
    width: 120, height: 160,
    child: Card.filled(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Expanded(child: Image.file(thumbnailFile, fit: BoxFit.cover, width: double.infinity)),
        SizedBox(height: 40, child: Padding(
          padding: EdgeInsets.all(8),
          child: Text(title, style: textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        )),
      ]),
    ),
  ),
)
```

---

### 5.4 Notation Row (Library List)

**Widget:** `NotationListTile`

```dart
Column(children: [
  SlideActionRow(  // wraps in swipe gesture handler
    editAction: onEdit,
    deleteAction: onDelete,
    child: ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(thumbnail, width: 56, height: 56, fit: BoxFit.cover),
      ),
      title: Text(title, style: textTheme.titleMedium),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(artists, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        if (tags.isNotEmpty) SizedBox(height: 4),
        if (tags.isNotEmpty) Wrap(spacing: 4, runSpacing: 4, children: tags.map(_buildTagChip).toList()),
      ]),
      onTap: onTap,
      onLongPress: onLongPress,
    ),
  ),
  Divider(indent: 72, height: 1),
])
```

---

### 5.5 Fanned Paper Stack

**Widget:** `FannedPageStack`

```dart
GestureDetector(
  onTap: onTap,
  child: Semantics(
    label: "View pages of $title, $pageCount pages",
    button: true,
    child: SizedBox(
      width: 240, height: 320,
      child: Stack(alignment: Alignment.center, children: [
        // Back page (rotated +8°)
        Transform.rotate(
          angle: 8 * pi / 180,
          child: Container(
            width: 200, height: 280,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(blurRadius: 4, offset: Offset(0, 2))],
            ),
          ),
        ),
        // Middle page (rotated -5°)
        Transform.rotate(
          angle: -5 * pi / 180,
          child: Container(/* same style */),
        ),
        // Front page (actual thumbnail)
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(firstPageThumbnail, width: 210, height: 296, fit: BoxFit.cover),
        ),
      ]),
    ),
  ),
)
```

- Single-page notation: show only front layer (no rotation behind)
- Placeholder when no thumbnail: `Icon(Icons.music_note_outlined, size: 72, color: onSurfaceVariant)` on `surfaceContainerHigh` background

---

### 5.6 Tag Chip (Display)

```dart
RawChip(
  label: Text(
    tag.name,
    style: textTheme.labelSmall?.copyWith(
      color: _darkenForContrast(tag.catColor),
    ),
  ),
  backgroundColor: tag.catColor.withOpacity(0.2),
  side: BorderSide(color: tag.catColor.withOpacity(0.6), width: 1),
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  isEnabled: false, // display-only; set true in filter/metadata contexts
)
```

- `_darkenForContrast`: darken Catppuccin color by 30% in light mode, lighten in dark mode to maintain ≥ 4.5:1 ratio

---

### 5.7 Error States

#### Screen-Level Error

```dart
Center(child: Padding(
  padding: EdgeInsets.all(32),
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.error_outline, size: 72, color: colorScheme.error),
    SizedBox(height: 16),
    Text(message, style: textTheme.headlineSmall, textAlign: TextAlign.center),
    if (onRetry != null) ...[
      SizedBox(height: 16),
      FilledButton.icon(icon: Icon(Icons.refresh), label: Text("Retry"), onPressed: onRetry),
    ],
  ]),
))
```

#### Inline Error (Form)

- `InputDecoration(errorText: message)` on `TextField`
- Shows below field in `colorScheme.error`

#### Error Snackbar

- `SnackBar(backgroundColor: colorScheme.errorContainer, content: Text(message, style: TextStyle(color: colorScheme.onErrorContainer)), behavior: SnackBarBehavior.floating)`

---

### 5.8 Empty States

| Screen | Icon | Headline | Body | CTA |
|--------|------|---------|------|-----|
| Library (no notations) | `Icons.music_note` 72dp `primary` | "No notations yet" | "Tap + to capture your first" | `FilledButton("Capture")` |
| Library (search miss) | `Icons.search_off` 72dp `onSurfaceVariant` | "No results" | "Try a different search term" | `TextButton("Clear search")` |
| Library (filter miss) | `Icons.filter_alt_off` 72dp `onSurfaceVariant` | "No matches" | "Try adjusting your filters" | `TextButton("Clear filters")` |
| Trash | `Icons.delete_outline` 72dp `onSurfaceVariant` | "Trash is empty" | — | — |

---

### 5.9 Snackbar Patterns

All snackbars: `SnackBar(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))`.

| Trigger | Message | Action |
|---------|---------|--------|
| Notation soft-deleted | "Moved to Trash" | `TextButton("Undo")` → restore |
| Notation restored | "Notation restored" | — |
| Notation saved (new) | "Notation saved" | — |
| Notation updated | "Changes saved" | — |
| Notation duplicated | "Notation duplicated" | — |
| Tag deleted | "Tag deleted" | — |
| Instrument archived | "Instrument archived" | — |

---

### 5.10 Dialog Patterns

All: `AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)))`.

Destructive action style: `TextButton.styleFrom(foregroundColor: colorScheme.error)`.

| Dialog | Title | Content | Actions |
|--------|-------|---------|---------|
| Delete notation | "Move to Trash?" | "This notation will be moved to Trash." | Cancel · Delete |
| Delete permanently | "Delete permanently?" | "This cannot be undone." | Cancel · Delete† |
| Discard capture | "Discard pages?" | "All captured pages will be lost." | Cancel · Discard† |
| Archive instrument | "Archive instrument?" | "It will no longer appear in pickers." | Cancel · Archive |
| Delete tag | "Delete tag?" | "Removes from all notations." | Cancel · Delete† |
| Delete custom field | "Delete field?" | "Data for this field will be lost." | Cancel · Delete† |
| Empty trash | "Empty Trash?" | "All items will be permanently deleted." | Cancel · Empty† |
| Your name | "Your name" | TextField | Cancel · Save |

† = destructive style (`colorScheme.error` foreground)

---

### 5.11 Bottom Sheet Patterns

All: `showModalBottomSheet(shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))))` + drag handle.

| Sheet | Approx Height | Widget |
|-------|-------------|--------|
| Capture entry | 200dp | `Column` of 2 `ListTile`s |
| Sort options | 350dp | `ListView` of 5 sort `ListTile`s |
| Advanced filter | 80% screen | `DraggableScrollableSheet` |
| Filter picker (Page Editor) | 220dp | Horizontal thumbnail `ListView` |
| Add Tag picker (long-press) | 300dp | `Wrap` of tag chips + Done button |
| Create custom field | 300dp | Form fields |

---

## 6. Accessibility

### 6.1 Contrast Requirements

| Text Category | Minimum Ratio | Standard |
|--------------|--------------|---------|
| Normal text (< 18pt or < 14pt bold) | 4.5:1 | WCAG 2.1 AA |
| Large text (≥ 18pt or ≥ 14pt bold) | 3:1 | WCAG 2.1 AA |
| UI component boundaries | 3:1 | WCAG 2.1 AA |
| Tag chip text on Catppuccin bg | ≥ 4.5:1 | Use `_darkenForContrast()` |
| White check icon on Catppuccin swatch | Verify per color | Some light swatches may need dark check |

---

### 6.2 Touch Targets

| Element | Min Target | Implementation |
|---------|-----------|---------------|
| All `IconButton`s | 48×48dp | `IconButton` default |
| `FilterChip` in filter row | 48dp height | `Padding` wrapper or `materialTapTargetSize: padded` |
| Catppuccin color circles | 48dp tappable | `SizedBox(48)` wrapping 36dp circle |
| Notation list rows | 80dp min height | `ListTile(minVerticalPadding: 12)` |
| Recently Played cards | 160dp height | full card is tappable |
| FAB | 56dp standard | `FloatingActionButton` default |

---

### 6.3 Semantics Labels

| Widget | Semantics.label |
|--------|----------------|
| Notation list row | "Open \<title\> by \<artist\>" |
| Recently Played card | "Recently played: \<title\>" |
| `FannedPageStack` | "View pages of \<title\>, \<N\> pages" |
| Play button (Detail) | "Play \<title\>" |
| FAB | "Capture new notation" |
| Sort `IconButton` | "Sort notations" |
| Filter chip (active) | "\<tag\> filter, active" |
| Filter chip (inactive) | "\<tag\> filter, inactive" |
| Swipe Edit badge | "Edit \<title\>" |
| Swipe Delete badge | "Delete \<title\>" |
| Catppuccin swatch | "\<color name\>, \<selected/not selected\>" |
| Thumbnail in editor | "Page \<N\> of \<total\>" |
| Player page | "Notation page \<N\> of \<total\>, \<title\>" |

---

### 6.4 TalkBack-Specific Implementation

- `MergeSemantics` on `NotationListTile` to read as single unit
- `ExcludeSemantics` on decorative bottom layers of `FannedPageStack`
- All `Image.file` thumbnails: `semanticLabel: "Thumbnail of \<title\>"` or `semanticLabel: ""` (if decorative-only)
- Player page swipe: `Semantics(onIncrease: nextPage, onDecrease: prevPage)` on `PageView`
- Form fields: `Semantics(label: fieldName)` where label is not visible due to autofocus/collapsed state

---

## 7. Orientation & Layout

### 7.1 Portrait (Primary)

- All screens designed portrait-first
- `LibraryScreen`, `NotationDetailScreen`, `SettingsScreen` and sub-screens: standard `Scaffold` + `NavigationBar`
- `PageEditorScreen`: portrait default; thumbnail strip at bottom
- `MetadataFormScreen`: `SingleChildScrollView`; form fields stacked vertically

### 7.2 Landscape — Player

- `PlayerScreen`: full-screen in both orientations
- **Portrait player:** toolbar at bottom, title at top, page indicator above toolbar
- **Landscape player:** toolbar moves to right-side vertical column; page indicator at bottom-center; title at top-left
- Layout via `OrientationBuilder(builder: (context, orientation) => ...)`

```dart
OrientationBuilder(builder: (context, orientation) {
  if (orientation == Orientation.landscape) {
    return Stack(children: [
      PageView(...),          // full screen
      Positioned(top: ..., left: ..., right: ..., child: _titleOverlay),
      Positioned(bottom: ..., child: _pageIndicator),
      Positioned(top: ..., right: ..., bottom: ..., child: _verticalToolbar),
    ]);
  }
  return Stack(children: [
    PageView(...),
    Positioned(top: ..., child: _titleOverlay),
    Positioned(bottom: ..., child: Column(children: [_pageIndicator, _horizontalToolbar])),
  ]);
})
```

### 7.3 Orientation Lock (Player)

```dart
// Lock portrait
await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

// Unlock all
await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
```

- Lock persisted only for current player session; restored to `DeviceOrientation.values` on `PlayerScreen` dispose

### 7.4 Safe Areas

- `SafeArea` wrapping all `Scaffold.body` content
- Player: `MediaQuery.of(context).padding` used manually (no `SafeArea` — full-screen immersive mode)
- Bottom sheets: `SizedBox(height: MediaQuery.of(context).viewInsets.bottom)` for keyboard avoidance in form sheets
