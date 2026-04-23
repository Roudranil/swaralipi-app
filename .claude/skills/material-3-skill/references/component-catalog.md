# MD3 Component Catalog

Complete reference for Material Design 3 components. **Primary:** Flutter (`package:flutter/material.dart`) — all components use Material 3 automatically when `useMaterial3: true` is set in `ThemeData`.

## Actions

### Buttons

MD3 has 5 button types ordered by emphasis: Filled > Filled Tonal > Elevated > Outlined > Text.

#### Filled Button
**Widget**: `FilledButton`
**Use when**: Primary action, highest emphasis.

```dart
FilledButton(
  onPressed: () {},
  child: const Text('Get started'),
)

FilledButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.arrow_forward),
  label: const Text('Sign up'),
)
```

#### Filled Tonal Button
**Widget**: `FilledButton.tonal`
**Use when**: Medium emphasis, softer than filled. Secondary actions alongside a filled button.

```dart
FilledButton.tonal(
  onPressed: () {},
  child: const Text('Save draft'),
)
```

#### Elevated Button
**Widget**: `ElevatedButton`
**Use when**: Medium emphasis with shadow. Use on colored backgrounds where tonal button blends in.

```dart
ElevatedButton(
  onPressed: () {},
  child: const Text('Add to cart'),
)
```

#### Outlined Button
**Widget**: `OutlinedButton`
**Use when**: Medium emphasis, neutral. Good for secondary actions.

```dart
OutlinedButton(
  onPressed: () {},
  child: const Text('Cancel'),
)
```

#### Text Button
**Widget**: `TextButton`
**Use when**: Lowest emphasis. Inline actions, dialog actions, less important options.

```dart
TextButton(
  onPressed: () {},
  child: const Text('Learn more'),
)
```

#### Button Sizes (Expressive)
Buttons now support 5 sizes. Adjust via `ButtonStyle`:
```dart
FilledButton(
  style: FilledButton.styleFrom(
    minimumSize: const Size(0, 32), // XS
    // minimumSize: const Size(0, 40), // S (default)
    // minimumSize: const Size(0, 48), // M
    // minimumSize: const Size(0, 56), // L
    // minimumSize: const Size(0, 64), // XL
  ),
  onPressed: () {},
  child: const Text('Button'),
)
```

**A11y**: Buttons have built-in semantics. Use `Semantics(label: ...)` when icon-only. Minimum touch target 48×48dp.

### Segmented Button
**Widget**: `SegmentedButton<T>`
**Use when**: Grouping related actions or selections with connected visual treatment.

```dart
SegmentedButton<String>(
  segments: const [
    ButtonSegment(value: 'day', label: Text('Day')),
    ButtonSegment(value: 'week', label: Text('Week')),
    ButtonSegment(value: 'month', label: Text('Month')),
  ],
  selected: {selectedValue},
  onSelectionChanged: (newSelection) {
    setState(() => selectedValue = newSelection.first);
  },
)
```

### FAB (Floating Action Button)
**Widget**: `FloatingActionButton`
**Use when**: The single most important action on a screen.

| Parameter | Type | Description |
|-----------|------|-------------|
| `onPressed` | VoidCallback? | Action callback |
| `child` | Widget? | Icon widget |
| `tooltip` | String? | Accessibility label |

```dart
// Standard FAB
FloatingActionButton(
  onPressed: () {},
  tooltip: 'Create new',
  child: const Icon(Icons.add),
)

// Small FAB
FloatingActionButton.small(
  onPressed: () {},
  tooltip: 'Edit',
  child: const Icon(Icons.edit),
)

// Large FAB
FloatingActionButton.large(
  onPressed: () {},
  child: const Icon(Icons.add),
)
```

**A11y**: Always provide `tooltip` since FABs are typically icon-only.

### Extended FAB
**Widget**: `FloatingActionButton.extended`
**Use when**: Primary action with explanatory text.

```dart
FloatingActionButton.extended(
  onPressed: () {},
  icon: const Icon(Icons.edit),
  label: const Text('New message'),
)
```

### Icon Button
**Widget**: `IconButton` (4 variants)

| Variant | Widget |
|---------|--------|
| Standard | `IconButton` |
| Filled | `IconButton.filled` |
| Filled Tonal | `IconButton.filledTonal` |
| Outlined | `IconButton.outlined` |

```dart
IconButton(
  onPressed: () {},
  icon: const Icon(Icons.settings),
  tooltip: 'Settings',
)

// Toggle icon button (like/unlike)
IconButton(
  isSelected: isLiked,
  onPressed: () => setState(() => isLiked = !isLiked),
  icon: const Icon(Icons.favorite_border),
  selectedIcon: const Icon(Icons.favorite),
  tooltip: 'Favorite',
)
```

