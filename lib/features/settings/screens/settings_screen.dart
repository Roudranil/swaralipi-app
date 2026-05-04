// SettingsScreen — navigational shell for all settings sub-sections.
//
// Route: /settings
//
// The screen renders a [ListView] of [ListTile]s, each navigating to a
// settings sub-section via [GoRouter]:
//   • Tags            → /settings/tags
//   • Instruments     → /settings/instruments
//   • Trash           → /settings/trash
//   • Appearance      → /settings/appearance
//   • Custom Fields   → /settings/custom-fields
//   • About           → inline tile displaying app name + version
//
// The screen holds no state of its own. [PackageInfo] is loaded once via
// [FutureBuilder] to populate the About tile. All other tiles are static.

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Padding at the top and bottom of the settings list.
const EdgeInsets _kListPadding = EdgeInsets.symmetric(vertical: 8);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Navigational shell screen for all settings sub-sections.
///
/// Renders a [ListView] of navigation tiles. Tapping a tile calls
/// [GoRouter.go] to the corresponding sub-route. The About tile shows the
/// app name and version from [PackageInfo].
///
/// This screen is stateless with respect to user-editable data. It loads
/// [PackageInfo] once on first build via a [FutureBuilder].
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen].
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final info = snapshot.data;
          return ListView(
            padding: _kListPadding,
            children: [
              _SettingsTile(
                icon: Icons.label_outline,
                title: 'Tags',
                onTap: () => context.go('/settings/tags'),
              ),
              _SettingsTile(
                icon: Icons.music_note_outlined,
                title: 'Instruments',
                onTap: () => context.go('/settings/instruments'),
              ),
              _SettingsTile(
                icon: Icons.delete_outline,
                title: 'Trash',
                onTap: () => context.go('/settings/trash'),
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                onTap: () => context.go('/settings/appearance'),
              ),
              _SettingsTile(
                icon: Icons.tune_outlined,
                title: 'Custom Fields',
                onTap: () => context.go('/settings/custom-fields'),
              ),
              const Divider(),
              _AboutTile(info: info),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

/// A single navigational [ListTile] in the settings list.
///
/// Displays a leading [icon], a [title] label, and a trailing chevron.
/// Calls [onTap] when tapped.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  /// Icon displayed as the leading element.
  final IconData icon;

  /// Label text for the tile.
  final String title;

  /// Callback invoked when the tile is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: title,
      child: ListTile(
        leading: Icon(icon, color: colorScheme.onSurfaceVariant),
        title: Text(title),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}

/// The About tile, showing app name and version.
///
/// Displays a loading indicator while [PackageInfo] is being fetched.
/// Falls back to an empty subtitle when [info] is null (unexpected).
class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.info});

  /// The resolved [PackageInfo], or null while loading.
  final PackageInfo? info;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (info == null) {
      log('_AboutTile: PackageInfo not yet available', name: 'SettingsScreen');
      return ListTile(
        leading: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
        title: const Text('About'),
        subtitle: const LinearProgressIndicator(),
      );
    }

    final versionString = '${info!.appName} ${info!.version}';
    return ListTile(
      leading: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
      title: const Text('About'),
      subtitle: Text(
        versionString,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
