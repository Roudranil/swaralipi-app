// edit_notation_view_model.dart — ChangeNotifier ViewModel for editing an
// existing notation.
//
// Orchestrates the two-step edit flow:
//   1. [loadNotation] fetches the existing [NotationDetail] from the repository
//      and pre-populates [formState] with its metadata and [existingPages] with
//      its pages.
//   2. [save] assembles a [NotationDraft] from the mutated [formState] and
//      calls [NotationRepository.updateNotation], persisting only metadata changes.
//      Page render-param changes are persisted via the [updatedPages] list
//      which maps to the [NotationPage.renderParams] column.
//
// Architecture note:
//   View → EditNotationViewModel → NotationRepository
//
// The ViewModel is intentionally separate from [MetadataFormViewModel] so that
// the edit flow can share the same [MetadataFormScreen] and [PageEditorScreen]
// widgets without adding edit-mode coupling to the capture flow.
//
// Lifecycle:
//   Call [loadNotation] once from the screen's initState /
//   didChangeDependencies. Dispose is handled by ChangeNotifier.

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/capture/viewmodels/metadata_form_view_model.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Load state
// ---------------------------------------------------------------------------

/// Sealed state for the notation-loading phase of the edit flow.
///
/// Variants: [EditNotationStateIdle], [EditNotationStateLoading],
/// [EditNotationStateSuccess], [EditNotationStateNotFound],
/// [EditNotationStateError].
sealed class EditNotationState {
  /// Creates an [EditNotationState].
  const EditNotationState();
}

/// Initial state before [EditNotationViewModel.loadNotation] is called.
final class EditNotationStateIdle extends EditNotationState {
  /// Creates an [EditNotationStateIdle].
  const EditNotationStateIdle();
}

/// State while the notation is being fetched from the repository.
final class EditNotationStateLoading extends EditNotationState {
  /// Creates an [EditNotationStateLoading].
  const EditNotationStateLoading();
}

/// State when the notation was loaded and pre-population is complete.
final class EditNotationStateSuccess extends EditNotationState {
  /// Creates an [EditNotationStateSuccess].
  ///
  /// Parameters:
  /// - [notationId]: UUIDv4 of the loaded notation.
  const EditNotationStateSuccess({required this.notationId});

  /// UUIDv4 of the loaded notation.
  final String notationId;
}

/// State when the notation id does not exist in the repository.
final class EditNotationStateNotFound extends EditNotationState {
  /// Creates an [EditNotationStateNotFound].
  const EditNotationStateNotFound();
}

/// State when loading fails with an exception.
final class EditNotationStateError extends EditNotationState {
  /// Creates an [EditNotationStateError].
  ///
  /// Parameters:
  /// - [message]: Human-readable error description.
  const EditNotationStateError({required this.message});

  /// Human-readable error description.
  final String message;
}

// ---------------------------------------------------------------------------
// Save state
// ---------------------------------------------------------------------------

/// Sealed state for the notation-save phase of the edit flow.
///
/// Variants: [EditNotationSaveIdle], [EditNotationSaving],
/// [EditNotationSaveDone], [EditNotationSaveError].
sealed class EditNotationSaveState {
  /// Creates an [EditNotationSaveState].
  const EditNotationSaveState();
}

/// Initial state; no save has been attempted.
final class EditNotationSaveIdle extends EditNotationSaveState {
  /// Creates an [EditNotationSaveIdle].
  const EditNotationSaveIdle();
}

/// A save operation is in progress.
final class EditNotationSaving extends EditNotationSaveState {
  /// Creates an [EditNotationSaving].
  const EditNotationSaving();
}

/// The notation was updated successfully.
final class EditNotationSaveDone extends EditNotationSaveState {
  /// Creates an [EditNotationSaveDone].
  ///
  /// Parameters:
  /// - [notationId]: UUIDv4 of the updated notation.
  const EditNotationSaveDone({required this.notationId});

  /// UUIDv4 of the updated notation.
  final String notationId;
}

/// The save operation failed.
final class EditNotationSaveError extends EditNotationSaveState {
  /// Creates an [EditNotationSaveError].
  ///
  /// Parameters:
  /// - [message]: Human-readable error description.
  const EditNotationSaveError({required this.message});