**A11y**: Always provide `tooltip`. Toggle buttons should have descriptive tooltips for both states.

### Split Button
Not yet available as a built-in Flutter M3 widget. Implement with custom widgets using `ButtonBar` or `Row` with MD3 tokens.

## Communication

### Badge
**Widget**: `Badge`

```dart
// Small dot badge
Badge(
  child: IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () {},
  ),
)

// Large count badge
Badge(
  label: const Text('3'),
  child: IconButton(
    icon: const Icon(Icons.notifications),
    onPressed: () {},
  ),
)
```

### Progress Indicator
**Widgets**: `LinearProgressIndicator`, `CircularProgressIndicator`

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | double? | Progress (0.0–1.0); null = indeterminate |

```dart
// Determinate
LinearProgressIndicator(value: 0.6)
CircularProgressIndicator(value: 0.75)

// Indeterminate
const LinearProgressIndicator()
const CircularProgressIndicator()
```

**A11y**: Wrap in `Semantics(label: 'Loading messages')` for screen reader context.

### Snackbar
**Widget**: `SnackBar` (shown via `ScaffoldMessenger`)

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Message sent'),
    action: SnackBarAction(
      label: 'Undo',
      onPressed: () {},
    ),
  ),
)
```

### Tooltip
**Widget**: `Tooltip`

Two types:
- **Plain**: Short text label. Wrap any widget.
- **Rich**: Use `TooltipTheme` or custom overlay for multi-line with actions.

```dart
Tooltip(
  message: 'Settings',
  child: IconButton(
    icon: const Icon(Icons.settings),
    onPressed: () {},
  ),
)
```

## Containment

### Card
**Widget**: `Card` (3 variants)

| Variant | Widget | Appearance |
|---------|--------|-----------|
| Filled | `Card.filled` | surfaceContainerHighest fill |
| Outlined | `Card.outlined` | Surface fill, outlineVariant border |
| Elevated | `Card` | surfaceContainerLow fill, shadow |

```dart
// Outlined card
Card.outlined(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Supporting text',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      OverflowBar(
        alignment: MainAxisAlignment.end,
        children: [
          FilledButton.tonal(onPressed: () {}, child: const Text('Action')),
        ],
      ),
    ],
  ),
)

// Filled card
Card.filled(child: /* content */)

// Elevated card (default Card)
Card(child: /* content */)
```

### Dialog
**Widget**: `AlertDialog` (shown via `showDialog`)

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | Widget? | Dialog headline |
| `content` | Widget? | Dialog body |
| `actions` | List<Widget>? | Action buttons |

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirm action'),
    content: const Text('Are you sure you want to proceed?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.tonal(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Confirm'),
      ),
    ],
  ),
)
```

**A11y**: `AlertDialog` automatically announces title via semantics.

### Bottom Sheet
**Widgets**: `showModalBottomSheet`, `showBottomSheet`

```dart
// Modal bottom sheet
showModalBottomSheet(
  context: context,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    builder: (context, scrollController) => ListView(
      controller: scrollController,
      children: const [/* content */],
    ),
  ),
)

// Standard (persistent) bottom sheet
Scaffold(
  // ...
  bottomSheet: BottomSheet(
    onClosing: () {},
    builder: (context) => const Text('Persistent sheet'),
  ),
)
```

### Side Sheet
Not yet available as a built-in Flutter M3 widget. Use `Drawer` with custom width or a `Row`-based layout with an animated panel.

### Divider
**Widget**: `Divider`

```dart
const Divider()                           // Full-width
const Divider(indent: 16, endIndent: 16) // Inset
const VerticalDivider()                   // Vertical
```

### Carousel
Not yet available as a built-in Flutter M3 widget. Use `PageView` or a third-party carousel package styled with MD3 tokens.

## Input

### Checkbox
**Widget**: `Checkbox`

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | bool? | Checked state (null = indeterminate) |
| `onChanged` | ValueChanged<bool?>? | Change callback |
| `tristate` | bool | Enable indeterminate state |

```dart
Row(
  children: [
    Checkbox(
      value: isChecked,
      onChanged: (value) => setState(() => isChecked = value ?? false),
    ),
    const Text('Accept terms'),
  ],
)
```

**A11y**: Wrap in a `Row` with a `GestureDetector` + `Semantics` or use `CheckboxListTile` for built-in label association.

### Chips
**Widgets**: `ActionChip`, `FilterChip`, `InputChip`, `SuggestionChip`

| Variant | Widget | Use |
|---------|--------|-----|
| Assist | `ActionChip` | Smart suggestions, shortcuts |
| Filter | `FilterChip` | Filtering content, multi-select |
| Input | `InputChip` | User input tokens (email recipients) |
| Suggestion | `SuggestionChip` | Suggested responses, queries |

