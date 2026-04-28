// InstrumentInstancesScreen — lists active instances for one instrument class.
//
// Route: /settings/instruments/:classId/instances  (shell navigation)
//
// Observes [InstrumentInstancesViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (instance list), error.
// Each row shows the instrument thumbnail, brand/model, and color swatch.
// Tapping a row navigates to [InstrumentDetailScreen]. Swiping to the left
// archives the instance (with confirmation). The FAB opens
// [InstrumentInstanceFormSheet] to create a new instance.
//
// Dependencies injected at call site:
//   ChangeNotifierProvider<InstrumentInstancesViewModel>(
//     create: (_) => InstrumentInstancesViewModel(repo, classId: id)..init(),
//     child: const InstrumentInstancesScreen(),
//   )

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/storage/instrument_photo_service.dart';
import 'package:swaralipi/features/instruments/viewmodels/instrument_instances_view_model.dart';
import 'package:swaralipi/features/instruments/widgets/instrument_instance_form_sheet.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/features/tags/widgets/catppuccin_color_picker.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Minimum touch target height for each instance row.
const double _kRowMinHeight = 72.0;

/// Horizontal and vertical list padding.
const EdgeInsets _kListPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 8);

/// Photo thumbnail size on the instance row.
const double _kThumbnailSize = 48.0;

/// Shape for the bottom sheet modal.
const RoundedRectangleBorder _kSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen listing all active instrument instances for one class.
///
/// Reads [InstrumentInstancesViewModel] from the widget tree. Calls
/// [InstrumentInstancesViewModel.init] after the first frame.
class InstrumentInstancesScreen extends StatefulWidget {
  /// Creates an [InstrumentInstancesScreen].
  const InstrumentInstancesScreen({super.key});

  @override
  State<InstrumentInstancesScreen> createState() =>
      _InstrumentInstancesScreenState();
}

class _InstrumentInstancesScreenState extends State<InstrumentInstancesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstrumentInstancesViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InstrumentInstancesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruments'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        tooltip: 'Add instrument',
        child: const Icon(Icons.add),
      ),
      body: switch (vm.state) {
        InstrumentInstancesStateIdle() => const SizedBox.shrink(),
        InstrumentInstancesStateLoading() => const _LoadingView(),
        InstrumentInstancesStateSuccess(:final instances) => instances.isEmpty
            ? const _EmptyView()
            : _InstanceListView(instances: instances),
        InstrumentInstancesStateError(:final message) =>
          _ErrorView(message: message),
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final vm = context.read<InstrumentInstancesViewModel>();
    final photoSvc = InstrumentPhotoService();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => InstrumentInstanceFormSheet(
        onSave: (data) async {
          String? savedPhotoPath;
          if (data.photoPath != null) {
            savedPhotoPath = await photoSvc.savePhoto(data.photoPath!, 'temp');
          }
          await vm.createInstance(
            colorHex: data.colorHex,
            brand: data.brand,
            model: data.model,
            priceInr: data.priceInr,
            photoPath: savedPhotoPath,
            notes: data.notes,
          );
        },
      ),
    );

    if (!mounted) return;
    if (vm.createError != null) {
      _showErrorSnackBar(context, 'Could not create instrument.');
      vm.clearCreateError();
    }
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the instance stream initializes.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Empty state view when no instances exist.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.piano_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No instruments yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first instrument.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error view when the stream emits an error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load instruments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list of instrument instance rows.
class _InstanceListView extends StatelessWidget {
  const _InstanceListView({required this.instances});

