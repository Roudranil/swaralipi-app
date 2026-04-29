// MetadataFormViewModel — ChangeNotifier-based ViewModel for the Metadata
// Form screen.
//
// Holds all form state as an immutable [MetadataFormFormState] and exposes
// mutating methods that replace the state via copyWith. Subscribes to three
// repository streams (tags, all active instrument instances, custom field
// definitions) and combines them into a single [MetadataFormDepsState].
//
// Lifecycle:
//   Call [loadDependencies] once from the screen's initState /
//   didChangeDependencies. Dispose is handled by ChangeNotifier.
//
// Save flow:
//   1. Generate a notation UUID.
//   2. Iterate [_drafts]: call [FileStorageService.saveImage] for each page's
//      bytes, building a list of [SavedPage] DTOs with resolved relative paths.
//   3. If any file write fails, delete all files written so far (rollback),
//      then emit [MetadataFormSaveError].
//   4. On success: call [NotationRepository.saveNotation] in a single Drift
//      transaction. Emit [MetadataFormSaveDone].
//
// The ViewModel receives [List<CapturePageDraft>] (in-memory bytes) from the
// caller; [FileStorageService] is injected for disk I/O so both are testable.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/render_params.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

/// Shared [Uuid] instance used to generate notation and page UUIDs.
const _kUuid = Uuid();

// ---------------------------------------------------------------------------
// Custom field value input (local DTO for in-form state)
// ---------------------------------------------------------------------------

/// Holds an in-progress value for a single custom field during form editing.
///
/// Only the field matching the definition's [CustomFieldType] is populated.
final class CustomFieldEntry {
  /// Creates an immutable [CustomFieldEntry].
  ///
  /// Parameters:
  /// - [definitionId]: FK to the [CustomFieldDefinition].
  /// - [textValue]: Value for text-type fields; nullable.
  /// - [numberValue]: Value for number-type fields; nullable.
  /// - [dateValue]: ISO 8601 date for date-type fields; nullable.
  /// - [booleanValue]: Value for boolean-type fields; nullable.
  const CustomFieldEntry({
    required this.definitionId,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
  });

  /// FK to the [CustomFieldDefinition] row.
  final String definitionId;

  /// Text value; populated when the field type is `text`.
  final String? textValue;

  /// Numeric value; populated when the field type is `number`.
  final double? numberValue;

  /// ISO 8601 date; populated when the field type is `date`.
  final String? dateValue;

  /// Boolean value; populated when the field type is `boolean`.
  final bool? booleanValue;

  /// Returns a copy with the specified fields replaced.
  CustomFieldEntry copyWith({
    String? textValue,
    double? numberValue,
    String? dateValue,
    bool? booleanValue,
  }) =>
      CustomFieldEntry(
        definitionId: definitionId,
        textValue: textValue ?? this.textValue,
        numberValue: numberValue ?? this.numberValue,
        dateValue: dateValue ?? this.dateValue,
        booleanValue: booleanValue ?? this.booleanValue,
      );
}

// ---------------------------------------------------------------------------
// Form state
// ---------------------------------------------------------------------------

/// Immutable DTO holding all form field values for [MetadataFormViewModel].
///
/// Every mutation returns a new [MetadataFormFormState] via [copyWith].
final class MetadataFormFormState {
  /// Creates an immutable [MetadataFormFormState].
  ///
  /// All fields default to their empty/null equivalents.
  const MetadataFormFormState({
    this.title = '',
    this.artists = const [],
    this.dateWritten,
    this.timeSig,
    this.keySig,
    this.languages = const [],
    this.notes = '',
    this.selectedTagIds = const [],
    this.selectedInstrumentIds = const [],
    this.customFieldValues = const {},
  });

  /// Title of the notation; required (blocks save when empty).
  final String title;

  /// Ordered list of artist names.
  final List<String> artists;

  /// ISO 8601 date (YYYY-MM-DD) when the notation was written; nullable.
  final String? dateWritten;

  /// Time signature string, e.g. `'4/4'`; nullable.
  final String? timeSig;

  /// Key signature string, e.g. `'C major'`; nullable.
  final String? keySig;

  /// Selected language names, e.g. `['Hindi', 'Bengali']`.
  final List<String> languages;

  /// Free-form personal notes.
  final String notes;

  /// UUIDv4 ids of selected tags.
  final List<String> selectedTagIds;