```dart
Wrap(
  spacing: 8,
  children: [
    FilterChip(
      label: const Text('Vegetarian'),
      selected: isVegetarian,
      onSelected: (value) => setState(() => isVegetarian = value),
    ),
    FilterChip(
      label: const Text('Vegan'),
      selected: isVegan,
      onSelected: (value) => setState(() => isVegan = value),
    ),
  ],
)

// Input chip
InputChip(
  label: const Text('user@example.com'),
  onDeleted: () => removeChip(),
)
```

### Menu
**Widget**: `MenuAnchor` + `MenuItemButton`

```dart
MenuAnchor(
  builder: (context, controller, child) => FilledButton(
    onPressed: () => controller.isOpen ? controller.close() : controller.open(),
    child: const Text('Options'),
  ),
  menuChildren: [
    MenuItemButton(
      leadingIcon: const Icon(Icons.edit),
      child: const Text('Edit'),
      onPressed: () {},
    ),
    MenuItemButton(
      leadingIcon: const Icon(Icons.delete),
      child: const Text('Delete'),
      onPressed: () {},
    ),
  ],
)
```

### Radio Button
**Widget**: `Radio<T>`

```dart
Column(
  children: [
    RadioListTile<String>(
      title: const Text('Small'),
      value: 's',
      groupValue: selectedSize,
      onChanged: (value) => setState(() => selectedSize = value!),
    ),
    RadioListTile<String>(
      title: const Text('Medium'),
      value: 'm',
      groupValue: selectedSize,
      onChanged: (value) => setState(() => selectedSize = value!),
    ),
  ],
)
```

**A11y**: Use `RadioListTile` for built-in label association, or wrap `Radio` with `Semantics`.

### Slider
**Widget**: `Slider`, `RangeSlider`

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | double | Current value |
| `min` | double | Minimum value |
| `max` | double | Maximum value |
| `divisions` | int? | Discrete steps |
| `label` | String? | Value label on thumb |
| `onChanged` | ValueChanged<double>? | Change callback |

```dart
// Continuous
Slider(
  value: volume,
  min: 0,
  max: 100,
  onChanged: (value) => setState(() => volume = value),
)

// Discrete with label
Slider(
  value: rating,
  min: 1,
  max: 10,
  divisions: 9,
  label: rating.round().toString(),
  onChanged: (value) => setState(() => rating = value),
)

// Range
RangeSlider(
  values: priceRange,
  min: 0,
  max: 100,
  onChanged: (values) => setState(() => priceRange = values),
)
```

### Switch
**Widget**: `Switch`

| Parameter | Type | Description |
|-----------|------|-------------|
| `value` | bool | On state |
| `onChanged` | ValueChanged<bool>? | Change callback |
| `thumbIcon` | WidgetStateProperty<Icon?>? | On/off icons |

```dart
SwitchListTile(
  title: const Text('Dark mode'),
  value: isDarkMode,
  onChanged: (value) => setState(() => isDarkMode = value),
)

// With icons
Switch(
  value: isEnabled,
  onChanged: (value) => setState(() => isEnabled = value),
  thumbIcon: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.selected)) {
      return const Icon(Icons.check);
    }
    return const Icon(Icons.close);
  }),
)
```

### Text Field
**Widget**: `TextField` (filled or outlined via `InputDecoration`)

| Parameter | Type | Description |
|-----------|------|-------------|
| `controller` | TextEditingController? | Text controller |
| `decoration` | InputDecoration? | Label, hint, error, icons |
| `keyboardType` | TextInputType? | Input type |
| `maxLines` | int? | Single or multi-line |
| `onChanged` | ValueChanged<String>? | Change callback |

```dart
// Outlined (recommended for most uses)
TextField(
  decoration: const InputDecoration(
    labelText: 'Email',
    hintText: 'Enter your email',
    border: OutlineInputBorder(),
    helperText: "We'll never share your email",
  ),
  keyboardType: TextInputType.emailAddress,
)

// Filled
TextField(
  decoration: const InputDecoration(
    labelText: 'Search',
    prefixIcon: Icon(Icons.search),
    filled: true,
  ),
)

// With error
TextField(
  decoration: InputDecoration(
    labelText: 'Password',
    border: const OutlineInputBorder(),
    errorText: isError ? 'Password must be at least 8 characters' : null,
  ),
  obscureText: true,
)

// Multiline
TextField(
  maxLines: 4,
  decoration: const InputDecoration(
    labelText: 'Message',
    border: OutlineInputBorder(),
    counterText: '',
  ),
  maxLength: 500,
)
```

### Date Picker
**Shown via**: `showDatePicker`, `showDateRangePicker`

```dart
// Modal date picker
final date = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);

// Date range picker
final range = await showDateRangePicker(
  context: context,
  firstDate: DateTime(2020),
  lastDate: DateTime(2030),
);
```

