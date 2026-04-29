// MetadataFormScreen — full-page metadata entry form for a new notation.
//
// Route: /capture/metadata (out-of-shell)
//
// The screen observes [MetadataFormViewModel] via [ChangeNotifierProvider] and
// renders one of three top-level states:
//   - deps loading → CircularProgressIndicator
//   - deps error   → error view with message
//   - deps success → scrollable form
//
// The Save button in the AppBar is enabled only when the title is non-empty.
// It delegates to [MetadataFormViewModel.save] and reacts to [saveState]:
//   - MetadataFormSaveDone → pop the route (caller navigates to library)
//   - MetadataFormSaveError → SnackBar error message
//
// Dependency injection:
//   ChangeNotifierProvider<MetadataFormViewModel>(
//     create: (_) => MetadataFormViewModel(...),
//     child: const MetadataFormScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/viewmodels/metadata_form_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/tag.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Horizontal padding for the form body.
const EdgeInsets _kFormPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 12);

/// Vertical gap between form sections.
const double _kSectionGap = 20.0;

/// Vertical gap between a section label and its content.
const double _kLabelGap = 8.0;

/// Vertical gap between two chips in a row.
const double _kChipSpacing = 8.0;

/// Maximum width of the form content, centered on wide screens.
const double _kMaxFormWidth = 640.0;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-page form for entering notation metadata before saving.
///
/// Reads [MetadataFormViewModel] from the widget tree via
/// [ChangeNotifierProvider]. Calls [MetadataFormViewModel.loadDependencies]
/// once on first frame.
class MetadataFormScreen extends StatefulWidget {
  /// Creates a [MetadataFormScreen].
  const MetadataFormScreen({super.key});

  @override
  State<MetadataFormScreen> createState() => _MetadataFormScreenState();
}

class _MetadataFormScreenState extends State<MetadataFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _timeSigController;
  late final TextEditingController _keySigController;
  late final TextEditingController _notesController;
  late final TextEditingController _artistInputController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _timeSigController = TextEditingController();
    _keySigController = TextEditingController();
    _notesController = TextEditingController();
    _artistInputController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MetadataFormViewModel>().loadDependencies();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeSigController.dispose();
    _keySigController.dispose();
    _notesController.dispose();
    _artistInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MetadataFormViewModel>();

    // React to save state changes
    _handleSaveState(vm.saveState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Notation'),
        actions: [
          _SaveButton(
            enabled: vm.isTitleValid,
            isSaving: vm.saveState is MetadataFormSaving,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (vm.depsState) {
        MetadataFormDepsIdle() => const SizedBox.shrink(),
        MetadataFormDepsLoading() => const _LoadingView(),
        MetadataFormDepsError(:final message) => _ErrorView(message: message),
        MetadataFormDepsSuccess(
          :final tags,
          :final instruments,
          :final customFieldDefinitions,
        ) =>
          _FormBody(
            tags: tags,
            instruments: instruments,
            customFieldDefinitions: customFieldDefinitions,
            titleController: _titleController,
            timeSigController: _timeSigController,
            keySigController: _keySigController,
            notesController: _notesController,
            artistInputController: _artistInputController,
          ),
      },
    );
  }

  void _handleSaveState(MetadataFormSaveState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (state) {
        case MetadataFormSaveDone():
          Navigator.of(context).pop();
        case MetadataFormSaveError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save: $message'),
            ),
          );
          // Reset to idle so the error snackbar does not repeat
          context.read<MetadataFormViewModel>().clearSaveError();
        case MetadataFormSaveIdle():
        case MetadataFormSaving():
          break;
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

/// AppBar action button that triggers [MetadataFormViewModel.save].
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.enabled, required this.isSaving});

  final bool enabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Save notation',
      button: true,
      child: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton(
              onPressed: enabled
                  ? () => context.read<MetadataFormViewModel>().save()
                  : null,
              child: const Text('Save'),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading and error views
// ---------------------------------------------------------------------------

/// Centered loading indicator while dependencies are loading.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Error view shown when dependency streams emit an error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load form data',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.error,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form body
// ---------------------------------------------------------------------------

/// Scrollable form with all 13 metadata fields.
class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.tags,
    required this.instruments,
    required this.customFieldDefinitions,
    required this.titleController,
    required this.timeSigController,
    required this.keySigController,
    required this.notesController,
    required this.artistInputController,
  });

  final List<Tag> tags;
  final List<InstrumentInstance> instruments;
  final List<CustomFieldDefinition> customFieldDefinitions;
  final TextEditingController titleController;
  final TextEditingController timeSigController;
  final TextEditingController keySigController;
  final TextEditingController notesController;
  final TextEditingController artistInputController;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MetadataFormViewModel>();
    final fs = vm.formState;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxFormWidth),
        child: ListView(
          padding: _kFormPadding,
          children: [
            // Title — required
            _TitleField(controller: titleController),
            const SizedBox(height: _kSectionGap),

            // Artists chip input
            _ArtistChipInput(
              artists: fs.artists,
              inputController: artistInputController,
            ),
            const SizedBox(height: _kSectionGap),

            // Date written
            _DateField(currentValue: fs.dateWritten),
            const SizedBox(height: _kSectionGap),

            // Time signature
            _TextFormRow(
              label: 'Time signature',
              hint: 'e.g. 4/4, 6/8',
              controller: timeSigController,
              onChanged: vm.setTimeSig,
            ),
            const SizedBox(height: _kSectionGap),

            // Key signature
            _TextFormRow(
              label: 'Key signature',
              hint: 'e.g. C major, Yaman',
              controller: keySigController,
              onChanged: vm.setKeySig,
            ),
            const SizedBox(height: _kSectionGap),

            // Languages
            _LanguageChips(selected: fs.languages),
            const SizedBox(height: _kSectionGap),

            // Tags
            if (tags.isNotEmpty) ...[
              _TagChips(tags: tags, selectedIds: fs.selectedTagIds),
              const SizedBox(height: _kSectionGap),
            ],

            // Instruments
            if (instruments.isNotEmpty) ...[
              _InstrumentChips(
                instruments: instruments,
                selectedIds: fs.selectedInstrumentIds,
              ),
              const SizedBox(height: _kSectionGap),
            ],

            // Personal notes
            _NotesField(controller: notesController),
            const SizedBox(height: _kSectionGap),

            // Custom fields
            if (customFieldDefinitions.isNotEmpty)
              _CustomFieldsSection(definitions: customFieldDefinitions),

            // Bottom padding so content is not obscured
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Title field
// ---------------------------------------------------------------------------

/// Required title text field.
class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Title',
        border: OutlineInputBorder(),
        hintText: 'Notation title',
      ),
      textCapitalization: TextCapitalization.sentences,
      onChanged: vm.setTitle,
    );
  }
}

