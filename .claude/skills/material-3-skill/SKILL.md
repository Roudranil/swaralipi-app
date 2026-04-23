---
name: material-3-skill
description: Implement Google's Material Design 3 (Material You) UI system in Flutter. Covers tokens, 30+ components, layout, theming with useMaterial3: true, M3 Expressive, and accessibility. Use when: "material design", "MD3", "material you", "Flutter", "material component", "flutter widget".
user-invokable: true
argument-hint: "[component|theme|layout|scaffold|audit] [description or URL]"
---

# Material Design 3

This skill guides implementation of Google's Material Design 3 (MD3) — a personal, adaptive, expressive design system. MD3 uses dynamic color, tonal surfaces, rounded shapes, and spring-based motion to create UIs that feel alive and personal.

## Philosophy

MD3 is built on three principles:

- **Personal**: Dynamic color adapts UI to the user's wallpaper or content. Theming is individual, not one-size-fits-all.
- **Adaptive**: Layouts transform across 5 window size classes. Components resize, reposition, and change form factor responsively.
- **Expressive**: Shape morphing, spring physics, and emphasized typography create moments of delight without sacrificing usability.

**Key differences from MD2:**

- Tonal surfaces replace elevation shadows as the primary depth cue
- Dynamic color generates full schemes from a single seed color
- Fully rounded corners by default (not slightly rounded)
- Spring-based motion physics replace fixed easing curves for components
- 3 levels of user-controlled contrast (standard/medium/high)

**Relationship with frontend-design skill:**
When both skills are active, MD3 provides the design system (tokens, components, layout rules) and frontend-design provides creative direction within those constraints. MD3 rules take precedence for component structure and token usage. Note: Roboto/Roboto Flex IS the correct default typeface in MD3 — the frontend-design guidance to avoid Roboto does not apply when implementing MD3.

## Decision Tree

**What are you building?**

```
Full app scaffold        → See "Common Patterns: App Shell" + references/layout-and-responsive.md
Single component         → See "Component Quick Reference" table → references/component-catalog.md
Custom theme             → See references/theming-and-dynamic-color.md
Form / input layout      → See references/component-catalog.md § Input Components
Navigation structure     → See references/navigation-patterns.md
Data display             → See references/component-catalog.md § Data Display
```

**What platform?**

```
Flutter                  → useMaterial3: true in ThemeData, ColorScheme.fromSeed()
```

## Design Token System

All MD3 tokens use the `md.sys` namespace. In Flutter, color roles map to `ColorScheme`, typography to `TextTheme`, and shapes to `ThemeData.shapes` — all accessed via `Theme.of(context)`.

### Color Tokens — Flutter (ColorScheme)

