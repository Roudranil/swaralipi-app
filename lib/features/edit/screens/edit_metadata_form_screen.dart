// edit_metadata_form_screen.dart — Metadata form screen for the edit flow.
//
// Reuses the MetadataFormViewModel for loading picker dependencies (tags,
// instruments, custom fields) but delegates the save operation to
// EditNotationViewModel so that the edit path calls
// NotationRepository.updateNotation instead of saveNotation.
//
// The form is pre-populated by reading EditNotationViewModel.formState on
// first frame and pushing those values into the MetadataFormViewModel and
// the associated TextEditingControllers.
//
// On successful save (EditNotationSaveDone), the screen navigates back by
// popping until the route at depth 0 (NotationDetailScreen) is reached.
//
// Dependencies are provided above this widget via ChangeNotifierProvider:
//   - EditNotationViewModel (for current form state + save)
//   - CaptureSessionViewModel (for updated pages from the page editor)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/features/capture/viewmodels/metadata_form_view_model.dart';
import 'package:swaralipi/features/edit/viewmodels/edit_notation_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/render_params.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

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

/// Metadata form screen for the edit-notation flow.
///
/// Pre-populates the form from [EditNotationViewModel.formState] and saves
/// via [EditNotationViewModel.save] using pages from [CaptureSessionViewModel].
///
/// Reads [EditNotationViewModel] and [CaptureSessionViewModel] from the
/// widget tree. Also creates an internal [MetadataFormViewModel] solely for
/// loading picker dependencies (tags, instruments, custom field definitions).
class EditMetadataFormScreen extends StatefulWidget {
  /// Creates an [EditMetadataFormScreen].
  ///
  /// Parameters:
  /// - [notationId]: UUIDv4 of the notation being edited.
  /// - [tagRepository]: Source of truth for tags.
  /// - [instrumentRepository]: Source of truth for instruments.
  /// - [customFieldRepository]: Source of truth for custom field definitions.
  const EditMetadataFormScreen({
    required this.notationId,
    required this.tagRepository,
    required this.instrumentRepository,
    required this.customFieldRepository,
    super.key,
  });

  /// UUIDv4 of the notation being edited.
  final String notationId;

  /// Source of truth for tags.
  final TagRepository tagRepository;

  /// Source of truth for instruments.
  final InstrumentRepository instrumentRepository;

  /// Source of truth for custom field definitions.
  final CustomFieldRepository customFieldRepository;

  @override
  State<EditMetadataFormScreen> createState() => _EditMetadataFormScreenState();
}

class _EditMetadataFormScreenState extends State<EditMetadataFormScreen> {
  late final MetadataFormViewModel _depsVm;
  late final TextEditingController _titleController;
  late final TextEditingController _timeSigController;
  late final TextEditingController _keySigController;
  late final TextEditingController _notesController;
  late final TextEditingController _artistInputController;

  bool _prePopulated = false;