### Time Picker
**Shown via**: `showTimePicker`

```dart
final time = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),
);
```

## Navigation

### App Bar (Top)
**Widget**: `AppBar`, `SliverAppBar`

| Variant | Flutter | Notes |
|---------|---------|-------|
| Center-aligned | `AppBar(centerTitle: true)` | Title centered |
| Small | `AppBar(centerTitle: false)` | Title start-aligned, 64dp |
| Medium | `SliverAppBar.medium(...)` | 112dp, collapses |
| Large | `SliverAppBar.large(...)` | 152dp, collapses |

```dart
// Small app bar
AppBar(
  leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
  title: const Text('Page Title'),
  actions: [
    IconButton(icon: const Icon(Icons.search), onPressed: () {}),
    IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
  ],
)

// Medium app bar (collapses on scroll)
CustomScrollView(
  slivers: [
    SliverAppBar.medium(
      leading: BackButton(),
      title: const Text('Page Title'),
      actions: [
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    ),
    SliverFillRemaining(child: /* content */),
  ],
)
```

### Navigation Bar
**Widget**: `NavigationBar`
**Use when**: 3–5 primary destinations, compact screens, persistent.

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
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ],
)
```

### Navigation Drawer
**Widget**: `NavigationDrawer`
**Use when**: Many destinations, larger screens, can be modal or persistent.

```dart
NavigationDrawer(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) {
    setState(() => selectedIndex = index);
    Navigator.pop(context); // close drawer on mobile
  },
  children: [
    const Padding(
      padding: EdgeInsets.fromLTRB(28, 16, 16, 10),
      child: Text('Mail'),
    ),
    const NavigationDrawerDestination(
      icon: Icon(Icons.inbox_outlined),
      selectedIcon: Icon(Icons.inbox),
      label: Text('Inbox'),
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
)
```

### Navigation Rail
**Widget**: `NavigationRail`
**Use when**: 3–7 destinations, medium screens (600–839dp), persistent side navigation.

```dart
NavigationRail(
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => setState(() => selectedIndex = index),
  labelType: NavigationRailLabelType.all,
  leading: FloatingActionButton.small(
    onPressed: () {},
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

### Search
**Widgets**: `SearchBar`, `SearchAnchor`

```dart
// Persistent search bar
SearchBar(
  controller: searchController,
  hintText: 'Search...',
  leading: const Icon(Icons.search),
  onChanged: (query) => updateResults(query),
)

// Search with suggestions overlay
SearchAnchor(
  builder: (context, controller) => SearchBar(
    controller: controller,
    onTap: () => controller.openView(),
    hintText: 'Search',
    leading: const Icon(Icons.search),
  ),
  suggestionsBuilder: (context, controller) => [
    ListTile(title: const Text('Suggestion 1'), onTap: () {}),
    ListTile(title: const Text('Suggestion 2'), onTap: () {}),
  ],
)
```

### Tabs
**Widgets**: `TabBar`, `TabBarView`

| Variant | Notes |
|---------|-------|
| Primary | Top-level content switching; use with `DefaultTabController` |
| Secondary | Sub-sections; set `isScrollable` or style differently |

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      title: const Text('Explore'),
      bottom: const TabBar(
        tabs: [
          Tab(icon: Icon(Icons.flight), text: 'Flights'),
          Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
          Tab(icon: Icon(Icons.explore), text: 'Explore'),
        ],
      ),
    ),
    body: const TabBarView(
      children: [
        FlightsPage(),
        HotelsPage(),
        ExplorePage(),
      ],
    ),
  ),
)
```

## Data Display

### List
**Widgets**: `ListView`, `ListTile`

| Parameter (ListTile) | Type | Description |
|----------------------|------|-------------|
| `leading` | Widget? | Leading element (icon, avatar) |
| `trailing` | Widget? | Trailing element |
| `title` | Widget? | Primary text |
| `subtitle` | Widget? | Secondary text |
| `onTap` | VoidCallback? | Tap callback |
| `isThreeLine` | bool | Enable three-line layout |

```dart
ListView(
  children: [
    // One-line
    const ListTile(title: Text('Single line item')),

    // Two-line with icon
    const ListTile(
      leading: Icon(Icons.person),
      title: Text('Jane Smith'),
      subtitle: Text('Senior Developer'),
    ),

    // Three-line
    ListTile(
      leading: const Icon(Icons.mail),
      title: const Text('Meeting notes'),
      subtitle: const Text('Please review the attached notes from today\'s standup and provide feedback.'),
      trailing: const Text('3m ago'),
      isThreeLine: true,
    ),

    const Divider(),

    // Clickable item
    ListTile(
      leading: const Icon(Icons.settings),
      title: const Text('Settings'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {},
    ),
  ],
)
```
