# MD3 Typography, Shape, Elevation, and Motion

Reference for Material Design 3's visual token systems beyond color.

## Typography

### Type Scale

MD3 uses 15 baseline styles + 15 emphasized styles organized in 5 categories (Display, Headline, Title, Body, Label) with 3 sizes each (Large, Medium, Small).

#### Baseline Type Scale (Default Values)

| Style | Font | Weight | Size (sp) | Line Height | Tracking |
|-------|------|--------|-----------|------------|----------|
| Display Large | Roboto | 400 | 57 | 64sp | -0.25px |
| Display Medium | Roboto | 400 | 45 | 52sp | 0 |
| Display Small | Roboto | 400 | 36 | 44sp | 0 |
| Headline Large | Roboto | 400 | 32 | 40sp | 0 |
| Headline Medium | Roboto | 400 | 28 | 36sp | 0 |
| Headline Small | Roboto | 400 | 24 | 32sp | 0 |
| Title Large | Roboto | 400 | 22 | 28sp | 0 |
| Title Medium | Roboto | 500 | 16 | 24sp | 0.15px |
| Title Small | Roboto | 500 | 14 | 20sp | 0.1px |
| Body Large | Roboto | 400 | 16 | 24sp | 0.5px |
| Body Medium | Roboto | 400 | 14 | 20sp | 0.25px |
| Body Small | Roboto | 400 | 12 | 16sp | 0.4px |
| Label Large | Roboto | 500 | 14 | 20sp | 0.1px |
| Label Medium | Roboto | 500 | 12 | 16sp | 0.5px |
| Label Small | Roboto | 500 | 11 | 16sp | 0.5px |

#### Emphasized Type Styles (Expressive Update)

The 15 emphasized styles mirror the baseline scale but with **higher weight** and minor adjustments. Use for:
- Selected/active states in components
- Primary action buttons
- Headlines needing emphasis
- Unread/important content

To use: swap the baseline token for the emphasized version:
- Baseline: `md.sys.typescale.display-large`
- Emphasized: `md.sys.typescale.emphasized.display-large`

### Accessing Type Styles in Flutter

Access the type scale via `Theme.of(context).textTheme`:

```dart
Text('Hello', style: Theme.of(context).textTheme.headlineLarge)
Text('Body', style: Theme.of(context).textTheme.bodyMedium)
Text('Label', style: Theme.of(context).textTheme.labelLarge)
```

The full mapping:

| Scale | Flutter TextTheme property |
|-------|--------------------------|
| Display Large | `textTheme.displayLarge` |
| Display Medium | `textTheme.displayMedium` |
| Display Small | `textTheme.displaySmall` |
| Headline Large | `textTheme.headlineLarge` |
| Headline Medium | `textTheme.headlineMedium` |
| Headline Small | `textTheme.headlineSmall` |
| Title Large | `textTheme.titleLarge` |
| Title Medium | `textTheme.titleMedium` |
| Title Small | `textTheme.titleSmall` |
| Body Large | `textTheme.bodyLarge` |
| Body Medium | `textTheme.bodyMedium` |
| Body Small | `textTheme.bodySmall` |
| Label Large | `textTheme.labelLarge` |
| Label Medium | `textTheme.labelMedium` |
| Label Small | `textTheme.labelSmall` |

### Typeface Customization

MD3 uses two typeface roles:
- **Brand**: Used for Display and Headline styles (expression-focused)
- **Plain**: Used for Title, Body, and Label styles (readability-focused)

Both default to Roboto. To customize:

```dart
// Customize typeface in Flutter using google_fonts package
import 'package:google_fonts/google_fonts.dart';

ThemeData(
  useMaterial3: true,
  textTheme: GoogleFonts.robotoTextTheme(),
  // Or mix brand/plain typefaces:
  // textTheme: GoogleFonts.notoSerifTextTheme().copyWith(
  //   bodyLarge: GoogleFonts.roboto(fontSize: 16),
  // ),
)
```

### Roboto Flex

Roboto Flex is a variable font supporting multiple axes:
- **Weight** (wght): 100-1000
- **Width** (wdth): 25-151
- **Optical size** (opsz): 8-144

In Flutter, you can load Roboto Flex via the `google_fonts` package.

### Font Size Units

| Android/Flutter | Unit | Conversion |
|-----------------|------|------------|
| Android/Flutter | sp | 1:1 |

### Component Type Usage

