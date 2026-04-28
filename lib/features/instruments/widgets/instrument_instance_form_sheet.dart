// InstrumentInstanceFormSheet — bottom sheet form for creating or editing an
// instrument instance.
//
// Fields: Brand (optional), Model (optional), Color (Catppuccin picker),
// Price in INR (optional), Photo (gallery/camera via image_picker), Notes.
//
// Usage:
//   await showModalBottomSheet<void>(
//     context: context,
//     isScrollControlled: true,
//     shape: _kSheetShape,
//     builder: (_) => InstrumentInstanceFormSheet(
//       onSave: (data) async { ... },
//     ),
//   );

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

import 'package:swaralipi/features/tags/widgets/catppuccin_color_picker.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

/// Holds the validated form values collected by [InstrumentInstanceFormSheet].
class InstrumentInstanceFormData {
  /// Creates an [InstrumentInstanceFormData].
  ///
  /// Parameters:
  /// - [brand]: Optional brand name.
  /// - [model]: Optional model name.
  /// - [colorHex]: Selected Catppuccin hex color.
  /// - [priceInr]: Optional purchase price in INR.
  /// - [photoPath]: Absolute path to the selected photo; nullable.
  /// - [notes]: Free-form notes.
  const InstrumentInstanceFormData({
    this.brand,
    this.model,
    required this.colorHex,
    this.priceInr,
    this.photoPath,
    this.notes = '',
  });

  /// Optional brand name.
  final String? brand;

  /// Optional model name.
  final String? model;

  /// Selected Catppuccin hex color.
  final String colorHex;

  /// Optional purchase price in INR.
  final int? priceInr;

  /// Absolute path to the selected photo; nullable.
  final String? photoPath;

  /// Free-form notes.
  final String notes;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Default Catppuccin hex color used when no color is pre-selected.
const String _kDefaultColorHex = '#cba6f7';

/// Minimum height of the sheet to show most fields without scrolling.
const double _kMinSheetHeight = 0.85;

/// Spacing between form fields.
const double _kFieldSpacing = 16.0;

// ---------------------------------------------------------------------------
// Sheet
// ---------------------------------------------------------------------------

/// A scrollable bottom sheet form for creating or editing an instrument
/// instance.
///
/// Provides fields for brand, model, color (Catppuccin palette), price (INR),
/// photo (gallery or camera), and notes. The [onSave] callback is invoked with
/// an [InstrumentInstanceFormData] when the form is submitted.
///
/// Pre-fill all optional parameters when editing an existing instance.
class InstrumentInstanceFormSheet extends StatefulWidget {
  /// Creates an [InstrumentInstanceFormSheet].
  ///
  /// Parameters:
  /// - [existingInstance]: Pre-fills all fields when editing. `null` for
  ///   creation.
  /// - [currentPhotoAbsPath]: The resolved absolute path of the current photo;
  ///   used to display the thumbnail when editing.
  /// - [onSave]: Async callback receiving the validated [InstrumentInstanceFormData].
  const InstrumentInstanceFormSheet({
    super.key,
    this.existingInstance,
    this.currentPhotoAbsPath,
    required this.onSave,
  });

  /// Pre-fills all fields when editing an existing instance. `null` for
  /// creation.
  final InstrumentInstance? existingInstance;

  /// Resolved absolute path of the existing photo (used for the thumbnail).
  final String? currentPhotoAbsPath;

  /// Async callback invoked when the form is submitted and valid.
  final Future<void> Function(InstrumentInstanceFormData data) onSave;