| Token                       | Flutter (ColorScheme)                 | Purpose                                                   |
| --------------------------- | ------------------------------------- | --------------------------------------------------------- |
| `primary`                   | `colorScheme.primary`                 | High-emphasis fills, text, icons against surface          |
| `on-primary`                | `colorScheme.onPrimary`               | Text/icons on primary                                     |
| `primary-container`         | `colorScheme.primaryContainer`        | Standout fill for key components (FAB, etc.)              |
| `on-primary-container`      | `colorScheme.onPrimaryContainer`      | Text/icons on primary-container                           |
| `secondary`                 | `colorScheme.secondary`               | Less prominent accents                                    |
| `on-secondary`              | `colorScheme.onSecondary`             | Text/icons on secondary                                   |
| `secondary-container`       | `colorScheme.secondaryContainer`      | Recessive components (tonal buttons)                      |
| `on-secondary-container`    | `colorScheme.onSecondaryContainer`    | Text/icons on secondary-container                         |
| `tertiary`                  | `colorScheme.tertiary`                | Contrasting accents                                       |
| `on-tertiary`               | `colorScheme.onTertiary`              | Text/icons on tertiary                                    |
| `tertiary-container`        | `colorScheme.tertiaryContainer`       | Complementary containers                                  |
| `on-tertiary-container`     | `colorScheme.onTertiaryContainer`     | Text/icons on tertiary-container                          |
| `error`                     | `colorScheme.error`                   | Error states (static — doesn't change with dynamic color) |
| `on-error`                  | `colorScheme.onError`                 | Text/icons on error                                       |
| `surface`                   | `colorScheme.surface`                 | Default background                                        |
| `on-surface`                | `colorScheme.onSurface`               | Text/icons on any surface                                 |
| `on-surface-variant`        | `colorScheme.onSurfaceVariant`        | Lower-emphasis text/icons on surface                      |
| `surface-container-lowest`  | `colorScheme.surfaceContainerLowest`  | Lowest-emphasis container                                 |
| `surface-container-low`     | `colorScheme.surfaceContainerLow`     | Low-emphasis container                                    |
| `surface-container`         | `colorScheme.surfaceContainer`        | Default container (nav areas)                             |
| `surface-container-high`    | `colorScheme.surfaceContainerHigh`    | High-emphasis container                                   |
| `surface-container-highest` | `colorScheme.surfaceContainerHighest` | Highest-emphasis container                                |
| `surface-dim`               | `colorScheme.surfaceDim`              | Maintain relative brightness across light/dark            |
| `surface-bright`            | `colorScheme.surfaceBright`           | Maintain relative brightness across light/dark            |
| `inverse-surface`           | `colorScheme.inverseSurface`          | Contrasting elements (snackbars)                          |
| `inverse-on-surface`        | `colorScheme.onInverseSurface`        | Text/icons on inverse-surface                             |
| `inverse-primary`           | `colorScheme.inversePrimary`          | Contrasting primary accent                                |
| `outline`                   | `colorScheme.outline`                 | Important boundaries (text field borders)                 |
| `outline-variant`           | `colorScheme.outlineVariant`          | Decorative elements (dividers)                            |

Access via `Theme.of(context).colorScheme`

Full details: `references/color-system.md`

### Typography Tokens — Flutter (TextTheme)

| Scale              | Flutter (TextTheme)                    | Use                          |
| ------------------ | -------------------------------------- | ---------------------------- |
| Display L / M / S  | `textTheme.displayLarge/Medium/Small`  | Hero text, large numbers     |
| Headline L / M / S | `textTheme.headlineLarge/Medium/Small` | Section headers              |
| Title L / M / S    | `textTheme.titleLarge/Medium/Small`    | Smaller headers, card titles |
| Body L / M / S     | `textTheme.bodyLarge/Medium/Small`     | Paragraph text, descriptions |
| Label L / M / S    | `textTheme.labelLarge/Medium/Small`    | Buttons, chips, captions     |

Each style defines: font, weight, size, line-height, tracking.
Plus 15 **emphasized** variants (higher weight).

Access via `Theme.of(context).textTheme`

Full details: `references/typography-and-shape.md`

### Shape Tokens — Flutter (dp value)

In Flutter, shape values are applied as `BorderRadius.circular(X)` or via `RoundedRectangleBorder(borderRadius: BorderRadius.circular(X))`.

| Token                   | Value  | Example components      |
| ----------------------- | ------ | ----------------------- |
| `none`                  | 0dp    | —                       |
| `extra-small`           | 4dp    | Chips, snackbars        |
| `small`                 | 8dp    | Text fields, menus      |
| `medium`                | 12dp   | Cards                   |
| `large`                 | 16dp   | FABs, navigation drawer |
| `large-increased`       | 20dp   | (Expressive)            |
| `extra-large`           | 28dp   | Dialogs, bottom sheets  |
| `extra-large-increased` | 32dp   | (Expressive)            |
| `extra-extra-large`     | 48dp   | (Expressive)            |
| `full`                  | 9999dp | Buttons, chips, badges  |

### Elevation Levels

| Level | DP   | Tonal offset | Use                                     |
| ----- | ---- | ------------ | --------------------------------------- |
| 0     | 0dp  | None         | Flat surfaces, most components at rest  |
| 1     | 1dp  | +5% primary  | Elevated cards, modal sheets            |
| 2     | 3dp  | +8% primary  | Menus, nav bar, scrolled app bar        |
| 3     | 6dp  | +11% primary | FAB, dialogs, search, date/time pickers |
| 4     | 8dp  | +12% primary | (hover/focus increase only)             |
| 5     | 12dp | +14% primary | (hover/focus increase only)             |

In Flutter, use `Material(elevation: X)` which automatically applies tonal color overlay when `useMaterial3: true` is set. Elevation in MD3 is communicated through **tonal surface color**, not shadows. Shadows are only used when needed for additional protection against busy backgrounds.

### Motion

MD3 Expressive (May 2025) introduced **spring-based motion physics** for components. The legacy easing/duration system is still used for **transitions** (enter/exit/shared-axis):

| Easing                | Duration | Transition type                   |
| --------------------- | -------- | --------------------------------- |
| Emphasized            | 500ms    | Begin and end on screen           |
| Emphasized decelerate | 400ms    | Enter the screen                  |
| Emphasized accelerate | 200ms    | Exit the screen                   |
| Standard              | 300ms    | Begin and end on screen (utility) |
| Standard decelerate   | 250ms    | Enter screen (utility)            |
| Standard accelerate   | 200ms    | Exit screen (utility)             |

Flutter easing equivalents:

- Emphasized: `Curves.easeInOutCubicEmphasized`
- Emphasized decelerate / accelerate: use a custom `Cubic` curve (e.g., `Cubic(0.05, 0.7, 0.1, 1.0)`) or the `flutter_animate` package's `CubicBezier` helper
- Standard: `Curves.easeInOut`
- Standard decelerate: `Curves.easeOut`
- Standard accelerate: `Curves.easeIn`

## Component Quick Reference

| Component          | Flutter Widget                                                                         | Key Variants                                                     | Category      |
| ------------------ | -------------------------------------------------------------------------------------- | ---------------------------------------------------------------- | ------------- |
| Button             | `FilledButton`, `OutlinedButton`, `TextButton`, `ElevatedButton`, `FilledButton.tonal` | Filled, Outlined, Text, Elevated, Tonal; 5 sizes (XS-XL); toggle | Actions       |
| Button group       | `SegmentedButton`                                                                      | Standard, connected                                              | Actions       |
| Extended FAB       | `FloatingActionButton.extended`                                                        | Surface, Primary, Secondary, Tertiary                            | Actions       |
| FAB                | `FloatingActionButton`                                                                 | Small, Medium, Large                                             | Actions       |
| FAB menu           | —                                                                                      | —                                                                | Actions       |
| Icon button        | `IconButton`, `IconButton.filled`, `IconButton.filledTonal`, `IconButton.outlined`     | Standard, Filled, Filled Tonal, Outlined                         | Actions       |
| Segmented button   | `SegmentedButton`                                                                      | Single-select, Multi-select                                      | Actions       |
| Split button       | —                                                                                      | —                                                                | Actions       |
| Badge              | `Badge`                                                                                | Small (dot), Large (count)                                       | Communication |
| Loading indicator  | —                                                                                      | Linear, Circular                                                 | Communication |
| Progress indicator | `LinearProgressIndicator`, `CircularProgressIndicator`                                 | Linear, Circular; determinate/indeterminate                      | Communication |
| Snackbar           | `SnackBar`                                                                             | Single-line, Two-line, Action                                    | Communication |
| Tooltip            | `Tooltip`                                                                              | Plain, Rich                                                      | Communication |
| Card               | `Card`                                                                                 | Filled, Outlined, Elevated                                       | Containment   |
| Carousel           | `(custom)`                                                                             | Multi-browse, Uncontained, Hero                                  | Containment   |
| Dialog             | `AlertDialog`                                                                          | Basic, Full-screen                                               | Containment   |
| Bottom sheet       | `BottomSheet` / `showModalBottomSheet`                                                 | Standard, Modal                                                  | Sheets        |
| Side sheet         | —                                                                                      | Standard, Modal                                                  | Sheets        |
| Divider            | `Divider`                                                                              | Full-width, Inset                                                | Containment   |
| Checkbox           | `Checkbox`                                                                             | —                                                                | Input         |
| Chips              | `ActionChip`, `FilterChip`, `InputChip`, `SuggestionChip`                              | Assist, Filter, Input, Suggestion                                | Input         |
| Date picker        | `showDatePicker`                                                                       | Docked, Modal, Range                                             | Input         |
| Menu               | `MenuAnchor`                                                                           | —                                                                | Input         |
| Radio button       | `Radio`                                                                                | —                                                                | Input         |
| Slider             | `Slider`                                                                               | Continuous, Discrete, Range                                      | Input         |
| Switch             | `Switch`                                                                               | With/without icon                                                | Input         |
| Text field         | `TextField`                                                                            | Filled, Outlined                                                 | Input         |
| Time picker        | `showTimePicker`                                                                       | Docked, Modal                                                    | Input         |
| App bar (top)      | `AppBar` / `SliverAppBar`                                                              | Center-aligned, Small, Medium, Large                             | Navigation    |
| Navigation bar     | `NavigationBar`                                                                        | —                                                                | Navigation    |
| Navigation drawer  | `NavigationDrawer`                                                                     | Standard, Modal                                                  | Navigation    |
| Navigation rail    | `NavigationRail`                                                                       | —                                                                | Navigation    |
| Search             | `SearchBar` / `SearchAnchor`                                                           | Search bar, Search view                                          | Navigation    |
| Tabs               | `TabBar`                                                                               | Primary, Secondary                                               | Navigation    |
| Toolbar            | —                                                                                      | —                                                                | Navigation    |
| List               | `ListView` + `ListTile`                                                                | One-line, Two-line, Three-line                                   | Data Display  |

**Note:** Components marked with `—` have no direct Flutter equivalent; implement with custom widgets. Flutter widget names and examples live in `references/component-catalog.md`.

Full component details with code examples: `references/component-catalog.md`

## Flutter (primary)

Use **`package:flutter/material.dart`** with `MaterialApp`, `useMaterial3: true`, and Material 3 widgets (`Scaffold`, `FilledButton`, `NavigationBar`, top app bars, etc.).

- **Theming**: Wrap your app in `MaterialApp` with `theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: yourColor))`. For **dark theme**, supply `darkTheme` with `ColorScheme.fromSeed(seedColor: yourColor, brightness: Brightness.dark)` or `ThemeData.dark(useMaterial3: true)`.
- **Dynamic color** (Android 12+): Use `package:dynamic_color` and `DynamicColorBuilder` to get the system wallpaper-derived color scheme at runtime; fall back to a seed-based scheme.
- **Adaptive UI**: Use `MediaQuery.sizeOf(context).width` to detect window size class, `NavigationRail` on medium, `NavigationDrawer` on expanded — see `references/navigation-patterns.md` and `references/layout-and-responsive.md`.
- **Accessing tokens**: `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, `Theme.of(context).shapes`.
- **Experimental APIs**: Some M3 Expressive widgets require checking your Flutter/Material version; verify APIs against your SDK.

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
  themeMode: ThemeMode.system,
);
```

## Common Patterns

### App Shell

Standard MD3 app with responsive navigation + top app bar + content area.
Where `isExpanded = MediaQuery.sizeOf(context).width >= 840`.

```dart
// App shell with adaptive navigation
Scaffold(
  appBar: AppBar(title: const Text('Page Title')),
  body: Row(
    children: [
      if (isExpanded) NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => setState(() => selectedIndex = i),
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
          NavigationRailDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: Text('Search')),
        ],
      ),
      Expanded(child: content),
    ],
  ),
  bottomNavigationBar: isExpanded ? null : NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: (i) => setState(() => selectedIndex = i),
    destinations: const [
      NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
    ],
  ),
)
```

### Card Grid

```dart
// Responsive card grid
GridView.builder(
  padding: const EdgeInsets.all(16),
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 300,
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 0.8,
  ),
  itemBuilder: (context, index) => Card.outlined(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Image.network('image.jpg', fit: BoxFit.cover, width: double.infinity)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Card Title', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Supporting text', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
            ],
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () {}, child: const Text('Learn more')),
            FilledButton.tonal(onPressed: () {}, child: const Text('Action')),
          ],
        ),
      ],
    ),
  ),
)
```

### Form Layout

```dart
// MD3 form layout
Padding(
  padding: const EdgeInsets.all(16),
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 560),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(decoration: const InputDecoration(labelText: 'Full name', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        TextField(maxLines: 4, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder())),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: () {}, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton(onPressed: () {}, child: const Text('Submit')),
          ],
        ),
      ],
    ),
  ),
)
```

More patterns: `references/navigation-patterns.md`, `references/layout-and-responsive.md`

## Anti-Patterns

**Never do these when implementing MD3:**

- **Use old ThemeData APIs without `useMaterial3: true`**: Without this flag, Flutter defaults to MD2 styling. Always set `useMaterial3: true` in your `ThemeData` to get MD3 component behavior and tonal color.
- **Hardcode colors**: Don't use raw `Color(0xFF...)` values for semantic roles. Use `Theme.of(context).colorScheme.*` tokens. Hardcoded colors break dynamic theming, dark mode, and contrast adjustment.
- **Ignore tonal pairing**: Only combine colors in their intended pairs (e.g., `primary` + `onPrimary`, `surfaceContainer` + `onSurface`). Arbitrary pairings break contrast in dynamic color and high contrast modes.
- **Use `outline` for dividers**: Use `outlineVariant` for dividers. `outline` is for important boundaries like text field borders.
- **Hardcode shape values**: Use `Theme.of(context).shapes` or pass a `shape:` prop with MD3 corner token values; avoid hardcoded `BorderRadius` values in components so shapes stay consistent with theming.
- **Use shadows for elevation by default**: MD3 communicates elevation through tonal surface color, not shadows. With `useMaterial3: true`, `Material(elevation: X)` applies tonal overlay automatically. Only add explicit shadows when elements need extra separation from busy backgrounds.
- **Apply frontend-design "avoid Roboto" rule**: On **Flutter/Android**, **Roboto** is the default Material typeface. Replace only when intentionally customizing the type scale.
- **Ignore foldables and large screens**: MD3 is designed for all screen sizes. Don't ship phone-only layouts — use canonical layouts, multi-pane at 600dp+, and test on foldable/tablet emulators. Place no interactive content across the fold/hinge.
- **Stretch content to fill wide screens**: On Large (1200dp+) and Extra-large (1600dp+) windows, constrain content to a max width (840-1040dp). Endless-width text lines are unreadable.

## Platform Notes

### Flutter

```dart
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  ),
);
```

### Component Name Mapping

| Concept             | Flutter                               |
| ------------------- | ------------------------------------- |
| Filled button       | `FilledButton`                        |
| Outlined text field | `TextField` with `OutlineInputBorder` |
| FAB                 | `FloatingActionButton`                |
| Navigation bar      | `NavigationBar`                       |
| Switch              | `Switch`                              |

## M3 Expressive (May 2025)

The Expressive update adds visual richness while maintaining usability. **Availability differs by platform** — do not assume one stack implements everything.

| Capability                                 | Flutter                                                                                       |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| Spring / motion physics                    | Varies by Flutter Material version; check current Flutter docs and Material package changelog |
| Emphasized typography                      | Via theme / type scale                                                                        |
| Shape morphing                             | Check current Flutter docs                                                                    |
| New button sizes (XS-XL), toggle           | Follow Flutter MD3 widget docs                                                                |
| Extra corner tokens (e.g. large-increased) | Theme shapes                                                                                  |
| 3 contrast levels                          | Plugins / manual scheme builders                                                              |

**Flutter:** Some M3 Expressive APIs require checking your Flutter SDK and Material package version; verify APIs against your installed SDK before use.

**Legacy easing/duration** remains valid for **transitions** (enter/exit/shared-axis) where the spec still references them; see the Motion table above.

## MD3 Compliance Audit

When invoked with `audit` as the argument (e.g., `/material-3 audit`), or when asked to audit/review MD3 compliance, analyze the target app or page and produce a compliance report.

### Audit Procedure

1. **Identify the target**: The user provides a URL (use browser tools to inspect), file paths (read source), or a running app.
2. **Inspect the following categories** and score each 0-10:

| Category          | What to check                                                                                                                                                                                    |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Color tokens**  | `colorScheme` roles via `Theme.of(context).colorScheme` (no raw `Color(0xFF...)` for semantic roles without reason). Proper tonal pairing (`onX` on `X`). Dark theme configured.                 |
| **Typography**    | MD3 type scale via `Theme.of(context).textTheme`; correct roles (displayLarge, headlineMedium, bodyLarge, etc.).                                                                                 |
| **Shape**         | `Theme.of(context).shapes` or `shape:` prop with MD3 corner token dp values. Buttons: full; cards: medium; avoid hardcoded `BorderRadius` magic numbers.                                         |
| **Elevation**     | `Material(elevation: X)` with `useMaterial3: true` for tonal overlay. Shadows only where needed for busy backgrounds.                                                                            |
| **Components**    | Flutter Material3 widgets (`FilledButton`, `Scaffold`, `NavigationBar`, etc.). Correct variants used.                                                                                            |
| **Layout**        | Canonical layouts; `MediaQuery.sizeOf` for window size class / adaptive APIs; readable max width on large widths; foldable hinge avoidance.                                                      |
| **Navigation**    | `NavigationBar` / `NavigationRail` / `NavigationDrawer` patterns per size class; predictive back where applicable.                                                                               |
| **Motion**        | `Curves.easeInOutCubicEmphasized` and MD3 duration values for transitions; spring physics where Flutter Material APIs support it.                                                                |
| **Accessibility** | MD3 roles help, but **verify contrast**: UI components often need **3:1** for large text/borders and **4.5:1** for normal text (WCAG 2.x). Semantics labels, focus order, touch targets (~48dp). |
| **Theming**       | `ThemeData(useMaterial3: true)` + `ColorScheme.fromSeed` + light/dark/dynamic as designed.                                                                                                       |

3. **Generate the report**:

```
# MD3 Compliance Audit Report

Target: [URL or file path]
Date: [date]
Overall Score: [X/100]

## Scores by Category
| Category       | Score | Status |
|----------------|-------|--------|
| Color tokens   | X/10  | [pass/warn/fail] |
| Typography     | X/10  | [pass/warn/fail] |
| Shape          | X/10  | [pass/warn/fail] |
| Elevation      | X/10  | [pass/warn/fail] |
| Components     | X/10  | [pass/warn/fail] |
| Layout         | X/10  | [pass/warn/fail] |
| Navigation     | X/10  | [pass/warn/fail] |
| Motion         | X/10  | [pass/warn/fail] |
| Accessibility  | X/10  | [pass/warn/fail] |
| Theming        | X/10  | [pass/warn/fail] |

## Critical Issues
[List items scoring 0-3 with specific file:line references and fixes]

## Warnings
[List items scoring 4-6 with recommendations]

## Passing
[List items scoring 7-10 with notes on what's done well]

## Recommended Fixes (Priority Order)
1. [Most impactful fix first]
2. ...
```

### Audit Methods

**For a live URL** (browser or devtools, e.g. Flutter Web):

- Inspect computed styles and rendered token values
- Resize viewport or use responsive mode for breakpoints
- Capture screenshots at key widths if helpful

**For source code** (file paths provided):

- **Flutter:** `.dart` files — check `ThemeData(useMaterial3: true)`, `ColorScheme` usage, `Color(0x…)` abuse for semantic roles, hard-coded `Dp` values in place of token dp values, missing `Semantics` widgets where needed

**Quick checks** (adapt paths to your Flutter project):

```
# Flutter: raw Color(...) usage that may bypass colorScheme
grep -rn 'Color(0x' --include='*.dart'

# Flutter: missing useMaterial3 flag
grep -rn 'ThemeData(' --include='*.dart'

# Flutter: hardcoded BorderRadius values (potential shape token violations)
grep -rn 'BorderRadius.circular' --include='*.dart'
```

**Browser automation** (if your environment exposes MCP browser tools): navigate, snapshot rendered output, resize for breakpoints — optional, not required.

### Scoring Guide

- **9-10**: Fully MD3 compliant, uses correct tokens and patterns
- **7-8**: Mostly compliant, minor issues (e.g., a few hardcoded values)
- **4-6**: Partially compliant, some MD3 patterns but significant gaps
- **1-3**: Major violations, mostly non-MD3 or MD2 patterns
- **0**: Not applicable or completely absent

Status thresholds: **pass** (7+), **warn** (4-6), **fail** (0-3)

## Reference Documents

- `references/color-system.md` — Color roles, tonal palettes, dynamic color, Flutter ColorScheme mapping
- `references/typography-and-shape.md` — Type scale, shape corners, elevation, motion, Expressive notes
- `references/component-catalog.md` — Components: Flutter widgets and usage examples
- `references/navigation-patterns.md` — Navigation selection, adaptive patterns
- `references/layout-and-responsive.md` — Breakpoints, canonical layouts, insets, foldables
- `references/theming-and-dynamic-color.md` — Theming: Flutter ThemeData, dynamic color, dark theme