  /// UUIDv4 ids of selected instrument instances.
  final List<String> selectedInstrumentIds;

  /// Custom field values keyed by definition id.
  final Map<String, CustomFieldEntry> customFieldValues;

  /// Returns a copy with the specified fields replaced.
  MetadataFormFormState copyWith({
    String? title,
    List<String>? artists,
    String? dateWritten,
    String? timeSig,
    String? keySig,
    List<String>? languages,
    String? notes,
    List<String>? selectedTagIds,
    List<String>? selectedInstrumentIds,
    Map<String, CustomFieldEntry>? customFieldValues,
  }) =>
      MetadataFormFormState(
        title: title ?? this.title,
        artists: artists ?? this.artists,
        dateWritten: dateWritten ?? this.dateWritten,
        timeSig: timeSig ?? this.timeSig,
        keySig: keySig ?? this.keySig,
        languages: languages ?? this.languages,
        notes: notes ?? this.notes,
        selectedTagIds: selectedTagIds ?? this.selectedTagIds,
        selectedInstrumentIds:
            selectedInstrumentIds ?? this.selectedInstrumentIds,
        customFieldValues: customFieldValues ?? this.customFieldValues,
      );
}

// ---------------------------------------------------------------------------
// Dependencies state
// ---------------------------------------------------------------------------

/// Sealed state tracking the loading status of picker dependencies.
///
/// Variants: [MetadataFormDepsIdle], [MetadataFormDepsLoading],
/// [MetadataFormDepsSuccess], [MetadataFormDepsError].
sealed class MetadataFormDepsState {
  /// Creates a [MetadataFormDepsState].
  const MetadataFormDepsState();
}

/// Initial state before [MetadataFormViewModel.loadDependencies] is called.
final class MetadataFormDepsIdle extends MetadataFormDepsState {
  /// Creates a [MetadataFormDepsIdle].
  const MetadataFormDepsIdle();
}

/// State while waiting for all three streams to emit at least once.
final class MetadataFormDepsLoading extends MetadataFormDepsState {
  /// Creates a [MetadataFormDepsLoading].
  const MetadataFormDepsLoading();
}

/// State when tags, instruments, and custom field definitions are all loaded.
final class MetadataFormDepsSuccess extends MetadataFormDepsState {
  /// Creates a [MetadataFormDepsSuccess].
  ///
  /// Parameters:
  /// - [tags]: All user-defined tags.
  /// - [instruments]: All active instrument instances.
  /// - [customFieldDefinitions]: All custom field definitions.
  const MetadataFormDepsSuccess({
    required this.tags,
    required this.instruments,
    required this.customFieldDefinitions,
  });

  /// All user-defined tags.
  final List<Tag> tags;

  /// All active instrument instances.
  final List<InstrumentInstance> instruments;

  /// All custom field definitions.
  final List<CustomFieldDefinition> customFieldDefinitions;
}

/// State when one of the streams emits an error.
final class MetadataFormDepsError extends MetadataFormDepsState {
  /// Creates a [MetadataFormDepsError].
  ///
  /// Parameters:
  /// - [message]: Human-readable error description.
  const MetadataFormDepsError({required this.message});

  /// Human-readable error description.
  final String message;
}

// ---------------------------------------------------------------------------
// Save state
// ---------------------------------------------------------------------------

/// Sealed state tracking the notation save operation.
///
/// Variants: [MetadataFormSaveIdle], [MetadataFormSaving],
/// [MetadataFormSaveDone], [MetadataFormSaveError].
sealed class MetadataFormSaveState {
  /// Creates a [MetadataFormSaveState].
  const MetadataFormSaveState();
}

/// Initial state; no save has been attempted.
final class MetadataFormSaveIdle extends MetadataFormSaveState {
  /// Creates a [MetadataFormSaveIdle].
  const MetadataFormSaveIdle();
}

/// A save operation is in progress.
final class MetadataFormSaving extends MetadataFormSaveState {
  /// Creates a [MetadataFormSaving].
  const MetadataFormSaving();
}

/// The notation was saved successfully.
final class MetadataFormSaveDone extends MetadataFormSaveState {
  /// Creates a [MetadataFormSaveDone].
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 of the newly persisted notation.
  const MetadataFormSaveDone({required this.notationId});