  final List<InstrumentInstance> instances;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: instances.length,
      itemBuilder: (context, index) => _InstanceRow(instance: instances[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Instance row
// ---------------------------------------------------------------------------

/// A single instance row with thumbnail, brand/model label, color swatch, and
/// swipe-to-archive.
class _InstanceRow extends StatelessWidget {
  const _InstanceRow({required this.instance});

  final InstrumentInstance instance;

  @override
  Widget build(BuildContext context) {
    final label = [instance.brand, instance.model]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    final displayLabel =
        label.isNotEmpty ? label : 'Instrument ${instance.id.substring(0, 6)}';

    return Semantics(
      label: 'Instrument: $displayLabel',
      child: Dismissible(
        key: ValueKey(instance.id),
        direction: DismissDirection.endToStart,
        background: const _SwipeArchiveBackground(),
        confirmDismiss: (_) => _confirmArchive(context, displayLabel),
        onDismissed: (_) => _archiveInstance(context),
        child: SizedBox(
          height: _kRowMinHeight,
          child: Row(
            children: [
              _Thumbnail(instance: instance),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayLabel,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (instance.priceInr != null)
                      Text(
                        '₹${instance.priceInr}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ),
              _ColorSwatch(colorHex: instance.colorHex),
              _EditButton(instance: instance),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmArchive(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive instrument?'),
        content: Text(
          'Archiving "$label" will hide it from active lists. '
          'Existing notation associations remain visible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveInstance(BuildContext context) async {
    final vm = context.read<InstrumentInstancesViewModel>();
    await vm.archiveInstance(instance.id);
    if (!context.mounted) return;
    if (vm.archiveError != null) {
      _showErrorSnackBar(context, 'Could not archive. Please try again.');
      vm.clearArchiveError();
    }
  }
}

/// Square thumbnail showing photo or a color-filled placeholder.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.instance});

  final InstrumentInstance instance;

  @override
  Widget build(BuildContext context) {
    final photoPath = instance.photoPath;
    final color = colorFromHex(instance.colorHex);

    return Container(
      width: _kThumbnailSize,
      height: _kThumbnailSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: photoPath != null
          ? _ResolvedPhoto(relativePath: photoPath)
          : Icon(Icons.piano_outlined, color: color, size: 28),
    );
  }
}

/// Resolves a relative photo path and displays the image.
class _ResolvedPhoto extends StatefulWidget {
  const _ResolvedPhoto({required this.relativePath});

  final String relativePath;

  @override
  State<_ResolvedPhoto> createState() => _ResolvedPhotoState();
}

class _ResolvedPhotoState extends State<_ResolvedPhoto> {
  String? _absPath;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final svc = InstrumentPhotoService();
    final abs = await svc.getAbsolutePath(widget.relativePath);
    if (!mounted) return;
    setState(() => _absPath = abs);
  }

  @override
  Widget build(BuildContext context) {
    if (_absPath == null) {
      return const SizedBox.shrink();
    }
    return Image.file(File(_absPath!), fit: BoxFit.cover);
  }
}

/// Small color swatch chip showing the instance color.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.colorHex});

  final String colorHex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: colorFromHex(colorHex),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Amber swipe-to-archive background.
class _SwipeArchiveBackground extends StatelessWidget {
  const _SwipeArchiveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.archive_outlined,
        color: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    );
  }
}

/// Edit icon button that opens the form sheet pre-filled.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.instance});

  final InstrumentInstance instance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit instrument',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _openEditSheet(context),
        tooltip: 'Edit',
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final vm = context.read<InstrumentInstancesViewModel>();
    final photoSvc = InstrumentPhotoService();

    String? absPath;
    if (instance.photoPath != null) {
      absPath = await photoSvc.getAbsolutePath(instance.photoPath!);
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => InstrumentInstanceFormSheet(
        existingInstance: instance,
        currentPhotoAbsPath: absPath,
        onSave: (data) async {
          String? newRelativePath;

          // If a new photo was picked (absolute path differs from resolved
          // existing), save it and delete the old one.
          if (data.photoPath != null && data.photoPath != absPath) {
            newRelativePath =
                await photoSvc.savePhoto(data.photoPath!, instance.id);
            if (instance.photoPath != null) {
              await photoSvc.deletePhoto(instance.photoPath!);
            }
          } else {
            newRelativePath = instance.photoPath;
          }

          await vm.updateInstance(
            instance.id,
            brand: data.brand,
            model: data.model,
            colorHex: data.colorHex,
            priceInr: data.priceInr,
            photoPath: newRelativePath,
            notes: data.notes,
          );
        },
      ),
    );

    if (!context.mounted) return;
    if (vm.updateError != null) {
      _showErrorSnackBar(context, 'Could not update. Please try again.');
      vm.clearUpdateError();
    }
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Shows a brief error [SnackBar].
///
/// Parameters:
/// - [context]: Build context with an active [Scaffold] in its tree.
/// - [message]: The error message to display.
void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
