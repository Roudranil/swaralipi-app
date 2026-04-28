// InstrumentClassFormSheet — bottom sheet for creating or editing an
// instrument class name.
//
// The sheet contains a single text field for the class name. Tapping "Save"
// invokes [onSave] and closes the sheet. Tapping "Cancel" dismisses without
// calling [onSave].

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Maximum length for a class name.
const int _kMaxNameLength = 60;

/// Padding inside the bottom sheet.
const EdgeInsets _kSheetPadding = EdgeInsets.fromLTRB(24, 24, 24, 32);

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Modal bottom sheet for creating or editing an instrument class name.
///
/// Shows a text field pre-filled with [initialName] when editing. Calls
/// [onSave] with the trimmed name when the user confirms.
class InstrumentClassFormSheet extends StatefulWidget {
  /// Creates an [InstrumentClassFormSheet].
  ///
  /// Parameters:
  /// - [initialName]: Pre-filled name for editing; leave null for creation.
  /// - [onSave]: Callback invoked with the trimmed name when the user saves.
  const InstrumentClassFormSheet({
    super.key,
    this.initialName,
    required this.onSave,
  });

  /// Pre-filled name for the class. Null when creating a new class.
  final String? initialName;

  /// Callback invoked with the trimmed name when the user taps "Save".
  ///
  /// Parameters:
  /// - [name]: The trimmed class name entered by the user.
  final Future<void> Function(String name) onSave;

  @override
  State<InstrumentClassFormSheet> createState() =>
      _InstrumentClassFormSheetState();
}

class _InstrumentClassFormSheetState extends State<InstrumentClassFormSheet> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.initialName != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: _kSheetPadding,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isEditing ? 'Edit Class' : 'New Class',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                _NameField(
                  controller: _nameController,
                  saving: _saving,
                ),
                const SizedBox(height: 24),
                _FormActions(
                  saving: _saving,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_nameController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Text field for the instrument class name.
class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.saving,
  });

  final TextEditingController controller;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Class name',
      child: TextFormField(
        controller: controller,
        enabled: !saving,
        maxLength: _kMaxNameLength,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Name',
          hintText: 'e.g. Sitar, Tabla, Bansuri',
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return 'Name is required.';
          return null;
        },
        onFieldSubmitted: (_) {},
      ),
    );
  }
}

/// Row of Cancel and Save buttons.
class _FormActions extends StatelessWidget {
  const _FormActions({
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool saving;
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
            onPressed: saving ? null : onCancel,
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Save class',
          button: true,
          child: FilledButton(
            onPressed: saving ? null : onSave,
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ),
      ],
    );
  }
}
