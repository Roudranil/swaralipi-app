# MD3 Theming and Dynamic Color

Complete guide to creating, applying, and managing Material Design 3 themes.

## Theme Architecture

The same **semantic roles** (primary, onSurface, surface containers, etc.) appear on every platform:

| Platform | Theme surface |
|----------|----------------|
| **Flutter** | `ThemeData` + `ColorScheme`, `useMaterial3: true` |

---

## Flutter Theming

```dart
import 'package:flutter/material.dart';

// Basic MD3 theme from seed
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.light,
    ),
  ),
  darkTheme: ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  ),
);

// Dynamic color (Android 12+)
// Requires package:dynamic_color
DynamicColorBuilder(
  builder: (lightDynamic, darkDynamic) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkDynamic ?? ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
    );
  },
);
```

## Brand Color Integration

### Mapping Existing Brand Colors

If you have existing brand colors, map them to MD3 roles:

| Brand concept | MD3 role |
|--------------|----------|
| Primary brand color | Use as seed for `primary` palette |
| Secondary brand color | Override `secondary` or use as custom color |
| Accent color | Map to `tertiary` |
| Alert/danger color | Override `error` (or keep MD3 default) |
| Background | Generated from seed (don't hardcode) |

### Using a Brand Color as Seed

The simplest approach: use your primary brand color as the seed. The algorithm will generate harmonious secondary and tertiary colors automatically.

```dart
// Flutter: use your brand color as the seed
ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8))
```

### Color Harmonization for Additional Brand Colors

If you need to integrate a specific brand color that wasn't generated from the seed:

```dart
// Flutter: use the material_color_utilities Dart package
// import 'package:material_color_utilities/material_color_utilities.dart';
// final harmonized = Blend.harmonize(customColorArgb, schemePrimaryArgb);
```

## Dark Theme

### Automatic Generation

Dark theme is automatically generated from the same seed color. The tonal mapping simply shifts:
- Light theme uses lighter tones (80-100) for surfaces, darker tones (10-40) for accents
- Dark theme inverts: darker tones (4-22) for surfaces, lighter tones (80-90) for accents

In Flutter, supply both `theme` and `darkTheme` to `MaterialApp` and set `themeMode: ThemeMode.system` to automatically follow the OS setting. For manual toggle, use a state management solution to switch `themeMode`.

## High Contrast Themes

MD3 supports 3 contrast levels, adjustable via the `contrast` parameter:

| Level | Value | Effect |
|-------|-------|--------|
| Standard | 0.0 | Default tonal distance |
| Medium | 0.5 | Increased tonal distance, easier to read |
| High | 1.0 | Maximum tonal distance, highest legibility |

```dart
// Flutter: the contrast parameter is available via material_color_utilities
// import 'package:material_color_utilities/material_color_utilities.dart';
// final scheme = SchemeContent(Hct.fromInt(seed), isDark, 1.0); // high contrast
// Then map roles to ColorScheme manually, or use a generated theme
```

Higher contrast increases the tonal distance between paired color roles (e.g., `primary` and `on-primary`), making text more legible without fundamentally changing the color feel.

## Component-Level Overrides (Flutter)

Override individual component styles using component-specific `ThemeData` fields:

```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  // Override filled button colors
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      foregroundColor: Theme.of(context).colorScheme.onTertiary,
    ),
  ),
  // Override text field shape
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)), // medium corner
    ),
  ),
  // Override FAB
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
    foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
  ),
)
```

For per-widget overrides, wrap with a `Theme` widget:
```dart
Theme(
  data: Theme.of(context).copyWith(
    switchTheme: SwitchThemeData(
      trackColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
    ),
  ),
  child: Switch(value: value, onChanged: onChanged),
)
```

## Dynamic Color from Content

Extract a color from an image and apply it as the theme:

```dart
// Flutter: extract dominant color from an image using the palette package
// import 'package:palette_generator/palette_generator.dart';

Future<ColorScheme> schemeFromImage(ImageProvider imageProvider) async {
  final paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
  final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.deepPurple;
  return ColorScheme.fromSeed(seedColor: dominantColor);
}
```

## Scoped Themes

Apply different themes to different sections of the UI:

```dart
// Flutter: scoped themes via Theme widget
Theme(
  data: Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
      primary: const Color(0xFFB69DF8),
      primaryContainer: const Color(0xFF3F2D7A),
    ),
  ),
  child: Column(
    children: [
      // Children inherit the overridden theme
      FilledButton(onPressed: () {}, child: const Text('Premium')),
    ],
  ),
)
```

Theme overrides cascade to children — any widget inside the `Theme` widget's subtree will automatically inherit the overridden theme data.
