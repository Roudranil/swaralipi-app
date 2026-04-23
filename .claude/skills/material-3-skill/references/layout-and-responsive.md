# MD3 Layout and Responsive Design

Reference for Material Design 3's layout system: breakpoints, canonical layouts, and responsive implementation.

## Flutter and Adaptive Layout

Use **`MediaQuery.sizeOf(context).width`** to determine window size class at runtime. For more complex adaptive UI, the `flutter_adaptive_scaffold` package provides ready-made adaptive layout widgets.

**Edge-to-edge:** Flutter handles system bar padding via `MediaQuery.padding` and `SafeArea`. Use `Scaffold` with appropriate properties for status bar and navigation bar insets. The `MediaQuery.viewInsetsOf(context).bottom` gives IME (keyboard) height.

**Foldables:** Use `MediaQuery.displayFeatures` to detect hinges and folds. See the foldable section below.

---

## Window Size Classes

MD3 defines 5 breakpoint classes:

| Class | Width Range | Typical Devices | Columns |
|-------|-----------|----------------|---------|
| Compact | < 600dp | Phone portrait | 4 |
| Medium | 600–839dp | Tablet portrait, foldable | 8 |
| Expanded | 840–1199dp | Tablet landscape, small desktop | 12 |
| Large | 1200–1599dp | Desktop | 12 |
| Extra-large | 1600dp+ | Ultra-wide, large desktop | 12 |

### Flutter Breakpoints

```dart
double width = MediaQuery.sizeOf(context).width;

if (width < 600) {
  // Compact: phone portrait — NavigationBar, single column
} else if (width < 840) {
  // Medium: tablet portrait — NavigationRail, 2 columns
} else if (width < 1200) {
  // Expanded: tablet landscape — NavigationDrawer, 3 columns
} else if (width < 1600) {
  // Large: desktop — 4 columns, constrain max width
} else {
  // Extra-large: ultra-wide — 3 panes or generous margins
}
```

## Layout Anatomy

### Key Terms

- **Window**: The visible area of the app
- **Pane**: A layout container within the window. A pane is fixed, flexible, floating, or semi-permanent
- **Column**: A vertical content block within a pane
- **Margin**: Space between screen edge and content
- **Gutter**: Space between columns
- **Spacer**: Space between panes (in multi-pane layouts)

### Margin and Gutter Values

| Window Size | Margins | Gutters |
|-------------|---------|---------|
| Compact | 16dp | 8dp |
| Medium | 24dp | 16dp |
| Expanded | 24dp | 16dp |
| Large | 24dp | 24dp |
| Extra-large | 24dp | 24dp |

## Canonical Layouts

MD3 defines 3 canonical layouts as starting points. Always begin from one of these rather than from a raw grid.

### Feed Layout

**Use when**: Displaying a large collection of browsable items (social feed, news, product grid).

```
Compact:    Single column of cards
Medium:     2-column grid
Expanded:   3-column grid
Large:      4-column grid + optional side panel
```

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final width = constraints.maxWidth;
    final crossAxisCount = width < 600 ? 1
        : width < 840 ? 2
        : width < 1200 ? 3
        : 4;
    final padding = width < 600 ? 16.0 : 24.0;
    final spacing = width < 600 ? 8.0 : 16.0;

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      ),
      itemBuilder: (context, index) => const FeedCard(),
      itemCount: items.length,
    );
  },
)
```

### List-Detail Layout

**Use when**: Browsing a list of items where each has detailed content (email, file browser, contacts).

```
Compact:    List view OR detail view (navigate between them)
Medium:     Side-by-side list (1/3) + detail (2/3)
Expanded:   Side-by-side with wider detail pane
```

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isNarrow = constraints.maxWidth < 600;

    if (isNarrow) {
      // Compact: show one pane at a time
      return selectedItem == null
          ? ListPane(onItemSelected: (item) => setState(() => selectedItem = item))
          : DetailPane(
              item: selectedItem!,
              onBack: () => setState(() => selectedItem = null),
            );
    }

    // Medium+: side by side
    return Row(
      children: [
        SizedBox(
          width: constraints.maxWidth >= 840 ? 400 : 360,
          child: ListPane(
            onItemSelected: (item) => setState(() => selectedItem = item),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: selectedItem != null
              ? DetailPane(item: selectedItem!)
              : const Center(child: Text('Select an item')),
        ),
      ],
    );
  },
)
```

### Supporting Pane Layout

**Use when**: Primary content needs supplementary information (document + properties panel, video + comments).