  /// Human-readable error description.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ChangeNotifier ViewModel that manages loading and saving an existing
/// notation in the edit flow.
///
/// On [loadNotation], fetches the [NotationDetail] and pre-populates
/// [formState] and [existingPages] so the edit screens show current values.
///
/// On [save], assembles a [NotationDraft] from [formState] and calls
/// [NotationRepository.updateNotation].  Page-level [RenderParams] changes
/// arrive via the [updatedPages] parameter and are persisted separately
/// through the repository's page-replace mechanism (not implemented here —
/// the caller is responsible for passing pages that already have updated
/// [NotationPage.renderParams] values; this ViewModel stores them in
/// [existingPages] so the page editor screen can read them).
///
/// Dependencies are injected via constructor; no [BuildContext] references.
class EditNotationViewModel extends ChangeNotifier {
  /// Creates an [EditNotationViewModel].
  ///
  /// Parameters:
  /// - [notationRepository]: Used to load and update the notation.
  EditNotationViewModel({required NotationRepository notationRepository})
      : _notationRepository = notationRepository;

  final NotationRepository _notationRepository;

  EditNotationState _state = const EditNotationStateIdle();
  EditNotationSaveState _saveState = const EditNotationSaveIdle();
  MetadataFormFormState _formState = const MetadataFormFormState();
  List<NotationPage> _existingPages = const [];
  String? _notationId;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current load state.
  EditNotationState get state => _state;

  /// The current save state.
  EditNotationSaveState get saveState => _saveState;

  /// The current form field values, pre-populated after [loadNotation].
  MetadataFormFormState get formState => _formState;

  /// The pages belonging to the loaded notation, pre-populated after
  /// [loadNotation].
  ///
  /// Returns an unmodifiable view. Callers hand these to [PageEditorScreen]
  /// as the initial page set for the edit session.
  List<NotationPage> get existingPages => List.unmodifiable(_existingPages);

  /// Whether the title field contains a non-empty, non-whitespace string.
  bool get isTitleValid => _formState.title.trim().isNotEmpty;

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------

  /// Loads the notation with [id] and pre-populates [formState] and
  /// [existingPages].
  ///
  /// Transitions:
  ///   [EditNotationStateIdle] → [EditNotationStateLoading] →
  ///   [EditNotationStateSuccess] (found) |
  ///   [EditNotationStateNotFound] (null return) |
  ///   [EditNotationStateError] (exception)
  ///
  /// Calling [loadNotation] again resets all state.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to load.
  Future<void> loadNotation(String id) async {
    _state = const EditNotationStateLoading();
    _formState = const MetadataFormFormState();
    _existingPages = const [];
    _notationId = null;
    notifyListeners();

    try {
      final detail = await _notationRepository.loadNotation(id);
      if (detail == null) {
        _state = const EditNotationStateNotFound();
        notifyListeners();
        return;
      }

      _notationId = detail.notation.id;
      _formState = _buildFormState(detail);
      _existingPages = List.unmodifiable(detail.pages);
      _state = EditNotationStateSuccess(notationId: detail.notation.id);

      log(
        'EditNotationViewModel: loaded notation "${detail.notation.id}"',
        name: 'EditNotationViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'EditNotationViewModel: loadNotation failed — $e',
        name: 'EditNotationViewModel',
        error: e,
        stackTrace: st,
      );
      _state = EditNotationStateError(message: e.toString());
    }

    notifyListeners();
  }

  /// Builds a pre-populated [MetadataFormFormState] from [detail].
  MetadataFormFormState _buildFormState(NotationDetail detail) {
    final notation = detail.notation;

    final tagIds = detail.tags.map((t) => t.id).toList();

    final customFields = <String, CustomFieldEntry>{};
    for (final cfv in detail.customFieldValues) {
      customFields[cfv.definitionId] = CustomFieldEntry(
        definitionId: cfv.definitionId,
        textValue: cfv.valueText,
        numberValue: cfv.valueNumber,
        dateValue: cfv.valueDate,
        booleanValue: cfv.valueBoolean,
      );
    }

    return MetadataFormFormState(
      title: notation.title,
      artists: List<String>.from(notation.artists),
      dateWritten: notation.dateWritten,
      timeSig: notation.timeSig,
      keySig: notation.keySig,
      languages: List<String>.from(notation.languages),
      notes: notation.notes,
      selectedTagIds: tagIds,
      customFieldValues: customFields,
    );
  }