| Component | Type Style |
|-----------|-----------|
| Button label | Label Large |
| Card title | Title Medium |
| Card body | Body Medium |
| Top app bar title | Title Large |
| Navigation label | Label Medium |
| Dialog headline | Headline Small |
| Dialog body | Body Medium |
| Chip label | Label Large |
| Text field input | Body Large |
| Text field label | Body Small (floating) / Body Large (resting) |
| List headline | Body Large |
| List supporting text | Body Medium |
| Snackbar text | Body Medium |
| Tooltip text | Body Small |
| Tab label | Title Small |
| Badge count | Label Small |

## Shape

### Corner Radius Scale

| Token | Value (dp) | Value (px/CSS) | Default components |
|-------|-----------|----------------|-------------------|
| `none` | 0 | 0px | — |
| `extra-small` | 4 | 4px | Snackbar |
| `small` | 8 | 8px | Text fields, menus, chips |
| `medium` | 12 | 12px | Cards |
| `large` | 16 | 16px | FAB, extended FAB, nav drawer |
| `large-increased` | 20 | 20px | (Expressive update) |
| `extra-large` | 28 | 28px | Dialogs, bottom sheets, side sheets |
| `extra-large-increased` | 32 | 32px | (Expressive update) |
| `extra-extra-large` | 48 | 48px | (Expressive update) |
| `full` | — | 9999px | Buttons, badges, pills, sliders |

In Flutter, use `BorderRadius.circular(value)` with these dp values, or supply `RoundedRectangleBorder(borderRadius: BorderRadius.circular(value))` to a widget's `shape` parameter.

### Component Shape Mapping

| Component | Default Shape Token |
|-----------|-------------------|
| Buttons (all types) | `full` |
| FAB | `large` |
| Extended FAB | `large` |
| Icon button | `full` |
| Chips | `small` |
| Cards | `medium` |
| Dialogs | `extra-large` |
| Text fields | `small` (top corners) |
| Menus | `small` |
| Navigation drawer | `large` (end corners) |
| Bottom sheets | `extra-large` (top corners) |
| Snackbar | `extra-small` |
| Badges | `full` |
| Sliders (handle) | `full` |
| Switch (track) | `full` |
| Tabs (indicator) | `full` (top corners) |
| Search bar | `full` |

### Shape Morphing (Expressive)

In the M3 Expressive update, components can morph between shapes on interaction:
- Button shapes morph when pressed
- Selected states can change shape
- Loading indicators use shape morphing to show progress

**Flutter:** check current Flutter/Material3 version for shape morphing support — expressive APIs are being added progressively.

## Elevation

### Elevation Levels

| Level | DP Height | Use |
|-------|-----------|-----|
| 0 | 0dp | Most resting components |
| 1 | 1dp | Elevated variants (cards, sheets) |
| 2 | 3dp | Menus, nav bar, scrolled app bar |
| 3 | 6dp | FAB, dialogs, search, date/time pickers |
| 4 | 8dp | Hover/focus increase only |
| 5 | 12dp | Hover/focus increase only |

### Tonal Elevation (Not Shadows)

MD3 uses **tonal surface color** to communicate elevation, not shadows. Higher elevation = lighter surface tone (in light theme) or lighter surface tone (in dark theme).

The surface container roles map to this concept:
- Level 0: `surface` (flattest)
- Level 1: `surface-container-low`
- Level 2: `surface-container`
- Level 3: `surface-container-high`
- Level 4-5: `surface-container-highest`

### When to Use Shadows

Shadows are only appropriate when:
- A component floats over content that may be visually busy (e.g., FAB over images)
- Additional depth cue is needed beyond color (e.g., overlapping elements)
- The platform convention expects shadows (some Android components)

### Flutter Shadow Values

