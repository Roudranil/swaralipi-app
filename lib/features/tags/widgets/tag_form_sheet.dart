// TagFormSheet — modal bottom sheet for creating or editing a tag.
//
// Shows a name text field and a Catppuccin Mocha color grid picker. The
// [initialName] and [initialColorHex] parameters pre-fill the form for
// edit mode; both are omitted for create mode.
//
// The [onSave] callback is invoked only when the form is valid (non-empty name
// and a color is selected). The sheet closes itself after a successful save.
//
// Usage — create:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => TagFormSheet(onSave: (name, hex) async { ... }),
//   );
//
// Usage — edit:
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     builder: (_) => TagFormSheet(
//       initialName: tag.name,
//       initialColorHex: tag.colorHex,
//       onSave: (name, hex) async { ... },
//     ),
//   );

import 'package:flutter/material.dart';

import 'package:swaralipi/features/tags/widgets/catppuccin_color_picker.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Maximum characters allowed for a tag name.
const int _kTagNameMaxLength = 50;

/// Padding around the sheet content.
const EdgeInsets _kSheetPadding = EdgeInsets.fromLTRB(24, 16, 24, 24);

/// Vertical space between form sections.
const double _kSectionSpacing = 20.0;

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

/// A modal bottom sheet form for creating or editing a tag.
///
/// Provides a name field and a [CatppuccinColorPicker]. The [onSave] callback
/// is invoked with the trimmed name and selected color hex when the user taps
/// Save and the form is valid.
class TagFormSheet extends StatefulWidget {
  /// Creates a [TagFormSheet].
  ///
  /// Parameters:
  /// - [initialName]: Pre-filled name for edit mode; omit for create mode.
  /// - [initialColorHex]: Pre-selected color for edit mode; omit for create.
  /// - [onSave]: Async callback receiving the validated (name, colorHex) pair.
  const TagFormSheet({
    super.key,
    this.initialName,
    this.initialColorHex,
    required this.onSave,
  });

  /// Pre-filled tag name when editing an existing tag.
  final String? initialName;

  /// Pre-selected Catppuccin hex color when editing an existing tag.
  final String? initialColorHex;

  /// Called with `(name, colorHex)` when the form is submitted and valid.
  final Future<void> Function(String name, String colorHex) onSave;

  @override
  State<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends State<TagFormSheet> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  String? _selectedColorHex;
  bool _isSaving = false;
  String? _colorError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selectedColorHex = widget.initialColorHex;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // Validate color selection separately since it's not a FormField.
    if (_selectedColorHex == null) {
      setState(() => _colorError = 'Please select a color');
      return;
    }
    setState(() => _colorError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    await widget.onSave(
      _nameController.text.trim(),
      _selectedColorHex!,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return Padding(
      // Shift sheet up when the keyboard is visible.
      padding: _kSheetPadding.copyWith(
        bottom:
            _kSheetPadding.bottom + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHandle(),
            const SizedBox(height: 8),
            Text(
              isEditing ? 'Edit Tag' : 'New Tag',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: _kSectionSpacing),
            _NameField(controller: _nameController),
            const SizedBox(height: _kSectionSpacing),
            _ColorPickerSection(
              selectedColorHex: _selectedColorHex,
              errorText: _colorError,
              onColorSelected: (hex) {
                setState(() {
                  _selectedColorHex = hex;
                  _colorError = null;
                });
              },
            ),
            const SizedBox(height: _kSectionSpacing),
            _SaveCancelRow(
              isSaving: _isSaving,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Draggable handle indicator at the top of the sheet.
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Tag name text field with validation.
class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLength: _kTagNameMaxLength,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Name',
        border: OutlineInputBorder(),
        counterText: '',
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) return 'Name cannot be empty';
        return null;
      },
    );
  }
}

/// Color picker section with label and optional error text.
class _ColorPickerSection extends StatelessWidget {
  const _ColorPickerSection({
    required this.selectedColorHex,
    required this.onColorSelected,
    this.errorText,
  });

  final String? selectedColorHex;
  final ValueChanged<String> onColorSelected;
  final String? errorText;

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
        const SizedBox(height: 12),
        CatppuccinColorPicker(
          selectedColorHex: selectedColorHex,
          onColorSelected: onColorSelected,
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ],
    );
  }
}

/// Row with Cancel and Save buttons.
class _SaveCancelRow extends StatelessWidget {
  const _SaveCancelRow({
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Semantics(
          label: 'Cancel',
          button: true,
          child: TextButton(
            onPressed: isSaving ? null : onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Save tag',
          button: true,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