```
Compact:    Stacked — primary on top, supporting below (or bottom sheet)
Medium:     Side-by-side (2/3 primary + 1/3 supporting)
Expanded:   Same but with more space
```

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 600) {
      // Compact: stacked
      return Column(
        children: [
          Expanded(flex: 2, child: PrimaryContent()),
          Expanded(flex: 1, child: SupportingContent()),
        ],
      );
    }

    // Medium+: side by side
    return Row(
      children: [
        Expanded(flex: 2, child: PrimaryContent()),
        const SizedBox(width: 24),
        Expanded(flex: 1, child: SupportingContent()),
      ],
    );
  },
)
```

## Adaptive Component Behavior

Components transform across breakpoints:

| Component | Compact | Medium (incl. foldable unfolded) | Expanded+ / Large screen |
|-----------|---------|--------|-----------|
| Navigation | Bottom bar | Side rail | Side drawer |
| App bar | Small (64dp) | Small (64dp) | Small or Medium (112dp) |
| Dialog | Full-screen | Centered dialog | Centered dialog (max 560dp wide) |
| Bottom sheet | Full height | Partial height | Side sheet |
| Search | Full-screen search view | Persistent search bar | Persistent search bar |
| Cards | Full-width single column | Multi-column grid | Multi-column grid (max 4 cols) |
| Content panes | Single pane | Optional second pane | Two or three panes |
| Input method | Touch only | Touch + stylus | Touch + mouse/trackpad + keyboard |

## Complete App Layout Example

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final isExpanded = width >= 840;
  final isMedium = width >= 600;

  return Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    body: Row(
      children: [
        // Side navigation for medium+
        if (isExpanded)
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onNav,
            children: drawerDestinations,
          )
        else if (isMedium)
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onNav,
            labelType: NavigationRailLabelType.all,
            destinations: railDestinations,
          ),
        // Content area
        Expanded(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: width >= 1200 ? 1040 : double.infinity,
            ),
            child: pages[selectedIndex],
          ),
        ),
      ],
    ),
    // Bottom nav for compact only
    bottomNavigationBar: isExpanded || isMedium
        ? null
        : NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onNav,
            destinations: barDestinations,
          ),
  );
}
```

## Foldables and Large Screens

MD3 provides specific guidance for foldable devices, tablets, and large-screen form factors. These are first-class targets in Material Design 3 — not afterthoughts.

### Foldable Postures

Foldable devices introduce postures that don't exist on traditional phones:

| Posture | Description | Layout behavior |
|---------|-------------|----------------|
| **Flat (unfolded)** | Device fully open, single large screen | Treat as Medium or Expanded window class based on width |
| **Half-opened (tabletop)** | Folded ~90° horizontally, bottom half on table | Split content at the hinge — video/image on top half, controls/info on bottom half |
| **Half-opened (book)** | Folded ~90° vertically, held like a book | Split content at the hinge — list on one side, detail on the other |
| **Folded** | Device closed, outer/cover screen | Treat as Compact — show essential content only |

### Hinge-Aware Layouts

The fold/hinge is a physical divider. Never place interactive content or critical information across the hinge area.

**Flutter — `MediaQuery` and display features:**

```dart
Widget build(BuildContext context) {
  final displayFeatures = MediaQuery.of(context).displayFeatures;
  final hinge = displayFeatures.whereType<DisplayFeature>().where(
    (f) => f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold,
  ).firstOrNull;

  if (hinge != null) {
    // Foldable device — split at the hinge
    return TwoPane(
      startPane: ListPane(),
      endPane: DetailPane(),
      paneProportion: 0.5,
      panePriority: isPortrait ? TwoPanePriority.start : TwoPanePriority.both,
    );
  }

  // Single screen — use window size class
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return CompactLayout();
  if (width < 840) return MediumLayout();
  return ExpandedLayout();
}
```

### Tabletop Posture Pattern

When the device is in tabletop posture (horizontal fold, bottom half resting on a surface), the content naturally divides into two halves:

```
┌─────────────────────┐
│                     │  ← Top half: visual content
│   Video / Image /   │     (camera viewfinder, video player,
│   Primary content   │      image gallery, map)
│                     │
├─ ─ ─ hinge ─ ─ ─ ─ ┤
│                     │  ← Bottom half: controls & info
│  Controls / Text /  │     (playback controls, chat input,
│  Supporting info    │      product details, toolbar)
│                     │
└─────────────────────┘
```

### Book Posture Pattern

When the device is in book posture (vertical fold, held like a book), it naturally maps to list-detail:

