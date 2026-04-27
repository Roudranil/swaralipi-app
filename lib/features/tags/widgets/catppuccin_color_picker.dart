// CatppuccinColorPicker — Catppuccin Mocha accent color grid picker widget.
//
// Renders all 14 Catppuccin Mocha accent colors as selectable chip swatches.
// The currently selected color is highlighted with a check mark overlay.
//
// Usage:
//   CatppuccinColorPicker(
//     selectedColorHex: '#f38ba8',
//     onColorSelected: (hex) => setState(() => _colorHex = hex),
//   )

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Catppuccin Mocha palette constants
// ---------------------------------------------------------------------------

/// All 14 Catppuccin Mocha accent color hex strings.
const List<String> kCatppuccinMochaAccents = [
  '#f38ba8', // Rosewater
  '#fab387', // Peach
  '#f9e2af', // Yellow
  '#a6e3a1', // Green
  '#94e2d5', // Teal
  '#89dceb', // Sky
  '#89b4fa', // Blue
  '#b4befe', // Lavender
  '#cba6f7', // Mauve
  '#f5c2e7', // Pink
  '#eba0ac', // Maroon
  '#a6adc8', // Subtext 1
  '#bac2de', // Subtext 0
  '#7f849c', // Overlay 1
];

/// Human-readable names for each Catppuccin Mocha accent, keyed by hex.
const Map<String, String> kCatppuccinMochaNames = {
  '#f38ba8': 'Rosewater',
  '#fab387': 'Peach',
  '#f9e2af': 'Yellow',
  '#a6e3a1': 'Green',
  '#94e2d5': 'Teal',
  '#89dceb': 'Sky',
  '#89b4fa': 'Blue',
  '#b4befe': 'Lavender',
  '#cba6f7': 'Mauve',
  '#f5c2e7': 'Pink',
  '#eba0ac': 'Maroon',
  '#a6adc8': 'Subtext 1',
  '#bac2de': 'Subtext 0',
  '#7f849c': 'Overlay 1',
};

// ---------------------------------------------------------------------------
// Color parsing helper
// ---------------------------------------------------------------------------

/// Parses a Catppuccin hex string (e.g. `'#f38ba8'`) to a [Color].
///
/// Returns [Colors.grey] if the string is malformed.
///
/// Parameters:
/// - [hex]: A 7-character hex string starting with `#`.
Color colorFromHex(String hex) {
  final normalized = hex.replaceFirst('#', '');
  final value = int.tryParse('FF$normalized', radix: 16);
  if (value == null) return Colors.grey;
  return Color(value);
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Spacing between color swatches in the grid.
const double _kSwatchSpacing = 8.0;

/// Size of each color swatch chip.
const double _kSwatchSize = 40.0;

/// A grid of selectable Catppuccin Mocha color swatches.
///
/// Displays all [kCatppuccinMochaAccents] as circular chips. The currently
/// selected swatch is highlighted with a check mark. Tapping a swatch calls
/// [onColorSelected] with the corresponding hex string.
class CatppuccinColorPicker extends StatelessWidget {
  /// Creates a [CatppuccinColorPicker].
  ///
  /// Parameters:
  /// - [selectedColorHex]: The currently selected hex string; may be `null`
  ///   when no selection has been made yet.
  /// - [onColorSelected]: Called with the hex string when a swatch is tapped.
  const CatppuccinColorPicker({
    super.key,
    required this.selectedColorHex,
    required this.onColorSelected,
  });

  /// The currently selected Catppuccin hex color string.
  final String? selectedColorHex;

  /// Called when the user selects a color swatch.
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: _kSwatchSpacing,
      runSpacing: _kSwatchSpacing,
      children: kCatppuccinMochaAccents.map((hex) {
        final isSelected = hex == selectedColorHex;
        final color = colorFromHex(hex);
        final name = kCatppuccinMochaNames[hex] ?? hex;

        return Semantics(
          label: '$name${isSelected ? ', selected' : ''}',
          button: true,
          child: GestureDetector(
            onTap: () => onColorSelected(hex),
            child: _ColorSwatch(
              color: color,
              isSelected: isSelected,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A single circular color swatch with an optional selection indicator.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.isSelected,
  });

  final Color color;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSwatchSize,
      height: _kSwatchSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              size: 20,
              color:
                  ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                      ? Colors.white
                      : Colors.black,
            )
          : null,
    );
  }
}
