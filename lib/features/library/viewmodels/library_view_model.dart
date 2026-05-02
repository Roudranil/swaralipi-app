// LibraryViewModel — ChangeNotifier-based ViewModel for the Library screen.
//
// Subscribes to [NotationRepository.watchAllActive] and exposes state as a
// sealed [LibraryState] hierarchy: idle / loading / success / error.
//
// Provides [softDelete] for moving a notation to trash from the Library,
// and [undoDelete] for restoring it via [TrashRepository.restoreNotation]
// within the undo window.
//
// Provides [duplicate] for copying a notation via [DuplicateNotationUseCase].
// Emits the new notation id via [lastDuplicatedId] on success.
//
// A single [operationError] field surfaces per-operation failures without
// replacing the main list state.
//
// Construction:
//   LibraryViewModel(notationRepository, trashRepository,
//     duplicateUseCase: useCase)
//
// Lifecycle:
//   Call [init] once (e.g. via addPostFrameCallback in initState).
//   Disposal is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/edit/viewmodels/duplicate_notation_use_case.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [LibraryViewModel].
///
/// Variants: [LibraryStateIdle], [LibraryStateLoading],
/// [LibraryStateSuccess], [LibraryStateError].
sealed class LibraryState {
  /// Creates a [LibraryState].
  const LibraryState();
}

/// Initial state before [LibraryViewModel.init] is called.
final class LibraryStateIdle extends LibraryState {
  /// Creates a [LibraryStateIdle].
  const LibraryStateIdle();
}

/// State while awaiting the first stream emission.
final class LibraryStateLoading extends LibraryState {
  /// Creates a [LibraryStateLoading].
  const LibraryStateLoading();
}

/// State when the active notation list has been received from the stream.
final class LibraryStateSuccess extends LibraryState {
  /// Creates a [LibraryStateSuccess] with the given [notations].
  ///
  /// Parameters:
  /// - [notations]: Current list of active (non-deleted) notations.
  const LibraryStateSuccess({required this.notations});

  /// Current list of active notations, ordered by [Notation.updatedAt]
  /// descending.
  final List<Notation> notations;
}

/// State when the stream emitted an error.
final class LibraryStateError extends LibraryState {
  /// Creates a [LibraryStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const LibraryStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Library screen.
///
/// Observes [NotationRepository.watchAllActive] and translates stream events
/// into [LibraryState] values. Exposes [softDelete], [undoDelete], and
/// [duplicate] operations that surface failures via [operationError] without
/// interrupting the library list display.
///
/// State management contract:
/// - [state] is the primary display state (idle / loading / success / error).
/// - [operationError] is an auxiliary error field; it does not affect [state]
///   so the list remains visible while an operation error is shown.
/// - [lastDuplicatedId] carries the new notation id after a successful
///   [duplicate] call. Clear with [clearLastDuplicatedId].
class LibraryViewModel extends ChangeNotifier {
  /// Creates a [LibraryViewModel] backed by the given repositories.
  ///
  /// Parameters:
  /// - [_notationRepository]: Source of truth for active notation list.
  /// - [_trashRepository]: Used to restore a soft-deleted notation on undo.
  /// - [duplicateUseCase]: Optional use case for duplicating a notation.
  ///   When null the [duplicate] method is a no-op.
  LibraryViewModel(
    this._notationRepository,
    this._trashRepository, {
    DuplicateNotationUseCase? duplicateUseCase,
  }) : _duplicateUseCase = duplicateUseCase;

  final NotationRepository _notationRepository;
  final TrashRepository _trashRepository;
  final DuplicateNotationUseCase? _duplicateUseCase;
  StreamSubscription<List<Notation>>? _subscription;

  LibraryState _state = const LibraryStateIdle();
  String? _operationError;
  String? _lastDuplicatedId;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the library screen.
  LibraryState get state => _state;

  /// Non-null when the most recent operation (softDelete / undoDelete / duplicate) failed.
  ///
  /// Clear with [clearOperationError] after the error has been surfaced.
  String? get operationError => _operationError;

  /// Non-null when the most recent [duplicate] call succeeded.
  ///
  /// Contains the new notation's UUID. Clear with [clearLastDuplicatedId]
  /// after the caller has consumed the value (e.g., after navigation).
  String? get lastDuplicatedId => _lastDuplicatedId;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the active notation stream and begins emitting state
  /// updates.
  ///
  /// Transitions immediately to [LibraryStateLoading], then to
  /// [LibraryStateSuccess] or [LibraryStateError] as the stream emits.
  /// Calling [init] again cancels the previous subscription before
  /// restarting.
  void init() {
    _subscription?.cancel();
    _state = const LibraryStateLoading();
    notifyListeners();

    _subscription = _notationRepository.watchAllActive().listen(
      (notations) {
        _state = LibraryStateSuccess(notations: notations);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'LibraryViewModel: stream error — $error',
          name: 'LibraryViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = LibraryStateError(message: error.toString());
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
  // Operations
  // -------------------------------------------------------------------------

  /// Soft-deletes the notation identified by [id].
  ///
  /// Sets `deleted_at` on the notation row, removing it from the active list.
  /// On failure [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to soft-delete.
  Future<void> softDelete(String id) async {
    try {
      await _notationRepository.softDelete(id);
      log('LibraryViewModel: soft-deleted notation $id',
          name: 'LibraryViewModel');
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: softDelete failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Restores the notation identified by [id] from the trash.
  ///
  /// Called when the user taps "Undo" on the deletion SnackBar. On failure
  /// [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to restore.
  Future<void> undoDelete(String id) async {
    try {
      await _trashRepository.restoreNotation(id);
      log('LibraryViewModel: restored notation $id', name: 'LibraryViewModel');
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: undoDelete failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Duplicates the notation identified by [id].
  ///
  /// Copies all page files to a new directory and creates a new notation
  /// record with the same metadata and title suffixed with " (copy)".
  ///
  /// On success [lastDuplicatedId] is set to the new notation's UUID and
  /// [notifyListeners] is called. On failure [operationError] is populated.
  ///
  /// No-op when [duplicateUseCase] was not provided at construction time.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to duplicate.
  Future<void> duplicate(String id) async {
    final useCase = _duplicateUseCase;
    if (useCase == null) return;

    try {
      final newId = await useCase.execute(id);
      _lastDuplicatedId = newId;
      log(
        'LibraryViewModel: duplicated notation $id → $newId',
        name: 'LibraryViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'LibraryViewModel: duplicate failed — $e',
        name: 'LibraryViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Error reset
  // -------------------------------------------------------------------------

  /// Clears [operationError] and notifies listeners.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }

  /// Clears [lastDuplicatedId] and notifies listeners.
  ///
  /// Call after the caller has consumed the value (e.g., navigated to the
  /// new notation's detail screen).
  void clearLastDuplicatedId() {
    _lastDuplicatedId = null;
    notifyListeners();
  }
}