  @override
  void initState() {
    super.initState();
    _depsVm = MetadataFormViewModel(
      tagRepository: widget.tagRepository,
      instrumentRepository: widget.instrumentRepository,
      customFieldRepository: widget.customFieldRepository,
      // NotationRepository and FileStorageService not used in edit deps mode.
      notationRepository: _NoopNotationRepository(),
      fileStorageService: _NoopFileStorageService(),
      drafts: const [],
    );

    _titleController = TextEditingController();
    _timeSigController = TextEditingController();
    _keySigController = TextEditingController();
    _notesController = TextEditingController();
    _artistInputController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _depsVm.loadDependencies();
      _prePopulateControllers();
    });
  }

  void _prePopulateControllers() {
    final editVm = context.read<EditNotationViewModel>();
    final fs = editVm.formState;

    // Sync text controllers with pre-populated form state.
    _titleController.text = fs.title;
    _timeSigController.text = fs.timeSig ?? '';
    _keySigController.text = fs.keySig ?? '';
    _notesController.text = fs.notes;

    // Keep EditNotationViewModel in sync with initial controller values.
    editVm
      ..setTitle(fs.title)
      ..setTimeSig(fs.timeSig ?? '')
      ..setKeySig(fs.keySig ?? '')
      ..setNotes(fs.notes);

    setState(() => _prePopulated = true);
  }

  @override
  void dispose() {
    _depsVm.dispose();
    _titleController.dispose();
    _timeSigController.dispose();
    _keySigController.dispose();
    _notesController.dispose();
    _artistInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editVm = context.watch<EditNotationViewModel>();

    // React to save state changes.
    _handleSaveState(editVm.saveState);

    return ChangeNotifierProvider<MetadataFormViewModel>.value(
      value: _depsVm,
      child: Builder(
        builder: (innerContext) {
          final depsVm = innerContext.watch<MetadataFormViewModel>();

          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Notation'),
              actions: [
                _EditSaveButton(
                  enabled: editVm.isTitleValid,
                  isSaving: editVm.saveState is EditNotationSaving,
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: switch (depsVm.depsState) {
              MetadataFormDepsIdle() ||
              MetadataFormDepsLoading() =>
                const _LoadingView(),
              MetadataFormDepsError(:final message) =>
                _ErrorView(message: message),
              MetadataFormDepsSuccess(
                :final tags,
                :final instruments,
                :final customFieldDefinitions,
              ) =>
                _prePopulated
                    ? _EditFormBody(
                        tags: tags,
                        instruments: instruments,
                        customFieldDefinitions: customFieldDefinitions,
                        titleController: _titleController,
                        timeSigController: _timeSigController,
                        keySigController: _keySigController,
                        notesController: _notesController,
                        artistInputController: _artistInputController,
                      )
                    : const _LoadingView(),
            },
          );
        },
      ),
    );
  }

  void _handleSaveState(EditNotationSaveState state) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (state) {
        case EditNotationSaveDone():
          // Pop all edit screens back to the caller (NotationDetailScreen).
          Navigator.of(context).popUntil((route) => route.isFirst);
        case EditNotationSaveError(:final message):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not save: $message'),
            ),
          );
          context.read<EditNotationViewModel>().clearSaveError();
        case EditNotationSaveIdle():
        case EditNotationSaving():
          break;
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

/// AppBar action button that triggers the edit save.
class _EditSaveButton extends StatelessWidget {
  const _EditSaveButton({required this.enabled, required this.isSaving});

