# MD3 Navigation Patterns

Guide for choosing and implementing Material Design 3 navigation components.

## Flutter (primary)

Use `package:flutter/material.dart`: `NavigationBar`, `NavigationRail`, `NavigationDrawer`, `NavigationDrawerDestination`, `Drawer`, `AppBar`, and **`Scaffold`** (`bottomNavigationBar`, `floatingActionButton`, `endDrawer`).

Wire destinations with **Navigator** or a routing package like `go_router`. For **adaptive** UIs, check `MediaQuery.sizeOf(context).width` to switch between navigation components across breakpoints.

```dart
// Conceptual — adapt routes and selection to your app
Scaffold(
  bottomNavigationBar: NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: (index) {
      setState(() => currentIndex = index);
      // Navigate to route
    },
    destinations: destinations.map((dest) => NavigationDestination(
      icon: dest.icon,
      selectedIcon: dest.selectedIcon,
      label: dest.label,
    )).toList(),
  ),
  body: pages[currentIndex],
)
```

---

## Navigation Component Selection

### Decision Tree

```
How many primary destinations?
├── 2 destinations → Tabs (primary)
├── 3–5 destinations
│   ├── Compact screen (<600dp) → NavigationBar (bottom)
│   ├── Medium screen (600–839dp) → NavigationRail (side)
│   └── Expanded+ screen (840dp+) → NavigationDrawer (side) or Rail
├── 6+ destinations
│   ├── Compact → NavigationDrawer (modal via Scaffold.drawer)
│   ├── Medium → NavigationDrawer (standard) or Rail + overflow menu
│   └── Expanded+ → NavigationDrawer (standard)
└── Hierarchical (nested sections)
    └── NavigationDrawer with sections
```

### Quick Reference

| Component | Destinations | Screen Size | Persistence | Position |
|-----------|-------------|-------------|-------------|----------|
| NavigationBar | 3–5 | Compact | Persistent | Bottom |
| NavigationRail | 3–7 | Medium | Persistent | Side (start) |
| NavigationDrawer | Unlimited | Expanded+ | Standard or Modal | Side (start) |
| TabBar | 2+ related views | Any | Persistent | Top (below app bar) |

## Navigation Bar

**Use when**: 3–5 primary destinations on compact (mobile) screens.
**Position**: Bottom of screen, always visible.

### Anatomy
- Fixed at bottom, full width
- 3–5 navigation destinations with icon + label
- Active destination shows filled icon + indicator pill
- Height: 80dp

### Implementation

```dart
NavigationBar(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => setState(() => selectedIndex = index),
  destinations: const [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: 'Search',
    ),
    NavigationDestination(
      icon: Icon(Icons.notifications_outlined),
      selectedIcon: Icon(Icons.notifications),
      label: 'Notifications',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ],
)
```

