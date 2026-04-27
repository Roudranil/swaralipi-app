// CustomFieldFormSheet — bottom sheet for creating or editing a custom field
// definition.
//
// Accepts an optional [initialKeyName] and [initialFieldType] for edit mode.
// Calls [onSave] with the trimmed key name and selected type string on confirm.
//
// The form validates that the key name is non-empty before enabling save.

import 'package:flutter/material.dart';

import 'package:swaralipi/shared/models/custom_field_definition.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Vertical padding inside the bottom sheet.
const EdgeInsets _kSheetPadding = EdgeInsets.fromLTRB(24, 20, 24, 24);

/// Spacing between form fields.
const double _kFieldSpacing = 16.0;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Modal bottom sheet for creating or editing a custom field definition.
///
/// Displays a text field for the key name and a [SegmentedButton] for
/// selecting the field type. The save button is disabled while the key name
/// is empty.
///
/// Dependencies are passed via constructor injection:
/// ```dart
/// CustomFieldFormSheet(onSave: (keyName, fieldType) async { ... })
/// ```
class CustomFieldFormSheet extends StatefulWidget {
  /// Creates a [CustomFieldFormSheet].
  ///
  /// Parameters:
  /// - [onSave]: Called with the trimmed key name and field type string when
  ///   the user confirms.
  /// - [initialKeyName]: Pre-filled key name for edit mode.
  /// - [initialFieldType]: Pre-selected field type for edit mode. Defaults to
  ///   `'text'`.
  const CustomFieldFormSheet({
    super.key,
    required this.onSave,
    this.initialKeyName,
    this.initialFieldType = 'text',
  });

  /// Callback invoked with `(keyName, fieldType)` when the user taps Save.
  final Future<void> Function(String keyName, String fieldType) onSave;

  /// Pre-filled key name; `null` for create mode.
  final String? initialKeyName;

  /// Pre-selected field type string; defaults to `'text'`.
  final String initialFieldType;

  @override
  State<CustomFieldFormSheet> createState() => _CustomFieldFormSheetState();
}

class _CustomFieldFormSheetState extends State<CustomFieldFormSheet> {
  late final TextEditingController _keyNameController;
  late String _selectedType;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _keyNameController = TextEditingController(
      text: widget.initialKeyName ?? '',
    );
    _selectedType = widget.initialFieldType;
    _keyNameController.addListener(_onKeyNameChanged);
  }

  @override
  void dispose() {
    _keyNameController.removeListener(_onKeyNameChanged);
    _keyNameController.dispose();
    super.dispose();
  }

  void _onKeyNameChanged() => setState(() {});

  bool get _canSave => _keyNameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        _keyNameController.text.trim(),
        _selectedType,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialKeyName != null;

    return Padding(
      padding: _kSheetPadding.copyWith(
        bottom: _kSheetPadding.bottom + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHandle(),
          const SizedBox(height: 16),
          Text(
            isEditing ? 'Edit field' : 'New custom field',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: _kFieldSpacing),
          _KeyNameField(controller: _keyNameController),
          const SizedBox(height: _kFieldSpacing),
          _FieldTypeSelector(
            selected: _selectedType,
            onChanged: (type) => setState(() => _selectedType = type),
          ),
          const SizedBox(height: 24),
          _SaveButton(
            isSaving: _isSaving,
            canSave: _canSave,
            onSave: _handleSave,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Visual drag handle for the bottom sheet.
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(76),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Text field for the custom field key name.
class _KeyNameField extends StatelessWidget {
  const _KeyNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Field name',
      child: TextField(
        controller: controller,
        autofocus: true,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Field name',
          hintText: 'e.g. raga_name',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}

/// Segmented button for selecting a [CustomFieldType].
class _FieldTypeSelector extends StatelessWidget {
  const _FieldTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Field type',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'text',
                label: Text('Text'),
                icon: Icon(Icons.text_fields_outlined),
              ),
              ButtonSegment(
                value: 'number',
                label: Text('Number'),
                icon: Icon(Icons.numbers_outlined),
              ),
              ButtonSegment(
                value: 'date',
                label: Text('Date'),
                icon: Icon(Icons.calendar_today_outlined),
              ),
              ButtonSegment(
                value: 'boolean',
                label: Text('Bool'),
                icon: Icon(Icons.toggle_on_outlined),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (set) {
              if (set.isNotEmpty) onChanged(set.first);
            },
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

/// Save button with loading indicator support.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.canSave,
    required this.onSave,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: canSave ? onSave : null,
      child: isSaving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Save'),
    );
  }
}