```
┌──────────┬──────────┐
│          │          │
│  List /  │  Detail  │
│  Nav /   │  Content │
│  Browse  │  / Edit  │
│          │          │
└──────────┴──────────┘
         hinge
```

### Large Screen Layout Guidance

For tablets, Chromebooks, desktop, and large foldables (Expanded, Large, Extra-large):

**Content width constraints:**
- Don't stretch content to fill ultra-wide screens — reading lines longer than ~80 characters become hard to scan
- Constrain body content to a max width (typically 840–1040dp) and center it
- Use the extra space for multi-pane layouts, not wider single columns

```dart
// Constrain content on large screens
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 1040),
  child: Center(child: contentWidget),
)
```

**Multi-pane strategies by window class:**

| Window class | Columns | Recommended layout |
|-------------|---------|-------------------|
| Compact (<600dp) | 4 | Single pane. Full-screen navigation between views. |
| Medium (600–839dp) | 8 | Optional second pane. List-detail with narrow list. Rail navigation. |
| Expanded (840–1199dp) | 12 | Two panes standard. List-detail or supporting pane. Drawer navigation. |
| Large (1200–1599dp) | 12 | Two or three panes. Feed with side panel. Persistent supporting pane. |
| Extra-large (1600dp+) | 12 | Three panes or constrained two-pane with generous margins. |

**Adaptive input in Flutter:**

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  final isLargeScreen = width >= 840;

  return Scaffold(
    body: Row(
      children: [
        // Navigation adapts
        if (isLargeScreen)
          NavigationRail(
            destinations: destinations,
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            labelType: NavigationRailLabelType.all,
            leading: FloatingActionButton(
              onPressed: onCompose,
              child: const Icon(Icons.edit),
            ),
          ),
        // Content fills remaining space
        Expanded(
          child: isLargeScreen
              ? Row(
                  children: [
                    SizedBox(width: 360, child: ListPane()),
                    const VerticalDivider(width: 1),
                    Expanded(child: DetailPane()),
                  ],
                )
              : selectedItem == null
                  ? ListPane()
                  : DetailPane(),
        ),
      ],
    ),
    bottomNavigationBar: isLargeScreen
        ? null
        : NavigationBar(
            destinations: destinations.map((d) =>
              NavigationDestination(icon: d.icon, label: d.label)).toList(),
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
          ),
  );
}
```

### Foldable-Aware Canonical Layouts

The three canonical layouts adapt naturally to foldables:

| Layout | Foldable behavior |
|--------|------------------|
| **Feed** | Unfolded: multi-column grid fills both halves. Tabletop: grid on top, selected item preview on bottom. |
| **List-detail** | Book posture: list on left half, detail on right half — a perfect natural fit. Tabletop: list on top, detail on bottom. |
| **Supporting pane** | Book posture: primary on left, supporting on right. Tabletop: primary on top, supporting controls on bottom. |

### Testing Large Screens and Foldables

**Flutter:**
- Use `DevicePreview` package to simulate foldables and tablets
- Test with `MediaQuery` overrides for `displayFeatures`
- Run on Android emulators: Pixel Fold, 7.6" foldable, 10" tablet, Chromebook

### Audit Checklist for Foldable/Large Screen Support

When auditing, check these specific items:

- [ ] App uses `MediaQuery.sizeOf(context).width` to determine window size class
- [ ] Layout switches from single-pane to multi-pane at 600dp
- [ ] Navigation transforms: bottom bar → rail → drawer across breakpoints
- [ ] Content has max-width constraint on large screens (not stretching to fill)
- [ ] No critical content or interactive elements placed across a fold/hinge
- [ ] Foldable postures handled (if targeting foldable devices): tabletop and book modes
- [ ] Hover/focus states exist for pointer devices (use `MouseRegion` and `InkWell`)
- [ ] Touch targets remain 48dp minimum even on large screens
- [ ] Dialogs are centered (not full-screen) on medium+ screens
- [ ] Bottom sheets convert to side sheets on expanded+ screens

## Spacing System

MD3 uses a 4dp base grid for spacing:

| Use | Values |
|-----|--------|
| Component internal padding | 4, 8, 12, 16, 24dp |
| Between components | 8, 12, 16, 24dp |
| Section spacing | 24, 32, 48dp |
| Layout margins | 16dp (compact), 24dp (medium+) |
| Grid gutters | 8dp (compact), 16dp (medium), 24dp (large+) |

Always use multiples of 4dp for consistent spatial rhythm. In Flutter, use `SizedBox(height: X)` or `EdgeInsets.all(X)` with these values.