  // -------------------------------------------------------------------------
  // Form field setters
  // -------------------------------------------------------------------------

  /// Updates the title field.
  ///
  /// Parameters:
  /// - [value]: The new title string.
  void setTitle(String value) {
    _formState = _formState.copyWith(title: value);
    notifyListeners();
  }

  /// Updates the date written field.
  ///
  /// Parameters:
  /// - [value]: ISO 8601 date string (YYYY-MM-DD).
  void setDateWritten(String value) {
    _formState = _formState.copyWith(dateWritten: value);
    notifyListeners();
  }

  /// Updates the time signature field.
  ///
  /// Parameters:
  /// - [value]: Time signature string, e.g. `'4/4'`.
  void setTimeSig(String value) {
    _formState = _formState.copyWith(timeSig: value);
    notifyListeners();
  }

  /// Updates the key signature field.
  ///
  /// Parameters:
  /// - [value]: Key signature string, e.g. `'C major'`.
  void setKeySig(String value) {
    _formState = _formState.copyWith(keySig: value);
    notifyListeners();
  }

  /// Updates the personal notes field.
  ///
  /// Parameters:
  /// - [value]: Free-form text.
  void setNotes(String value) {
    _formState = _formState.copyWith(notes: value);
    notifyListeners();
  }

  /// Appends a trimmed artist name to the artists list.
  ///
  /// Blank (whitespace-only) values are ignored.
  ///
  /// Parameters:
  /// - [name]: Artist name to add.
  void addArtist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    _formState = _formState.copyWith(
      artists: [..._formState.artists, trimmed],
    );
    notifyListeners();
  }

  /// Removes the artist at [index] from the list.
  ///
  /// Parameters:
  /// - [index]: 0-based position of the artist to remove.
  void removeArtist(int index) {
    final updated = List<String>.from(_formState.artists)..removeAt(index);
    _formState = _formState.copyWith(artists: updated);
    notifyListeners();
  }

  /// Toggles [language] in the selected languages list.
  ///
  /// Adds [language] if not present; removes it if already selected.
  ///
  /// Parameters:
  /// - [language]: Language name, e.g. `'Hindi'`.
  void toggleLanguage(String language) {
    final current = List<String>.from(_formState.languages);
    if (current.contains(language)) {
      current.remove(language);
    } else {
      current.add(language);
    }
    _formState = _formState.copyWith(languages: current);
    notifyListeners();
  }