  /// UUIDv4 of the newly created notation.
  final String notationId;
}

/// The save operation failed.
final class MetadataFormSaveError extends MetadataFormSaveState {
  /// Creates a [MetadataFormSaveError].
  ///
  /// Parameters:
  /// - [message]: Human-readable error description.
  const MetadataFormSaveError({required this.message});

  /// Human-readable error description.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// Predefined language options shown as multi-select chips in the form.
const List<String> kMetadataFormLanguages = [
  'Hindi',
  'Bengali',
  'English',
  'Sanskrit',
  'Other',
];

/// ViewModel for the metadata form screen.
///
/// Manages form state, picker dependencies, and the save operation.
/// Extends [ChangeNotifier] for compatibility with the [provider] package.
///
/// On [save], iterates [drafts] to write each page's bytes to disk via
/// [FileStorageService], then persists the notation record in a single Drift
/// transaction via [NotationRepository]. If any file write fails, all
/// previously written files are deleted before propagating the error.
///
/// Dependencies are injected via constructor; no [BuildContext] references.
class MetadataFormViewModel extends ChangeNotifier {
  /// Creates a [MetadataFormViewModel].
  ///
  /// Parameters:
  /// - [tagRepository]: Source of truth for tags.
  /// - [instrumentRepository]: Source of truth for instruments.
  /// - [customFieldRepository]: Source of truth for custom field definitions.
  /// - [notationRepository]: Persists the final notation record.
  /// - [fileStorageService]: Writes page images to disk before the DB save.
  /// - [drafts]: Ordered list of in-memory [CapturePageDraft] objects from
  ///   the capture session. The ViewModel writes their bytes to disk during
  ///   [save].
  /// - [allInstancesStream]: Optional override stream of all active instrument
  ///   instances. If provided, the ViewModel subscribes to this stream instead
  ///   of deriving one from [InstrumentRepository.watchActiveClasses]. Used in
  ///   tests to avoid the real repository's class-per-stream combination logic.
  MetadataFormViewModel({
    required TagRepository tagRepository,
    required InstrumentRepository instrumentRepository,
    required CustomFieldRepository customFieldRepository,
    required NotationRepository notationRepository,
    required FileStorageService fileStorageService,
    required List<CapturePageDraft> drafts,
    Stream<List<InstrumentInstance>>? allInstancesStream,
  })  : _tagRepository = tagRepository,
        _instrumentRepository = instrumentRepository,
        _customFieldRepository = customFieldRepository,
        _notationRepository = notationRepository,
        _fileStorageService = fileStorageService,
        _drafts = List.unmodifiable(drafts),
        _allInstancesStreamOverride = allInstancesStream;

  final TagRepository _tagRepository;
  final InstrumentRepository _instrumentRepository;
  final CustomFieldRepository _customFieldRepository;
  final NotationRepository _notationRepository;
  final FileStorageService _fileStorageService;
  final List<CapturePageDraft> _drafts;
  final Stream<List<InstrumentInstance>>? _allInstancesStreamOverride;

  // Stream subscriptions
  StreamSubscription<List<Tag>>? _tagSub;
  StreamSubscription<List<InstrumentInstance>>? _instrumentSub;
  StreamSubscription<List<CustomFieldDefinition>>? _cfSub;

  // Partial stream data (waiting for all three before transitioning to success)
  List<Tag>? _latestTags;
  List<InstrumentInstance>? _latestInstruments;
  List<CustomFieldDefinition>? _latestDefs;

  MetadataFormFormState _formState = const MetadataFormFormState();
  MetadataFormDepsState _depsState = const MetadataFormDepsIdle();
  MetadataFormSaveState _saveState = const MetadataFormSaveIdle();

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current form field values.
  MetadataFormFormState get formState => _formState;

  /// The current state of dependency loading (tags, instruments, custom fields).
  MetadataFormDepsState get depsState => _depsState;

  /// The current state of the save operation.
  MetadataFormSaveState get saveState => _saveState;