When shadows are needed (only add explicit `BoxShadow` when `Material(elevation: X)` tonal overlay alone isn't sufficient):

```dart
// Flutter shadow values (when elevation color alone isn't sufficient)
// Level 1
BoxShadow(offset: Offset(0, 1), blurRadius: 2, spreadRadius: 0, color: Colors.black.withValues(alpha: 0.3)),
BoxShadow(offset: Offset(0, 1), blurRadius: 3, spreadRadius: 1, color: Colors.black.withValues(alpha: 0.15)),

// Level 2
BoxShadow(offset: Offset(0, 1), blurRadius: 2, spreadRadius: 0, color: Colors.black.withValues(alpha: 0.3)),
BoxShadow(offset: Offset(0, 2), blurRadius: 6, spreadRadius: 2, color: Colors.black.withValues(alpha: 0.15)),

// Level 3
BoxShadow(offset: Offset(0, 4), blurRadius: 8, spreadRadius: 3, color: Colors.black.withValues(alpha: 0.15)),
BoxShadow(offset: Offset(0, 1), blurRadius: 3, spreadRadius: 0, color: Colors.black.withValues(alpha: 0.3)),
```

Note: In Flutter with `useMaterial3: true`, `Material(elevation: X)` automatically applies tonal surface overlay — only add explicit `BoxShadow` when needed.

### Component Elevation Mapping

| Level | Components at Rest |
|-------|--------------------|
| 0 | App bar (flat), filled/tonal/outlined buttons, button groups, filled/outlined cards, carousel, chips, full-screen dialogs, icon buttons, lists, nav rail, segmented buttons, sliders, split buttons, tabs |
| 1 | Banners, modal bottom sheet, elevated button, elevated card, elevated chips, modal nav drawer, modal side sheet |
| 2 | App bar (scrolled), menus, nav bar, rich tooltips, toolbar |
| 3 | Date pickers, modal dialogs, extended FAB, FAB, FAB menu close button, search, time pickers |

**Hover/focus**: Most interactive components increase by 1 level on hover/focus (e.g., FAB goes from level 3 to level 4).

## Motion

### Spring-Based Motion (Expressive Update)

MD3 Expressive (May 2025) introduced spring-based motion physics for component animations. Springs create more natural, responsive motion:

- Springs have no fixed duration — they respond dynamically to input
- Two schemes: **standard** (utilitarian) and **expressive** (bouncy)
- **Flutter:** check your Flutter/Material version for spring motion parity — expressive APIs are being added progressively.

### Easing and Duration (Transitions)

The easing/duration system is used for **transitions** (entering, exiting, shared-axis) and as a web fallback:

#### Easing Sets

**Emphasized** (recommended for most transitions — captures the MD3 style):
| Type | Cubic Bezier | Use |
|------|-------------|-----|
| Emphasized | `(0.2, 0, 0, 1)` | Begin and end on screen |
| Emphasized Decelerate | `(0.05, 0.7, 0.1, 1)` | Enter the screen |
| Emphasized Accelerate | `(0.3, 0, 0.8, 0.15)` | Exit the screen |

**Standard** (for utility transitions):
| Type | Cubic Bezier | Use |
|------|-------------|-----|
| Standard | `(0.2, 0, 0, 1)` | Begin and end on screen |
| Standard Decelerate | `(0, 0, 0, 1)` | Enter the screen |
| Standard Accelerate | `(0.3, 0, 1, 1)` | Exit the screen |

#### Duration Scale

| Token | Value | Use |
|-------|-------|-----|
| Short 1 | 50ms | Micro-interactions |
| Short 2 | 100ms | Small transitions |
| Short 3 | 150ms | Small transitions |
| Short 4 | 200ms | Exit transitions |
| Medium 1 | 250ms | Medium transitions |
| Medium 2 | 300ms | Standard transitions |
| Medium 3 | 350ms | Medium transitions |
| Medium 4 | 400ms | Enter transitions |
| Long 1 | 450ms | Large transitions |
| Long 2 | 500ms | Large, emphasized transitions |
| Long 3 | 550ms | Complex transitions |
| Long 4 | 600ms | Complex transitions |
| Extra Long 1 | 700ms | Page transitions |
| Extra Long 2 | 800ms | Page transitions |
| Extra Long 3 | 900ms | Complex page transitions |
| Extra Long 4 | 1000ms | Complex page transitions |

#### Suggested Pairings

| Transition | Easing | Duration |
|-----------|--------|----------|
| Element stays on screen | Emphasized | 500ms |
| Element enters screen | Emphasized Decelerate | 400ms |
| Element exits permanently | Emphasized Accelerate | 200ms |
| Element exits temporarily | Emphasized | 300ms |
| Small utility transition | Standard | 300ms |

### Flutter Implementation

Flutter uses `Curves` and `Duration` for motion. MD3 easing equivalents:

- **Emphasized**: `Curves.easeInOutCubicEmphasized`
- **Emphasized Decelerate**: `Cubic(0.05, 0.7, 0.1, 1.0)`
- **Emphasized Accelerate**: `Cubic(0.3, 0.0, 0.8, 0.15)`
- **Standard**: `Curves.easeInOutCubic`
- **Standard Decelerate**: `Curves.easeOutCubic`
- **Standard Accelerate**: `Curves.easeInCubic`

Use `Duration(milliseconds: X)` with the duration scale values above.

```dart
// Example: dialog enter animation
AnimatedContainer(
  duration: const Duration(milliseconds: 400), // Medium 4 — enter
  curve: Cubic(0.05, 0.7, 0.1, 1.0),           // Emphasized Decelerate
  // ...
)
```