// ---------------------------------------------------------------------------
// Artist chip input
// ---------------------------------------------------------------------------

/// Chip input row for adding and removing artist names.
class _ArtistChipInput extends StatelessWidget {
  const _ArtistChipInput({
    required this.artists,
    required this.inputController,
  });

  final List<String> artists;
  final TextEditingController inputController;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Artist(s)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: _kLabelGap),
        if (artists.isNotEmpty)
          Wrap(
            spacing: _kChipSpacing,
            runSpacing: _kChipSpacing,
            children: [
              for (var i = 0; i < artists.length; i++)
                InputChip(
                  label: Text(artists[i]),
                  onDeleted: () => vm.removeArtist(i),
                  deleteIconColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        if (artists.isNotEmpty) const SizedBox(height: _kLabelGap),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: inputController,
                decoration: const InputDecoration(
                  hintText: 'Add artist',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (value) {
                  vm.addArtist(value);
                  inputController.clear();
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                vm.addArtist(inputController.text);
                inputController.clear();
              },
              icon: const Icon(Icons.add),
              tooltip: 'Add artist',
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date field
// ---------------------------------------------------------------------------

/// Date picker row for the "Date written" field.
class _DateField extends StatelessWidget {
  const _DateField({required this.currentValue});

  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    final label = currentValue ?? 'Pick a date';

    return Row(
      children: [
        Expanded(
          child: Text(
            'Date written: $label',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton.icon(
          onPressed: () => _pickDate(context, vm),
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Select'),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    MetadataFormViewModel vm,
  ) async {
    final initial = currentValue != null
        ? DateTime.tryParse(currentValue!) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    // context.mounted is not available on StatelessWidget; the vm reference
    // is safe to use as it has no BuildContext dependency.
    vm.setDateWritten(
      '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}',
    );
  }
}

// ---------------------------------------------------------------------------
// Generic text form row
// ---------------------------------------------------------------------------

/// Labelled text field row (time sig, key sig).
class _TextFormRow extends StatelessWidget {
  const _TextFormRow({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

// ---------------------------------------------------------------------------
// Language chips
// ---------------------------------------------------------------------------

/// Multi-select filter chips for language selection.
class _LanguageChips extends StatelessWidget {
  const _LanguageChips({required this.selected});

  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: _kLabelGap),
        Wrap(
          spacing: _kChipSpacing,
          runSpacing: _kChipSpacing,
          children: kMetadataFormLanguages.map((lang) {
            final isSelected = selected.contains(lang);
            return FilterChip(
              label: Text(lang),
              selected: isSelected,
              onSelected: (_) => vm.toggleLanguage(lang),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tag chips
// ---------------------------------------------------------------------------

/// Multi-select filter chips for tag selection.
class _TagChips extends StatelessWidget {
  const _TagChips({required this.tags, required this.selectedIds});

  final List<Tag> tags;
  final List<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: _kLabelGap),
        Wrap(
          spacing: _kChipSpacing,
          runSpacing: _kChipSpacing,
          children: tags.map((tag) {
            final isSelected = selectedIds.contains(tag.id);
            return FilterChip(
              label: Text(tag.name),
              selected: isSelected,
              onSelected: (_) => vm.toggleTag(tag.id),
              avatar: CircleAvatar(
                backgroundColor: _colorFromHex(tag.colorHex),
                radius: 8,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Instrument chips
// ---------------------------------------------------------------------------

/// Multi-select filter chips for instrument selection.
class _InstrumentChips extends StatelessWidget {
  const _InstrumentChips({
    required this.instruments,
    required this.selectedIds,
  });

  final List<InstrumentInstance> instruments;
  final List<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instruments',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: _kLabelGap),
        Wrap(
          spacing: _kChipSpacing,
          runSpacing: _kChipSpacing,
          children: instruments.map((inst) {
            final isSelected = selectedIds.contains(inst.id);
            final label = _instanceLabel(inst);
            return FilterChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => vm.toggleInstrument(inst.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _instanceLabel(InstrumentInstance inst) {
    final parts = [inst.brand, inst.model].whereType<String>().toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return 'Instrument ${inst.id.substring(0, 4)}';
  }
}

// ---------------------------------------------------------------------------
// Notes field
// ---------------------------------------------------------------------------

/// Multiline text field for personal notes.
class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return TextField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Personal notes',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 4,
      textCapitalization: TextCapitalization.sentences,
      onChanged: vm.setNotes,
    );
  }
}

// ---------------------------------------------------------------------------
// Custom fields section
// ---------------------------------------------------------------------------

/// Dynamically rendered inputs for each [CustomFieldDefinition].
class _CustomFieldsSection extends StatelessWidget {
  const _CustomFieldsSection({required this.definitions});

  final List<CustomFieldDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom fields',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: _kLabelGap),
        ...definitions.map(
          (def) => Padding(
            padding: const EdgeInsets.only(bottom: _kSectionGap),
            child: _CustomFieldInput(definition: def),
          ),
        ),
      ],
    );
  }
}

/// A single custom field input rendered according to its [CustomFieldType].
class _CustomFieldInput extends StatelessWidget {
  const _CustomFieldInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    return switch (definition.fieldType) {
      CustomFieldType.text => _CustomTextInput(definition: definition),
      CustomFieldType.number => _CustomNumberInput(definition: definition),
      CustomFieldType.date => _CustomDateInput(definition: definition),
      CustomFieldType.boolean => _CustomBooleanInput(definition: definition),
    };
  }
}

class _CustomTextInput extends StatefulWidget {
  const _CustomTextInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  State<_CustomTextInput> createState() => _CustomTextInputState();
}

class _CustomTextInputState extends State<_CustomTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = context
            .read<MetadataFormViewModel>()
            .formState
            .customFieldValues[widget.definition.id]
            ?.textValue ??
        '';
    _controller = TextEditingController(text: existing);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.definition.keyName,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => vm.setCustomFieldText(widget.definition.id, v),
    );
  }
}

class _CustomNumberInput extends StatefulWidget {
  const _CustomNumberInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  State<_CustomNumberInput> createState() => _CustomNumberInputState();
}

class _CustomNumberInputState extends State<_CustomNumberInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = context
        .read<MetadataFormViewModel>()
        .formState
        .customFieldValues[widget.definition.id]
        ?.numberValue;
    _controller = TextEditingController(
      text: existing != null ? existing.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.definition.keyName,
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (v) {
        final n = double.tryParse(v);
        if (n != null) vm.setCustomFieldNumber(widget.definition.id, n);
      },
    );
  }
}

class _CustomDateInput extends StatelessWidget {
  const _CustomDateInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<MetadataFormViewModel>();
    final existing = vm.formState.customFieldValues[definition.id]?.dateValue;

    return Row(
      children: [
        Expanded(
          child: Text(
            '${definition.keyName}: ${existing ?? 'Not set'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        TextButton.icon(
          onPressed: () => _pickDate(context, vm),
          icon: const Icon(Icons.calendar_today_outlined),
          label: const Text('Select'),
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    MetadataFormViewModel vm,
  ) async {
    final existing = vm.formState.customFieldValues[definition.id]?.dateValue;
    final initial = existing != null
        ? DateTime.tryParse(existing) ?? DateTime.now()
        : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;
    // vm has no BuildContext; calling setCustomFieldDate is safe after await.
    vm.setCustomFieldDate(
      definition.id,
      '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}',
    );
  }
}

class _CustomBooleanInput extends StatelessWidget {
  const _CustomBooleanInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MetadataFormViewModel>();
    final value =
        vm.formState.customFieldValues[definition.id]?.booleanValue ?? false;

    return Row(
      children: [
        Expanded(
          child: Text(
            definition.keyName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Switch(
          value: value,
          onChanged: (v) => vm.setCustomFieldBoolean(definition.id, value: v),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Color helper
// ---------------------------------------------------------------------------

/// Parses a `'#RRGGBB'` hex string into a [Color].
///
/// Returns [Colors.grey] if the string is malformed.
Color _colorFromHex(String hex) {
  try {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return Colors.grey;
    return Color(int.parse('FF$cleaned', radix: 16));
  } on FormatException {
    return Colors.grey;
  }
}