  /// Whether the title field contains a non-empty, non-whitespace string.
  bool get isTitleValid => _formState.title.trim().isNotEmpty;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the tag, instrument, and custom field streams.
  ///
  /// Transitions immediately to [MetadataFormDepsLoading]. Once all three
  /// streams have emitted at least once, transitions to
  /// [MetadataFormDepsSuccess]. If any stream emits an error, transitions to
  /// [MetadataFormDepsError].
  ///
  /// Calling [loadDependencies] again cancels prior subscriptions.
  void loadDependencies() {
    _tagSub?.cancel();
    _instrumentSub?.cancel();
    _cfSub?.cancel();

    _latestTags = null;
    _latestInstruments = null;
    _latestDefs = null;

    _depsState = const MetadataFormDepsLoading();
    notifyListeners();

    _tagSub = _tagRepository.watchAllTags().listen(
      (tags) {
        _latestTags = tags;
        _tryUpdateDepsSuccess();
      },
      onError: (Object e, StackTrace st) => _onDepsError(e, st),
    );

    _instrumentSub = _allActiveInstruments().listen(
      (instances) {
        _latestInstruments = instances;
        _tryUpdateDepsSuccess();
      },
      onError: (Object e, StackTrace st) => _onDepsError(e, st),
    );

    _cfSub = _customFieldRepository.watchAllDefinitions().listen(
      (defs) {
        _latestDefs = defs;
        _tryUpdateDepsSuccess();
      },
      onError: (Object e, StackTrace st) => _onDepsError(e, st),
    );
  }

  /// Returns a stream of all active instrument instances regardless of class.
  ///
  /// When [_allInstancesStreamOverride] is set (e.g. in tests), that stream
  /// is used directly. Otherwise the ViewModel combines
  /// [InstrumentRepository.watchActiveClasses] with per-class instance streams.
  Stream<List<InstrumentInstance>> _allActiveInstruments() {
    return _allInstancesStreamOverride ?? _watchAllActiveInstancesCombined();
  }

  /// Combines [InstrumentRepository.watchActiveClasses] with per-class
  /// instance streams to produce a merged stream of all active instances.
  Stream<List<InstrumentInstance>> _watchAllActiveInstancesCombined() {
    // Outer stream that maps each class list into a list of per-class streams
    // and flattens them.
    return _instrumentRepository.watchActiveClasses().asyncExpand((classes) {
      if (classes.isEmpty) return Stream.value(<InstrumentInstance>[]);

      final streams = classes
          .map(
            (c) => _instrumentRepository.watchActiveInstancesForClass(c.id),
          )
          .toList();

      // Combine all per-class streams into a single merged list
      return _combineStreams(streams);
    });
  }

  /// Merges a list of streams of lists into a single stream that emits the
  /// concatenation of the latest value from each stream.
  Stream<List<InstrumentInstance>> _combineStreams(
    List<Stream<List<InstrumentInstance>>> streams,
  ) {
    if (streams.isEmpty) return Stream.value(<InstrumentInstance>[]);

    final latestValues =
        List<List<InstrumentInstance>?>.filled(streams.length, null);
    int emittedCount = 0;
    late StreamController<List<InstrumentInstance>> controller;

    controller = StreamController<List<InstrumentInstance>>.broadcast(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          final index = i;
          streams[index].listen(
            (values) {
              if (latestValues[index] == null) emittedCount++;
              latestValues[index] = values;
              if (emittedCount == streams.length) {
                controller.add(
                  latestValues
                      .expand((list) => list ?? <InstrumentInstance>[])
                      .toList(),
                );
              }
            },
            onError: controller.addError,
          );
        }
      },
    );

