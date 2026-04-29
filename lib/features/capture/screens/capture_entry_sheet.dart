// capture_entry_sheet.dart — modal bottom sheet for capture entry.
//
// Route: shown via showModalBottomSheet from LibraryScreen FAB.
//
// Presents two options: Gallery and Camera. Delegates to
// [CaptureEntryViewModel] for all platform operations and reacts to state
// changes:
//   - loading                     → disables buttons, shows progress
//   - permissionPermanentlyDenied → shows explanatory dialog with Settings link
//   - permissionDenied            → shows a snack bar
//   - cameraDone                  → pops sheet, navigates to PhotoSelectionScreen
//   - cameraEmpty                 → shows empty state inline
//   - galleryDone (non-empty)     → pops sheet, navigates to PageEditorScreen
//   - galleryDone (empty)         → returns to idle (user cancelled picker)
//
// Dependency injection:
//   ChangeNotifierProvider<CaptureEntryViewModel> must be in the widget tree
//   above this sheet (typically provided at the call site).

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/viewmodels/capture_entry_view_model.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Padding inside the bottom sheet content.
const EdgeInsets _kSheetPadding = EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 36.0);

/// Vertical gap between the handle and the title.
const double _kHandleGap = 8.0;

/// Vertical gap between the title and the option tiles.
const double _kTitleGap = 16.0;

/// Vertical gap between option tiles.
const double _kTileGap = 12.0;

/// Border radius of each option tile.
const double _kTileRadius = 16.0;

/// Height of each option tile.
const double _kTileHeight = 72.0;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Modal bottom sheet that lets the user choose between Gallery and Camera
/// as the source for new notation pages.
///
/// Observes [CaptureEntryViewModel] via [ChangeNotifierProvider] and drives
/// navigation / dialogs based on the resulting state.
class CaptureEntrySheet extends StatefulWidget {
  /// Creates a [CaptureEntrySheet].
  const CaptureEntrySheet({super.key});

  @override
  State<CaptureEntrySheet> createState() => _CaptureEntrySheetState();
}

class _CaptureEntrySheetState extends State<CaptureEntrySheet> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureEntryViewModel>(
      builder: (context, vm, _) {
        // React to terminal states that need navigation / dialogs.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _handleStateTransition(context, vm);
        });

        final isLoading = vm.state is CaptureEntryStateLoading;

        return _SheetBody(isLoading: isLoading);
      },
    );
  }

  void _handleStateTransition(
    BuildContext context,
    CaptureEntryViewModel vm,
  ) {
    switch (vm.state) {
      case CaptureEntryStatePermissionPermanentlyDenied():
        vm.reset();
        _showPermissionDialog(context);
      case CaptureEntryStatePermissionDenied():
        vm.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Camera permission is required to capture notation pages.',
            ),
          ),
        );
      case CaptureEntryStateCameraDone(:final imagePaths):
        vm.reset();
        if (!mounted) return;
        Navigator.of(context).pop(imagePaths);
      case CaptureEntryStateCameraEmpty():
        vm.reset();
        if (!mounted) return;
        Navigator.of(context).pop(<String>[]);
      case CaptureEntryStateGalleryDone(:final imagePaths):
        vm.reset();
        if (!mounted) return;
        Navigator.of(context).pop(imagePaths);
      case CaptureEntryStateIdle():
      case CaptureEntryStateLoading():
        break;
    }
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CameraPermissionDialog(),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet body
// ---------------------------------------------------------------------------

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: _kSheetPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 32.0,
            height: 4.0,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(height: _kHandleGap),
          // Title
          Text(
            'Add Notation Pages',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: _kTitleGap),
          // Camera option
          _CaptureOptionTile(
            icon: Icons.camera_alt_outlined,
            label: 'Camera',
            semanticsLabel: 'Capture pages using camera',
            enabled: !isLoading,
            onTap: () {
              context.read<CaptureEntryViewModel>().requestCameraAndLaunch();
            },
          ),
          const SizedBox(height: _kTileGap),
          // Gallery option
          _CaptureOptionTile(
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            semanticsLabel: 'Pick pages from gallery',
            enabled: !isLoading,
            onTap: () {
              context.read<CaptureEntryViewModel>().launchGallery();
            },
          ),
          if (isLoading) ...[
            const SizedBox(height: 16.0),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Option tile
// ---------------------------------------------------------------------------

class _CaptureOptionTile extends StatelessWidget {
  const _CaptureOptionTile({
    required this.icon,
    required this.label,
    required this.semanticsLabel,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String semanticsLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_kTileRadius),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(_kTileRadius),
          child: SizedBox(
            height: _kTileHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: enabled
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(97),
                    size: 28.0,
                  ),
                  const SizedBox(width: 16.0),
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withAlpha(97),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission dialog
// ---------------------------------------------------------------------------

/// Dialog shown when the camera permission has been permanently denied.
///
/// Provides a "Go to Settings" button that deep-links to the app's system
/// settings page so the user can re-enable the permission.
class _CameraPermissionDialog extends StatelessWidget {
  const _CameraPermissionDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Camera Permission Required'),
      content: const Text(
        'Swaralipi needs camera access to capture notation pages. '
        'Please enable it in Settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            unawaited(
              openAppSettings().catchError((Object e) {
                log(
                  'openAppSettings failed: $e',
                  name: 'CaptureEntrySheet',
                );
                return false;
              }),
            );
          },
          child: const Text('Go to Settings'),
        ),
      ],
    );
  }
}