  final bool enabled;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Save changes',
      button: true,
      child: isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : FilledButton(
              onPressed: enabled ? () => _save(context) : null,
              child: const Text('Save'),
            ),
    );
  }

  void _save(BuildContext context) {
    final editVm = context.read<EditNotationViewModel>();
    final sessionVm = context.read<CaptureSessionViewModel>();

    // Build the updated NotationPage list from the current session.
    // Each CapturePageDraft carries the mutated RenderParams; we match them
    // back to the original page ids via positional order (pages cannot be
    // added or removed in this flow — only their RenderParams change).
    final existingPages = editVm.existingPages;
    final sessionPages = sessionVm.pages;

    final updatedPages = <NotationPage>[];
    for (var i = 0; i < existingPages.length; i++) {
      final original = existingPages[i];
      final renderParams = i < sessionPages.length
          ? sessionPages[i].renderParams
          : RenderParams.identity;

      updatedPages.add(
        original.copyWith(
          renderParams: jsonEncode(renderParams.toJson()),
        ),
      );
    }

    editVm.save(updatedPages: updatedPages);
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

/// Scrollable form with all metadata fields, driven by [EditNotationViewModel].
class _EditFormBody extends StatelessWidget {
  const _EditFormBody({
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
    final vm = context.watch<EditNotationViewModel>();
    final fs = vm.formState;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxFormWidth),
        child: ListView(
          padding: _kFormPadding,
          children: [
            _EditTitleField(controller: titleController),
            const SizedBox(height: _kSectionGap),
            _EditArtistChipInput(
              artists: fs.artists,
              inputController: artistInputController,
            ),
            const SizedBox(height: _kSectionGap),
            _EditDateField(currentValue: fs.dateWritten),
            const SizedBox(height: _kSectionGap),
            _EditTextFormRow(
              label: 'Time signature',
              hint: 'e.g. 4/4, 6/8',
              controller: timeSigController,
              onChanged: vm.setTimeSig,
            ),
            const SizedBox(height: _kSectionGap),
            _EditTextFormRow(
              label: 'Key signature',
              hint: 'e.g. C major, Yaman',
              controller: keySigController,
              onChanged: vm.setKeySig,
            ),
            const SizedBox(height: _kSectionGap),
            _EditLanguageChips(selected: fs.languages),
            const SizedBox(height: _kSectionGap),
            if (tags.isNotEmpty) ...[
              _EditTagChips(tags: tags, selectedIds: fs.selectedTagIds),
              const SizedBox(height: _kSectionGap),
            ],
            if (instruments.isNotEmpty) ...[
              _EditInstrumentChips(
                instruments: instruments,
                selectedIds: fs.selectedInstrumentIds,
              ),
              const SizedBox(height: _kSectionGap),
            ],
            _EditNotesField(controller: notesController),
            const SizedBox(height: _kSectionGap),
            if (customFieldDefinitions.isNotEmpty)
              _EditCustomFieldsSection(definitions: customFieldDefinitions),
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

/// Required title text field wired to [EditNotationViewModel].
class _EditTitleField extends StatelessWidget {
  const _EditTitleField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
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
class _EditArtistChipInput extends StatelessWidget {
  const _EditArtistChipInput({
    required this.artists,
    required this.inputController,
  });

  final List<String> artists;
  final TextEditingController inputController;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Artist(s)', style: Theme.of(context).textTheme.labelLarge),
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
class _EditDateField extends StatelessWidget {
  const _EditDateField({required this.currentValue});

  final String? currentValue;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
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
    EditNotationViewModel vm,
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
class _EditTextFormRow extends StatelessWidget {
  const _EditTextFormRow({
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
class _EditLanguageChips extends StatelessWidget {
  const _EditLanguageChips({required this.selected});

  final List<String> selected;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Language', style: Theme.of(context).textTheme.labelLarge),
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
class _EditTagChips extends StatelessWidget {
  const _EditTagChips({required this.tags, required this.selectedIds});

  final List<Tag> tags;
  final List<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.labelLarge),
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
class _EditInstrumentChips extends StatelessWidget {
  const _EditInstrumentChips({
    required this.instruments,
    required this.selectedIds,
  });

  final List<InstrumentInstance> instruments;
  final List<String> selectedIds;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instruments', style: Theme.of(context).textTheme.labelLarge),
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
class _EditNotesField extends StatelessWidget {
  const _EditNotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<EditNotationViewModel>();
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
class _EditCustomFieldsSection extends StatelessWidget {
  const _EditCustomFieldsSection({required this.definitions});

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
            child: _EditCustomFieldInput(definition: def),
          ),
        ),
      ],
    );
  }
}

/// A single custom field input rendered by its type.
class _EditCustomFieldInput extends StatelessWidget {
  const _EditCustomFieldInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    return switch (definition.fieldType) {
      CustomFieldType.text => _EditCustomTextInput(definition: definition),
      CustomFieldType.number => _EditCustomNumberInput(definition: definition),
      CustomFieldType.date => _EditCustomDateInput(definition: definition),
      CustomFieldType.boolean =>
        _EditCustomBooleanInput(definition: definition),
    };
  }
}

class _EditCustomTextInput extends StatefulWidget {
  const _EditCustomTextInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  State<_EditCustomTextInput> createState() => _EditCustomTextInputState();
}

class _EditCustomTextInputState extends State<_EditCustomTextInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = context
            .read<EditNotationViewModel>()
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
    final vm = context.read<EditNotationViewModel>();
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

class _EditCustomNumberInput extends StatefulWidget {
  const _EditCustomNumberInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  State<_EditCustomNumberInput> createState() => _EditCustomNumberInputState();
}

class _EditCustomNumberInputState extends State<_EditCustomNumberInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final existing = context
        .read<EditNotationViewModel>()
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
    final vm = context.read<EditNotationViewModel>();
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

class _EditCustomDateInput extends StatelessWidget {
  const _EditCustomDateInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditNotationViewModel>();
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
    EditNotationViewModel vm,
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
    vm.setCustomFieldDate(
      definition.id,
      '${picked.year.toString().padLeft(4, '0')}-'
      '${picked.month.toString().padLeft(2, '0')}-'
      '${picked.day.toString().padLeft(2, '0')}',
    );
  }
}

class _EditCustomBooleanInput extends StatelessWidget {
  const _EditCustomBooleanInput({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditNotationViewModel>();
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
// No-op stubs for MetadataFormViewModel constructor requirements
// ---------------------------------------------------------------------------

/// No-op [NotationRepository] used solely to satisfy [MetadataFormViewModel]
/// constructor when the ViewModel is used only for dependency loading.
class _NoopNotationRepository implements NotationRepository {
  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) =>
      throw UnimplementedError();

  @override
  Future<NotationDetail?> loadNotation(String id) async => null;

  @override
  Stream<List<Notation>> watchAllActive() => const Stream.empty();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}
}

/// No-op [FileStorageService] used solely to satisfy [MetadataFormViewModel]
/// constructor when the ViewModel is used only for dependency loading.
class _NoopFileStorageService extends FileStorageService {}

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
