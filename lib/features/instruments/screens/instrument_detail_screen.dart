// InstrumentDetailScreen — read-only detail view for one instrument instance.
//
// Route: /settings/instruments/instance/:instanceId
//
// Shows all fields of the instance: photo (full-width), brand, model, color
// swatch, price, notes. Provides [Edit] and [Archive] actions.
//
// This screen does not depend on a ViewModel because it receives the fully
// loaded [InstrumentInstance] directly from its parent (the instances list).
// Mutations flow back via the shared [InstrumentInstancesViewModel].

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

/// Height of the hero photo area at the top of the detail screen.
const double _kPhotoHeight = 220.0;

/// Horizontal padding for the detail content.
const double _kContentPadding = 24.0;

/// Vertical spacing between detail rows.
const double _kRowSpacing = 12.0;

/// Shape for the bottom sheet modal.
const RoundedRectangleBorder _kSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Detail screen for a single instrument instance.
///
/// Displays all instance fields. Provides Edit and Archive actions via the
/// [InstrumentInstancesViewModel] provided in the widget tree.
class InstrumentDetailScreen extends StatefulWidget {
  /// Creates an [InstrumentDetailScreen].
  ///
  /// Parameters:
  /// - [instance]: The instrument instance to display.
  const InstrumentDetailScreen({
    super.key,
    required this.instance,
  });

  /// The instrument instance to display.
  final InstrumentInstance instance;

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  String? _absPhotoPath;

  @override
  void initState() {
    super.initState();
    _resolvePhoto();
  }

  @override
  void didUpdateWidget(InstrumentDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance.photoPath != widget.instance.photoPath) {
      _resolvePhoto();
    }
  }

  Future<void> _resolvePhoto() async {
    if (widget.instance.photoPath == null) return;
    final svc = InstrumentPhotoService();
    final abs = await svc.getAbsolutePath(widget.instance.photoPath!);
    if (!mounted) return;
    setState(() => _absPhotoPath = abs);
  }

  @override
  Widget build(BuildContext context) {
    final inst = widget.instance;
    final label = [inst.brand, inst.model]
        .where((s) => s != null && s.isNotEmpty)
        .join(' — ');
    final displayLabel =
        label.isNotEmpty ? label : 'Instrument ${inst.id.substring(0, 6)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(displayLabel),
        actions: [
          _EditAction(
            instance: inst,
            absPhotoPath: _absPhotoPath,
          ),
          _ArchiveAction(instance: inst),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PhotoHero(absPhotoPath: _absPhotoPath, colorHex: inst.colorHex),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _kContentPadding,
                vertical: _kContentPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (inst.brand != null)
                    _DetailRow(
                      icon: Icons.business_outlined,
                      label: 'Brand',
                      value: inst.brand!,
                    ),
                  if (inst.model != null) ...[
                    const SizedBox(height: _kRowSpacing),
                    _DetailRow(
                      icon: Icons.label_outline,
                      label: 'Model',
                      value: inst.model!,
                    ),
                  ],
                  const SizedBox(height: _kRowSpacing),
                  _ColorDetailRow(colorHex: inst.colorHex),
                  if (inst.priceInr != null) ...[
                    const SizedBox(height: _kRowSpacing),
                    _DetailRow(
                      icon: Icons.currency_rupee,
                      label: 'Price',
                      value: '₹${inst.priceInr}',
                    ),
                  ],
                  if (inst.notes.isNotEmpty) ...[
                    const SizedBox(height: _kRowSpacing),
                    _NotesRow(notes: inst.notes),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero photo
// ---------------------------------------------------------------------------

/// Full-width photo area at the top of the detail screen.
class _PhotoHero extends StatelessWidget {
  const _PhotoHero({required this.absPhotoPath, required this.colorHex});

  final String? absPhotoPath;
  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(colorHex);

    return SizedBox(
      height: _kPhotoHeight,
      child: absPhotoPath != null
          ? Image.file(File(absPhotoPath!), fit: BoxFit.cover)
          : Container(
              color: color.withValues(alpha: 0.15),
              child: Icon(
                Icons.piano_outlined,
                size: 72,
                color: color,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail rows
// ---------------------------------------------------------------------------

/// A single labeled row with icon, label, and value.
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Color swatch row with label.
class _ColorDetailRow extends StatelessWidget {
  const _ColorDetailRow({required this.colorHex});

  final String colorHex;

  @override
  Widget build(BuildContext context) {
    final colorName = kCatppuccinMochaNames[colorHex] ?? colorHex;

    return Row(
      children: [
        Icon(
          Icons.palette_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: colorFromHex(colorHex),
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  colorName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Notes section with icon and wrapped text.
class _NotesRow extends StatelessWidget {
  const _NotesRow({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.notes_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(
                notes,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar actions
// ---------------------------------------------------------------------------

/// Edit action button in the AppBar.
class _EditAction extends StatelessWidget {
  const _EditAction({
    required this.instance,
    required this.absPhotoPath,
  });

  final InstrumentInstance instance;
  final String? absPhotoPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit instrument',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: 'Edit',
        onPressed: () => _openEditSheet(context),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final vm = context.read<InstrumentInstancesViewModel>();
    final photoSvc = InstrumentPhotoService();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => InstrumentInstanceFormSheet(
        existingInstance: instance,
        currentPhotoAbsPath: absPhotoPath,
        onSave: (data) async {
          String? newRelativePath;

          if (data.photoPath != null && data.photoPath != absPhotoPath) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update. Please try again.')),
      );
      vm.clearUpdateError();
    }
  }
}

/// Archive action button in the AppBar.
class _ArchiveAction extends StatelessWidget {
  const _ArchiveAction({required this.instance});

  final InstrumentInstance instance;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Archive instrument',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.archive_outlined),
        tooltip: 'Archive',
        onPressed: () => _confirmAndArchive(context),
      ),
    );
  }

  Future<void> _confirmAndArchive(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive instrument?'),
        content: const Text(
          'Archiving will hide it from active lists. '
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

    if (confirmed != true) return;
    if (!context.mounted) return;

    final vm = context.read<InstrumentInstancesViewModel>();
    await vm.archiveInstance(instance.id);

    if (!context.mounted) return;
    if (vm.archiveError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not archive. Please try again.')),
      );
      vm.clearArchiveError();
    } else {
      Navigator.of(context).pop();
    }
  }
}