### Guidelines
- Always show labels (don't use icon-only)
- Use filled icons for active state, outlined for inactive
- Don't use for fewer than 3 or more than 5 destinations
- Elevation level 2 (3dp)

## Navigation Rail

**Use when**: 3–7 primary destinations on medium screens (tablets).
**Position**: Start edge (left in LTR), always visible.

### Anatomy
- Width: 80dp
- Optional FAB at top
- Destinations vertically stacked
- Active destination shows indicator pill

### Implementation

```dart
NavigationRail(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => setState(() => selectedIndex = index),
  labelType: NavigationRailLabelType.all,
  leading: FloatingActionButton.small(
    onPressed: () {},
    tooltip: 'Compose',
    child: const Icon(Icons.edit),
  ),
  destinations: const [
    NavigationRailDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: Text('Home'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.search_outlined),
      selectedIcon: Icon(Icons.search),
      label: Text('Search'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: Text('Settings'),
    ),
  ],
)
```

### Guidelines
- Show labels always (optional to hide, but recommended to show)
- FAB at top is optional but common
- Elevation level 0

## Navigation Drawer

**Use when**: Many destinations, expanded screens, or deep hierarchies.
**Position**: Start edge, standard (persistent) or modal (via `Scaffold.drawer`).

### Standard Drawer (Persistent)

Always visible alongside content. Width: 360dp.

```dart
// In your Scaffold body — place NavigationDrawer in a Row
Row(
  children: [
    NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => setState(() => selectedIndex = index),
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text('App Name'),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: Text('Inbox'),
          badge: Badge(label: Text('24')),
        ),
        const NavigationDrawerDestination(
          icon: Icon(Icons.send_outlined),
          selectedIcon: Icon(Icons.send),
          label: Text('Sent'),
        ),
        const Divider(indent: 28, endIndent: 28),
        const NavigationDrawerDestination(
          icon: Icon(Icons.drafts_outlined),
          selectedIcon: Icon(Icons.drafts),
          label: Text('Drafts'),
        ),
      ],
    ),
    Expanded(child: mainContent),
  ],
)
```

### Modal Drawer (Overlay)

Overlays content with a scrim. Used on smaller screens or when content space is limited.

```dart
Scaffold(
  drawer: NavigationDrawer(
    selectedIndex: selectedIndex,
    onDestinationSelected: (index) {
      setState(() => selectedIndex = index);
      Navigator.pop(context); // close drawer
    },
    children: const [/* same as above */],
  ),
  appBar: AppBar(
    // Scaffold automatically adds the menu button to leading
    title: const Text('My App'),
  ),
  body: mainContent,
)
```

### Guidelines
- Standard drawer uses `surfaceContainer` background
- Modal drawer has elevation level 1 and scrim overlay
- Group destinations with dividers and section headers
- Active destination uses `secondaryContainer` background
- Shape: `large` on end corners (right edge in LTR)

## Top App Bar

**Use when**: Every screen needs a title and optional actions.

### Variants

| Variant | Widget | Height | Scroll Behavior |
|---------|--------|--------|----------------|
| Center-aligned | `AppBar(centerTitle: true)` | 64dp | Elevates to level 2 on scroll |
| Small | `AppBar(centerTitle: false)` | 64dp | Elevates to level 2 on scroll |
| Medium | `SliverAppBar.medium(...)` | 112dp | Collapses to 64dp on scroll |
| Large | `SliverAppBar.large(...)` | 152dp | Collapses to 64dp on scroll |

### Implementation

```dart
// Small app bar
AppBar(
  leading: IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () => Scaffold.of(context).openDrawer(),
  ),
  title: const Text('Page Title'),
  actions: [
    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
    IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
  ],
)

// Medium app bar (scroll to collapse)
CustomScrollView(
  slivers: [
    SliverAppBar.medium(
      leading: BackButton(),
      title: const Text('Page Title'),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    ),
    SliverFillRemaining(child: /* page content */),
  ],
)
```

## Tabs

**Use when**: Switching between related content at the same hierarchy level.

### Primary vs Secondary

- **Primary tabs**: Top-level content switching (Flights / Hotels / Explore)
- **Secondary tabs**: Sub-sections within primary content

```dart
// Primary tabs
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      bottom: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.flight), text: 'Flights'),
          Tab(text: 'Hotels'),
          Tab(text: 'Car Rental'),
        ],
      ),
    ),
    body: const TabBarView(
      children: [FlightsPage(), HotelsPage(), CarPage()],
    ),
  ),
)

// Secondary tabs (nested under primary)
const TabBar(
  isScrollable: true,
  tabs: [
    Tab(text: 'Overview'),
    Tab(text: 'Reviews'),
    Tab(text: 'Photos'),
  ],
)
```

## Responsive Navigation Pattern

The key MD3 pattern: navigation component transforms across breakpoints.

### Compact → Medium → Expanded

```
Compact (<600dp):   NavigationBar (bottom)
Medium (600–839dp): NavigationRail (side)
Expanded (840dp+):  NavigationDrawer (side, standard)
```

### Flutter Implementation

```dart
Widget build(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;

  if (width >= 840) {
    // Expanded: Navigation Drawer
    return Scaffold(
      body: Row(
        children: [
          NavigationDrawer(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            children: drawerChildren,
          ),
          Expanded(child: _currentPage),
        ],
      ),
    );
  } else if (width >= 600) {
    // Medium: Navigation Rail
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: railDestinations,
          ),
          Expanded(child: _currentPage),
        ],
      ),
    );
  } else {
    // Compact: Navigation Bar
    return Scaffold(
      body: _currentPage,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: barDestinations,
      ),
    );
  }
}
```
