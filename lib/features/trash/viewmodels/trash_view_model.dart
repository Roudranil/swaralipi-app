// TrashViewModel — ChangeNotifier-based ViewModel for the Trash screen.
//
// Subscribes to [TrashRepository.watchTrashedNotations] and exposes state as
// a sealed [TrashState] hierarchy: idle / loading / success / error.
//
// A single [operationError] field surfaces per-operation failures (restore,
// purge, purgeAll) without replacing the main list state, so the trash list
// remains visible while an error message is shown.
//
// Construction:
//   TrashViewModel(trashRepository)
//
// Lifecycle:
//   Call [init] once (e.g. via addPostFrameCallback in initState).
//   Disposal is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [TrashViewModel].
///
/// Variants: [TrashStateIdle], [TrashStateLoading], [TrashStateSuccess],
/// [TrashStateError].
sealed class TrashState {
  /// Creates a [TrashState].
  const TrashState();
}

/// Initial state before [TrashViewModel.init] is called.
final class TrashStateIdle extends TrashState {
  /// Creates a [TrashStateIdle].
  const TrashStateIdle();
}

/// State while awaiting the first stream emission.
final class TrashStateLoading extends TrashState {
  /// Creates a [TrashStateLoading].
  const TrashStateLoading();
}

/// State when the trash list has been received from the stream.
final class TrashStateSuccess extends TrashState {
  /// Creates a [TrashStateSuccess] with the given [notations].
  ///
  /// Parameters:
  /// - [notations]: Current list of soft-deleted notations.
  const TrashStateSuccess({required this.notations});

  /// Current list of soft-deleted notations, ordered by [Notation.deletedAt]
  /// descending.
  final List<Notation> notations;
}

/// State when the stream emitted an error.
final class TrashStateError extends TrashState {
  /// Creates a [TrashStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const TrashStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Trash management screen.
///
/// Observes [TrashRepository.watchTrashedNotations] and translates stream
/// events into [TrashState] values. Exposes restore, purge, and purgeAll
/// operations that surface failures via [operationError] without interrupting
/// the trash list display.
///
/// State management contract:
/// - [state] is the primary display state (idle / loading / success / error).
/// - [operationError] is an auxiliary error field; it does not affect [state]
///   so the list remains visible while an operation error is surfaced.
class TrashViewModel extends ChangeNotifier {
  /// Creates a [TrashViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for all trash lifecycle operations.
  TrashViewModel(this._repository);

  final TrashRepository _repository;
  StreamSubscription<List<Notation>>? _subscription;

  TrashState _state = const TrashStateIdle();
  String? _operationError;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the trash screen.
  TrashState get state => _state;

  /// Non-null when the most recent operation (restore / purge / purgeAll)
  /// failed.
  ///
  /// Clear with [clearOperationError] after the error has been surfaced.
  String? get operationError => _operationError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the trash stream and begins emitting state updates.
  ///
  /// Transitions immediately to [TrashStateLoading], then to
  /// [TrashStateSuccess] or [TrashStateError] as the stream emits. Calling
  /// [init] again cancels the previous subscription before restarting.
  void init() {
    _subscription?.cancel();
    _state = const TrashStateLoading();
    notifyListeners();

    _subscription = _repository.watchTrashedNotations().listen(
      (notations) {
        _state = TrashStateSuccess(notations: notations);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'TrashViewModel: stream error — $error',
          name: 'TrashViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = TrashStateError(message: error.toString());
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

  /// Restores the notation identified by [id].
  ///
  /// On failure [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to restore.
  Future<void> restoreNotation(String id) async {
    try {
      await _repository.restoreNotation(id);
      log('TrashViewModel: restored notation $id', name: 'TrashViewModel');
    } on Exception catch (e, st) {
      log(
        'TrashViewModel: restoreNotation failed — $e',
        name: 'TrashViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Permanently deletes the notation identified by [id].
  ///
  /// On failure [operationError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to purge.
  Future<void> purgeNotation(String id) async {
    try {
      await _repository.purgeNotation(id);
      log('TrashViewModel: purged notation $id', name: 'TrashViewModel');
    } on Exception catch (e, st) {
      log(
        'TrashViewModel: purgeNotation failed — $e',
        name: 'TrashViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  /// Permanently deletes all trashed notations.
  ///
  /// On failure [operationError] is populated and [notifyListeners] is called.
  Future<void> purgeAll() async {
    try {
      await _repository.purgeAll();
      log('TrashViewModel: purged all trashed notations',
          name: 'TrashViewModel');
    } on Exception catch (e, st) {
      log(
        'TrashViewModel: purgeAll failed — $e',
        name: 'TrashViewModel',
        error: e,
        stackTrace: st,
      );
      _operationError = e.toString();
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Error reset
  // -------------------------------------------------------------------------

  /// Clears [operationError] and notifies listeners.
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }
}
