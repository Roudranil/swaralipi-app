// AppearanceScreen — screen for configuring theme and color scheme.
//
// Route: /settings/appearance
//
// The screen observes [AppearanceViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (settings UI), or error.
// Success state shows:
//   • Theme Mode — SegmentedButton with Light / Dark / System
//   • Color Scheme — Radio-style chips for Dynamic (Monet) and Seed Color;
//     the Catppuccin color grid is shown only when Seed Color is active
//
// Selecting any option immediately calls the corresponding ViewModel method,
// which persists to the repository. The MaterialApp ThemeData rebuilds are
// triggered by the consumer of the ViewModel at the app root; this screen is
// responsible only for display and user interaction.
//
// Dependencies injected at the call site:
//   ChangeNotifierProvider<AppearanceViewModel>(
//     create: (_) => AppearanceViewModel(prefsRepository)..init(),
//     child: const AppearanceScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/settings/viewmodels/appearance_view_model.dart';
import 'package:swaralipi/features/tags/widgets/catppuccin_color_picker.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Horizontal + vertical screen padding.
const EdgeInsets _kScreenPadding = EdgeInsets.all(16);

/// Vertical gap between settings sections.
const double _kSectionGap = 24.0;

/// Vertical gap within a section (label to control).
const double _kInnerGap = 12.0;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen for configuring appearance preferences (theme mode and color scheme).
///
/// Reads [AppearanceViewModel] from the widget tree via
/// [ChangeNotifierProvider]. Calls [AppearanceViewModel.init] in [initState].
class AppearanceScreen extends StatefulWidget {
  /// Creates an [AppearanceScreen].
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppearanceViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppearanceViewModel>();

    if (vm.operationError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save setting: ${vm.operationError}',
            ),
          ),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),
      body: switch (vm.state) {
        AppearanceStateIdle() => const _LoadingBody(),
        AppearanceStateLoading() => const _LoadingBody(),
        AppearanceStateSuccess(:final preferences) => _SuccessBody(
            preferences: preferences,
          ),
        AppearanceStateError(:final message) => _ErrorBody(message: message),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading body
// ---------------------------------------------------------------------------

/// Centered loading indicator while preferences are being fetched.
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// ---------------------------------------------------------------------------
// Error body
// ---------------------------------------------------------------------------

/// Error message with a retry button.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  /// Human-readable error description.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: _kScreenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load appearance settings.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => context.read<AppearanceViewModel>().init(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success body
// ---------------------------------------------------------------------------

/// Main settings UI rendered when preferences are loaded.
class _SuccessBody extends StatelessWidget {
  const _SuccessBody({required this.preferences});

  /// The current user preferences.
  final UserPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: _kScreenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThemeModeSection(currentMode: preferences.themeMode),
          const SizedBox(height: _kSectionGap),
          _ColorSchemeSection(
            currentMode: preferences.colorSchemeMode,
            currentSeedColor: preferences.seedColor,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme Mode section
// ---------------------------------------------------------------------------

/// Settings section for selecting the brightness theme mode.
class _ThemeModeSection extends StatelessWidget {
  const _ThemeModeSection({required this.currentMode});

  /// The currently persisted [AppThemeMode].
  final AppThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Theme Mode',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: _kInnerGap),
        SegmentedButton<AppThemeMode>(
          segments: const [
            ButtonSegment(
              value: AppThemeMode.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment(
              value: AppThemeMode.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
            ButtonSegment(
              value: AppThemeMode.system,
              label: Text('System'),
              icon: Icon(Icons.brightness_auto_outlined),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (selected) {
            context.read<AppearanceViewModel>().setThemeMode(selected.first);
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Color Scheme section
// ---------------------------------------------------------------------------

/// Settings section for selecting between Monet dynamic color and a
/// Catppuccin seed color.
class _ColorSchemeSection extends StatelessWidget {
  const _ColorSchemeSection({
    required this.currentMode,
    required this.currentSeedColor,
  });

  /// The currently persisted [ColorSchemeMode].
  final ColorSchemeMode currentMode;

  /// The currently persisted seed color hex, or `null`.
  final String? currentSeedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color Scheme',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: _kInnerGap),
        _ColorSchemeModeOption(
          label: 'Dynamic (Monet)',
          subtitle: 'Uses your wallpaper accent color (Android 12+)',
          icon: Icons.wallpaper_outlined,
          isSelected: currentMode == ColorSchemeMode.monet,
          onTap: () => context
              .read<AppearanceViewModel>()
              .setColorSchemeMode(ColorSchemeMode.monet),
        ),
        const SizedBox(height: 8),
        _ColorSchemeModeOption(
          label: 'Seed Color',
          subtitle: 'Pick a color from the Catppuccin palette',
          icon: Icons.palette_outlined,
          isSelected: currentMode == ColorSchemeMode.catppuccin,
          onTap: () => context
              .read<AppearanceViewModel>()
              .setColorSchemeMode(ColorSchemeMode.catppuccin),
        ),
        if (currentMode == ColorSchemeMode.catppuccin) ...[
          const SizedBox(height: _kSectionGap),
          Text(
            'Seed Color',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: _kInnerGap),
          CatppuccinColorPicker(
            selectedColorHex: currentSeedColor,
            onColorSelected: (hex) =>
                context.read<AppearanceViewModel>().setSeedColor(hex),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Color scheme mode option tile
// ---------------------------------------------------------------------------

/// A tappable list tile representing a single color scheme mode option.
class _ColorSchemeModeOption extends StatelessWidget {
  const _ColorSchemeModeOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  /// The display label for this option.
  final String label;

  /// Supporting text describing the option.
  final String subtitle;

  /// Leading icon.
  final IconData icon;

  /// Whether this option is currently selected.
  final bool isSelected;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      selected: isSelected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? colorScheme.secondary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isSelected
                                ? colorScheme.onSecondaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.secondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