    return controller.stream;
  }

  void _tryUpdateDepsSuccess() {
    final tags = _latestTags;
    final instruments = _latestInstruments;
    final defs = _latestDefs;

    if (tags == null || instruments == null || defs == null) return;

    _depsState = MetadataFormDepsSuccess(
      tags: tags,
      instruments: instruments,
      customFieldDefinitions: defs,
    );
    notifyListeners();
  }

  void _onDepsError(Object error, StackTrace stack) {
    log(
      'MetadataFormViewModel: deps stream error — $error',
      name: 'MetadataFormViewModel',
      error: error,
      stackTrace: stack,
    );
    _depsState = MetadataFormDepsError(message: error.toString());
    notifyListeners();
  }

  @override
  void dispose() {
    _tagSub?.cancel();
    _instrumentSub?.cancel();
    _cfSub?.cancel();
    super.dispose();
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

  // -------------------------------------------------------------------------
  // Artists chip management
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Language management
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Tag selection
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Instrument selection
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Custom field value setters
  // -------------------------------------------------------------------------

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

  /// Saves the notation to disk and to the database.
  ///
  /// No-op if [isTitleValid] is false or a save is already in progress.
  ///
  /// The save pipeline:
  /// 1. Generates a UUIDv4 for the notation.
  /// 2. Iterates [_drafts]: calls [FileStorageService.saveImage] for each
  ///    page's bytes to write JPEG files under
  ///    `appDocDir/notations/<notationId>/page_<n>_original.jpg`.
  /// 3. If any write fails, all previously written files are deleted
  ///    (rollback) and [saveState] transitions to [MetadataFormSaveError].
  /// 4. On success: calls [NotationRepository.saveNotation] in a single
  ///    Drift transaction, then transitions to [MetadataFormSaveDone].
  Future<void> save() async {
    if (!isTitleValid) return;
    if (_saveState is MetadataFormSaving) return;

    _saveState = const MetadataFormSaving();
    notifyListeners();

    final notationId = _kUuid.v4();

    try {
      final savedPages = await _writePagesToStorage(notationId);
      final draft = _buildDraft();
      final notation = await _notationRepository.saveNotation(
        draft,
        savedPages,
        notationId: notationId,
      );

      log(
        'MetadataFormViewModel: saved notation "${notation.id}" '
        'with ${savedPages.length} page(s)',
        name: 'MetadataFormViewModel',
      );

      _saveState = MetadataFormSaveDone(notationId: notation.id);
    } on Exception catch (e, st) {
      log(
        'MetadataFormViewModel: save failed — $e',
        name: 'MetadataFormViewModel',
        error: e,
        stackTrace: st,
      );
      _saveState = MetadataFormSaveError(message: e.toString());
    }
    notifyListeners();
  }

  /// Writes each draft's bytes to the file system and returns the
  /// resulting [SavedPage] list.
  ///
  /// Iterates [_drafts] in order. Each page is saved to
  /// `notations/<notationId>/page_<index>_original.jpg` via
  /// [FileStorageService.saveImage]. If any write throws, every file written
  /// so far is deleted and the exception is re-thrown so [save] can emit an
  /// error state.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 used as the notation directory name.
  Future<List<SavedPage>> _writePagesToStorage(String notationId) async {
    final writtenPaths = <String>[];
    final savedPages = <SavedPage>[];

    try {
      for (var i = 0; i < _drafts.length; i++) {
        final draft = _drafts[i];
        final relativePath = await _fileStorageService.saveImage(
          draft.originalBytes,
          notationId,
          i,
        );
        writtenPaths.add(relativePath);
        savedPages.add(
          SavedPage(
            id: _kUuid.v4(),
            pageOrder: i,
            imagePath: relativePath,
            renderParams: _encodeRenderParams(draft.renderParams),
          ),
        );
      }
    } on Exception catch (e, st) {
      log(
        'MetadataFormViewModel: file write failed, rolling back '
        '${writtenPaths.length} file(s) — $e',
        name: 'MetadataFormViewModel',
        error: e,
        stackTrace: st,
      );
      await _rollbackFiles(writtenPaths);
      rethrow;
    }

    return savedPages;
  }

  /// Deletes all files in [relativePaths] to clean up a failed save.
  ///
  /// Errors during deletion are logged but not re-thrown so the original
  /// save error is not masked.
  ///
  /// Parameters:
  /// - [relativePaths]: Relative paths returned by [FileStorageService.saveImage].
  Future<void> _rollbackFiles(List<String> relativePaths) async {
    for (final path in relativePaths) {
      try {
        await _fileStorageService.deletePageFile(path);
      } on Exception catch (e, st) {
        log(
          'MetadataFormViewModel: rollback delete failed for "$path": $e',
          name: 'MetadataFormViewModel',
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  /// Serialises [params] to a JSON string for storage in
  /// [NotationPagesTable.renderParams].
  ///
  /// Parameters:
  /// - [params]: The [RenderParams] to encode.
  String _encodeRenderParams(RenderParams params) {
    return jsonEncode(params.toJson());
  }

  /// Resets [saveState] to [MetadataFormSaveIdle] after an error has been
  /// surfaced to the user.
  ///
  /// Call this after displaying the error to prevent the same error from
  /// being shown again on rebuild.
  void clearSaveError() {
    if (_saveState is MetadataFormSaveError) {
      _saveState = const MetadataFormSaveIdle();
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