  /// Toggles [id] in the selected tag ids list.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the tag to toggle.
  void toggleTag(String id) {
    final current = List<String>.from(_formState.selectedTagIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _formState = _formState.copyWith(selectedTagIds: current);
    notifyListeners();
  }

  /// Toggles [id] in the selected instrument ids list.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the instrument instance to toggle.
  void toggleInstrument(String id) {
    final current = List<String>.from(_formState.selectedInstrumentIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _formState = _formState.copyWith(selectedInstrumentIds: current);
    notifyListeners();
  }

  /// Sets a text value for the custom field identified by [definitionId].
  ///
  /// Parameters:
  /// - [definitionId]: UUIDv4 of the custom field definition.
  /// - [value]: Text value to store.
  void setCustomFieldText(String definitionId, String value) {
    _updateCustomField(
      definitionId,
      (e) => e.copyWith(textValue: value),
      defaultEntry: CustomFieldEntry(
        definitionId: definitionId,
        textValue: value,
      ),
    );
  }

  /// Sets a numeric value for the custom field identified by [definitionId].
  ///
  /// Parameters:
  /// - [definitionId]: UUIDv4 of the custom field definition.
  /// - [value]: Numeric value to store.
  void setCustomFieldNumber(String definitionId, double value) {
    _updateCustomField(
      definitionId,
      (e) => e.copyWith(numberValue: value),
      defaultEntry: CustomFieldEntry(
        definitionId: definitionId,
        numberValue: value,
      ),
    );
  }

  /// Sets a date value for the custom field identified by [definitionId].
  ///
  /// Parameters:
  /// - [definitionId]: UUIDv4 of the custom field definition.
  /// - [value]: ISO 8601 date string (YYYY-MM-DD).
  void setCustomFieldDate(String definitionId, String value) {
    _updateCustomField(
      definitionId,
      (e) => e.copyWith(dateValue: value),
      defaultEntry: CustomFieldEntry(
        definitionId: definitionId,
        dateValue: value,
      ),
    );
  }

  /// Sets a boolean value for the custom field identified by [definitionId].
  ///
  /// Parameters:
  /// - [definitionId]: UUIDv4 of the custom field definition.
  /// - [value]: Boolean value to store.
  void setCustomFieldBoolean(String definitionId, {required bool value}) {
    _updateCustomField(
      definitionId,
      (e) => e.copyWith(booleanValue: value),
      defaultEntry: CustomFieldEntry(
        definitionId: definitionId,
        booleanValue: value,
      ),
    );
  }

  void _updateCustomField(
    String definitionId,
    CustomFieldEntry Function(CustomFieldEntry) update, {
    required CustomFieldEntry defaultEntry,
  }) {
    final current = Map<String, CustomFieldEntry>.from(
      _formState.customFieldValues,
    );
    final existing = current[definitionId];
    current[definitionId] = existing != null ? update(existing) : defaultEntry;
    _formState = _formState.copyWith(customFieldValues: current);
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Save
  // -------------------------------------------------------------------------

  /// Updates the notation in the repository with the current [formState].
  ///
  /// No-op if [isTitleValid] is false or a save is already in progress.
  ///
  /// The [updatedPages] parameter carries the final ordered list of
  /// [NotationPage] objects (with potentially mutated [renderParams]) that
  /// the page editor produced. This ViewModel stores them in [existingPages]
  /// after a successful save so the caller can navigate with up-to-date data.
  ///
  /// On success, transitions to [EditNotationSaveDone] carrying the
  /// [notationId]. On failure, transitions to [EditNotationSaveError].
  ///
  /// Parameters:
  /// - [updatedPages]: Final ordered list of [NotationPage] objects from the
  ///   page editor session.
  Future<void> save({required List<NotationPage> updatedPages}) async {
    if (!isTitleValid) return;
    if (_saveState is EditNotationSaving) return;

    final id = _notationId;
    if (id == null) return;

    _saveState = const EditNotationSaving();
    notifyListeners();

    try {
      final draft = _buildDraft();
      final updated =
          await _notationRepository.updateNotation(id, draft);

      // Persist any render-param changes for each page in the updated list.
      for (final page in updatedPages) {
        await _notationRepository.updatePageRenderParams(
          page.id,
          page.renderParams,
        );
      }

      if (updatedPages.isNotEmpty) {
        _existingPages = List.unmodifiable(updatedPages);
      }

      log(
        'EditNotationViewModel: updated notation "${updated.id}"',
        name: 'EditNotationViewModel',
      );

      _saveState = EditNotationSaveDone(notationId: updated.id);
    } on Exception catch (e, st) {
      log(
        'EditNotationViewModel: save failed — $e',
        name: 'EditNotationViewModel',
        error: e,
        stackTrace: st,
      );
      _saveState = EditNotationSaveError(message: e.toString());
    }

    notifyListeners();
  }

  /// Resets [saveState] to [EditNotationSaveIdle] after an error has been
  /// surfaced to the user.
  ///
  /// Call this after displaying the error to prevent the same error from
  /// being shown again on rebuild.
  void clearSaveError() {
    if (_saveState is EditNotationSaveError) {
      _saveState = const EditNotationSaveIdle();
      notifyListeners();
    }
  }

  NotationDraft _buildDraft() {
    final fs = _formState;
    final customFields = fs.customFieldValues.entries
        .map(
          (entry) => CustomFieldValueInput(
            definitionId: entry.key,
            fieldType: _fieldTypeForEntry(entry.value),
            textValue: entry.value.textValue,
            numberValue: entry.value.numberValue,
            dateValue: entry.value.dateValue,
            booleanValue: entry.value.booleanValue,
          ),
        )
        .toList();

    return NotationDraft(
      title: fs.title.trim(),
      artists: fs.artists,
      dateWritten: fs.dateWritten,
      timeSig: fs.timeSig,
      keySig: fs.keySig,
      languages: fs.languages,
      notes: fs.notes,
      tagIds: fs.selectedTagIds,
      customFields: customFields,
    );
  }

  String _fieldTypeForEntry(CustomFieldEntry entry) {
    if (entry.textValue != null) return 'text';
    if (entry.numberValue != null) return 'number';
    if (entry.dateValue != null) return 'date';
    return 'boolean';
  }
}
