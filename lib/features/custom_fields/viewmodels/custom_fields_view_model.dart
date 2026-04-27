// CustomFieldsViewModel — ChangeNotifier-based ViewModel for the Custom Fields
// feature.
//
// Subscribes to [CustomFieldRepository.watchAllDefinitions] and exposes state
// as a sealed [CustomFieldsState] hierarchy: idle / loading / success / error.
//
// Separate per-operation error fields (createError, updateError, deleteError)
// allow the UI to surface operation-specific error feedback without replacing
// the entire list state.
//
// Construction:
//   CustomFieldsViewModel(customFieldRepository)
//
// Lifecycle:
//   Call [init] once from the screen's initState / didChangeDependencies.
//   Dispose is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for the [CustomFieldsViewModel].
///
/// Variants: [CustomFieldsStateIdle], [CustomFieldsStateLoading],
/// [CustomFieldsStateSuccess], [CustomFieldsStateError].
sealed class CustomFieldsState {
  /// Creates a [CustomFieldsState].
  const CustomFieldsState();
}

/// Initial state before [CustomFieldsViewModel.init] is called.
final class CustomFieldsStateIdle extends CustomFieldsState {
  /// Creates a [CustomFieldsStateIdle].
  const CustomFieldsStateIdle();
}

/// State while awaiting the first stream emission.
final class CustomFieldsStateLoading extends CustomFieldsState {
  /// Creates a [CustomFieldsStateLoading].
  const CustomFieldsStateLoading();
}

/// State when the definition list has been successfully received from the
/// stream.
final class CustomFieldsStateSuccess extends CustomFieldsState {
  /// Creates a [CustomFieldsStateSuccess] with the given [definitions].
  ///
  /// Parameters:
  /// - [definitions]: The current list of all user-defined custom field
  ///   definitions.
  const CustomFieldsStateSuccess({required this.definitions});

  /// The current list of all custom field definitions, ordered alphabetically.
  final List<CustomFieldDefinition> definitions;
}

/// State when the stream emitted an error.
final class CustomFieldsStateError extends CustomFieldsState {
  /// Creates a [CustomFieldsStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const CustomFieldsStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Custom Fields management screen.
///
/// Observes [CustomFieldRepository.watchAllDefinitions] and translates stream
/// events into [CustomFieldsState] values. Exposes CRUD operations that
/// delegate to the repository and surface per-operation errors via dedicated
/// nullable fields.
///
/// State management contract:
/// - [state] is the primary display state (idle / loading / success / error).
/// - [createError], [updateError], [deleteError] are auxiliary error fields;
///   they do not affect [state] so the definition list remains visible while
///   an operation-specific error is surfaced.
class CustomFieldsViewModel extends ChangeNotifier {
  /// Creates a [CustomFieldsViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for all custom field data operations.
  CustomFieldsViewModel(this._repository);

  final CustomFieldRepository _repository;
  StreamSubscription<List<CustomFieldDefinition>>? _subscription;

  CustomFieldsState _state = const CustomFieldsStateIdle();
  String? _createError;
  String? _updateError;
  String? _deleteError;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the custom fields screen.
  CustomFieldsState get state => _state;

  /// Non-null when the most recent [createDefinition] call failed.
  ///
  /// Clear with [clearCreateError] after the error has been surfaced.
  String? get createError => _createError;

  /// Non-null when the most recent [updateDefinition] call failed.
  ///
  /// Clear with [clearUpdateError] after the error has been surfaced.
  String? get updateError => _updateError;

  /// Non-null when the most recent [deleteDefinition] call failed.
  ///
  /// Clear with [clearDeleteError] after the error has been surfaced.
  String? get deleteError => _deleteError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the definitions stream and begins emitting state updates.
  ///
  /// Transitions immediately to [CustomFieldsStateLoading], then to
  /// [CustomFieldsStateSuccess] or [CustomFieldsStateError] as the stream
  /// emits. Calling [init] again cancels the previous subscription before
  /// restarting.
  void init() {
    _subscription?.cancel();
    _state = const CustomFieldsStateLoading();
    notifyListeners();

    _subscription = _repository.watchAllDefinitions().listen(
      (defs) {
        _state = CustomFieldsStateSuccess(definitions: defs);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'CustomFieldsViewModel: stream error — $error',
          name: 'CustomFieldsViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = CustomFieldsStateError(message: error.toString());
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // CRUD operations
  // -------------------------------------------------------------------------

  /// Creates a new custom field definition with [keyName] and [fieldType].
  ///
  /// Returns the persisted [CustomFieldDefinition] on success, or `null` on
  /// failure. On failure [createError] is populated and [notifyListeners] is
  /// called.
  ///
  /// Parameters:
  /// - [keyName]: Unique machine-readable key, e.g. `'raga_name'`.
  /// - [fieldType]: One of `'text'`, `'number'`, `'date'`, `'boolean'`.
  Future<CustomFieldDefinition?> createDefinition(
    String keyName,
    String fieldType,
  ) async {
    try {
      final def = await _repository.createDefinition(keyName, fieldType);
      log(
        'CustomFieldsViewModel: created definition "${def.keyName}"',
        name: 'CustomFieldsViewModel',
      );
      return def;
    } on Exception catch (e, st) {
      log(
        'CustomFieldsViewModel: createDefinition failed — $e',
        name: 'CustomFieldsViewModel',
        error: e,
        stackTrace: st,
      );
      _createError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates the definition identified by [id] with optional new [keyName]
  /// and [fieldType].
  ///
  /// Returns the updated [CustomFieldDefinition] on success, or `null` on
  /// failure. On failure [updateError] is populated and [notifyListeners] is
  /// called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the definition to update.
  /// - [keyName]: New machine-readable key; omit to leave unchanged.
  /// - [fieldType]: New field type string; omit to leave unchanged.
  Future<CustomFieldDefinition?> updateDefinition(
    String id, {
    String? keyName,
    String? fieldType,
  }) async {
    try {
      final def = await _repository.updateDefinition(
        id,
        keyName: keyName,
        fieldType: fieldType,
      );
      log(
        'CustomFieldsViewModel: updated definition "$id"',
        name: 'CustomFieldsViewModel',
      );
      return def;
    } on Exception catch (e, st) {
      log(
        'CustomFieldsViewModel: updateDefinition failed — $e',
        name: 'CustomFieldsViewModel',
        error: e,
        stackTrace: st,
      );
      _updateError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Deletes the definition identified by [id].
  ///
  /// On failure [deleteError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the definition to delete.
  Future<void> deleteDefinition(String id) async {
    try {
      await _repository.deleteDefinition(id);
      log(
        'CustomFieldsViewModel: deleted definition "$id"',
        name: 'CustomFieldsViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'CustomFieldsViewModel: deleteDefinition failed — $e',
        name: 'CustomFieldsViewModel',
        error: e,
        stackTrace: st,
      );
      _deleteError = e.toString();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Error reset helpers
  // -------------------------------------------------------------------------

  /// Clears [createError] and notifies listeners.
  void clearCreateError() {
    _createError = null;
    notifyListeners();
  }

  /// Clears [updateError] and notifies listeners.
  void clearUpdateError() {
    _updateError = null;
    notifyListeners();
  }

  /// Clears [deleteError] and notifies listeners.
  void clearDeleteError() {
    _deleteError = null;
    notifyListeners();
  }
}