  @override
  State<InstrumentInstanceFormSheet> createState() =>
      _InstrumentInstanceFormSheetState();
}

class _InstrumentInstanceFormSheetState
    extends State<InstrumentInstanceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedColor;
  String? _newPhotoPath; // absolute path of a newly picked photo
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final inst = widget.existingInstance;
    _brandCtrl = TextEditingController(text: inst?.brand ?? '');
    _modelCtrl = TextEditingController(text: inst?.model ?? '');
    _priceCtrl = TextEditingController(
      text: inst?.priceInr != null ? '${inst!.priceInr}' : '',
    );
    _notesCtrl = TextEditingController(text: inst?.notes ?? '');
    _selectedColor = inst?.colorHex ?? _kDefaultColorHex;
  }

  @override
  void dispose() {
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingInstance != null;

    return DraggableScrollableSheet(
      initialChildSize: _kMinSheetHeight,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  Text(
                    isEditing ? 'Edit Instrument' : 'Add Instrument',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PhotoPickerRow(
                        newPhotoPath: _newPhotoPath,
                        existingPhotoPath: widget.currentPhotoAbsPath,
                        onPhotoSelected: (path) =>
                            setState(() => _newPhotoPath = path),
                      ),
                      const SizedBox(height: _kFieldSpacing),
                      _BrandField(controller: _brandCtrl),
                      const SizedBox(height: _kFieldSpacing),
                      _ModelField(controller: _modelCtrl),
                      const SizedBox(height: _kFieldSpacing),
                      _PriceField(controller: _priceCtrl),
                      const SizedBox(height: _kFieldSpacing),
                      _ColorSection(
                        selectedColorHex: _selectedColor,
                        onColorSelected: (hex) =>
                            setState(() => _selectedColor = hex),
                      ),
                      const SizedBox(height: _kFieldSpacing),
                      _NotesField(controller: _notesCtrl),
                      const SizedBox(height: 24),
                      _SaveButton(
                        isSaving: _isSaving,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    final priceText = _priceCtrl.text.trim();
    final priceInr = priceText.isEmpty ? null : int.tryParse(priceText);

    final brand =
        _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim();
    final model =
        _modelCtrl.text.trim().isEmpty ? null : _modelCtrl.text.trim();

    // Determine photo path: prefer newly picked, else keep existing.
    String? photoPath = _newPhotoPath;
    if (photoPath == null && widget.existingInstance?.photoPath != null) {
      photoPath = widget.existingInstance!.photoPath; // still the relative path
    }

    final data = InstrumentInstanceFormData(
      brand: brand,
      model: model,
      colorHex: _selectedColor,
      priceInr: priceInr,
      // Pass new absolute path so caller can use InstrumentPhotoService.
      photoPath: _newPhotoPath ?? widget.currentPhotoAbsPath,
      notes: _notesCtrl.text.trim(),
    );

    await widget.onSave(data);

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

/// Drag handle pill at the top of the sheet.
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Photo picker row showing thumbnail and pick buttons.
class _PhotoPickerRow extends StatelessWidget {
  const _PhotoPickerRow({
    required this.newPhotoPath,
    required this.existingPhotoPath,
    required this.onPhotoSelected,
  });

  final String? newPhotoPath;
  final String? existingPhotoPath;
  final ValueChanged<String> onPhotoSelected;

  @override
  Widget build(BuildContext context) {
    final displayPath = newPhotoPath ?? existingPhotoPath;

    return Row(
      children: [
        _PhotoThumbnail(photoPath: displayPath),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PickPhotoButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              source: ImageSource.gallery,
              onPhotoSelected: onPhotoSelected,
            ),
            const SizedBox(height: 8),
            _PickPhotoButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              source: ImageSource.camera,
              onPhotoSelected: onPhotoSelected,
            ),
          ],
        ),
      ],
    );
  }
}

/// Square thumbnail for the selected photo, or a placeholder icon.
class _PhotoThumbnail extends StatelessWidget {
  const _PhotoThumbnail({this.photoPath});

  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          photoPath != null ? 'Selected instrument photo' : 'No photo selected',
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: photoPath != null
            ? Image.file(File(photoPath!), fit: BoxFit.cover)
            : Icon(
                Icons.image_outlined,
                size: 36,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
      ),
    );
  }
}

/// Button that opens the image picker with [source].
class _PickPhotoButton extends StatelessWidget {
  const _PickPhotoButton({
    required this.icon,
    required this.label,
    required this.source,
    required this.onPhotoSelected,
  });

  final IconData icon;
  final String label;
  final ImageSource source;
  final ValueChanged<String> onPhotoSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pick photo from $label',
      button: true,
      child: OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: () => _pickPhoto(context),
      ),
    );
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 85);
    if (xFile == null) return;
    if (!context.mounted) return;
    onPhotoSelected(xFile.path);
  }
}

/// Brand name text field.
class _BrandField extends StatelessWidget {
  const _BrandField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Brand name',
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Brand',
          hintText: 'e.g. Yamaha',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

/// Model name text field.
class _ModelField extends StatelessWidget {
  const _ModelField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Model name',
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Model',
          hintText: 'e.g. C40',
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.words,
      ),
    );
  }
}

/// Price in INR text field (digits only).
class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Price in INR',
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Price (₹)',
          hintText: 'e.g. 15000',
          border: OutlineInputBorder(),
          prefixText: '₹ ',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) return null;
          final n = int.tryParse(value);
          if (n == null || n < 0) {
            return 'Enter a valid non-negative number';
          }
          return null;
        },
      ),
    );
  }
}

/// Color picker section showing a label and the Catppuccin grid.
class _ColorSection extends StatelessWidget {
  const _ColorSection({
    required this.selectedColorHex,
    required this.onColorSelected,
  });

  final String selectedColorHex;
  final ValueChanged<String> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        CatppuccinColorPicker(
          selectedColorHex: selectedColorHex,
          onColorSelected: onColorSelected,
        ),
      ],
    );
  }
}

/// Notes multi-line text field.
class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Notes',
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Notes',
          hintText: 'Optional notes…',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
        ),
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }
}

/// Save / submit button.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Save instrument',
      button: true,
      child: FilledButton(
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    );
  }
}
