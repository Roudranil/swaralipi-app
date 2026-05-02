// NotationDetailViewModel — ChangeNotifier-based ViewModel for the notation
// detail screen.
//
// Loads a fully-hydrated [NotationDetail] via [NotationRepository.loadNotation]
// and exposes state as a sealed [NotationDetailState] hierarchy:
// idle / loading / success / notFound / error.
//
// Provides [softDelete] for moving the notation to trash from the detail view.
// The [onDeleted] callback allows the caller (screen) to trigger navigation
// back to the library after a successful delete.
//
// Provides [undoDelete] for restoring the notation via
// [TrashRepository.restoreNotation] within the undo window.
//
// Provides [duplicate] for copying a notation via [DuplicateNotationUseCase].
// Emits the new notation id via [lastDuplicatedId] on success.
//
// A single [operationError] field surfaces per-operation failures without
// replacing the main state.
//
// Construction:
//   NotationDetailViewModel(notationRepository, trashRepository,
//     duplicateUseCase: useCase)
//
// Lifecycle:
//   Call [loadNotation] once per navigation to the detail screen.
//   Disposal is handled by the ChangeNotifier lifecycle.

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/edit/viewmodels/duplicate_notation_use_case.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [NotationDetailViewModel].
///
/// Variants: [NotationDetailStateIdle], [NotationDetailStateLoading],
/// [NotationDetailStateSuccess], [NotationDetailStateNotFound],
/// [NotationDetailStateError].
sealed class NotationDetailState {
  /// Creates a [NotationDetailState].
  const NotationDetailState();
}

/// Initial state before [NotationDetailViewModel.loadNotation] is called.
final class NotationDetailStateIdle extends NotationDetailState {
  /// Creates a [NotationDetailStateIdle].
  const NotationDetailStateIdle();
}

/// State while [NotationDetailViewModel.loadNotation] is in progress.
final class NotationDetailStateLoading extends NotationDetailState {
  /// Creates a [NotationDetailStateLoading].
  const NotationDetailStateLoading();
}

/// State when the notation was successfully loaded.
final class NotationDetailStateSuccess extends NotationDetailState {
  /// Creates a [NotationDetailStateSuccess] with the given [detail].
  ///
  /// Parameters:
  /// - [detail]: Fully-hydrated notation aggregate.
  const NotationDetailStateSuccess({required this.detail});

  /// Fully-hydrated notation aggregate for display.
  final NotationDetail detail;
}

/// State when no notation with the requested id exists.
final class NotationDetailStateNotFound extends NotationDetailState {
  /// Creates a [NotationDetailStateNotFound].
  const NotationDetailStateNotFound();
}

/// State when loading the notation failed with an exception.
final class NotationDetailStateError extends NotationDetailState {
  /// Creates a [NotationDetailStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const NotationDetailStateError({required this.message});

  /// Human-readable description of the load error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the notation detail screen.
///
/// Loads a single [NotationDetail] and translates the result into a
/// [NotationDetailState] value. Exposes [softDelete] and [undoDelete]
/// operations that surface failures via [operationError] without interrupting
/// the detail view display.
///
/// State management contract:
/// - [state] is the primary display state.
/// - [operationError] is an auxiliary error field set on operation failure.
class NotationDetailViewModel extends ChangeNotifier {
  /// Creates a [NotationDetailViewModel] backed by the given repositories.
  ///
  /// Parameters:
  /// - [_notationRepository]: Source of truth for notation loading and delete.
  /// - [_trashRepository]: Used to restore a soft-deleted notation on undo.
  /// - [duplicateUseCase]: Optional use case for duplicating a notation.
  ///   When null the [duplicate] method is a no-op.
  NotationDetailViewModel(
    this._notationRepository,
    this._trashRepository, {
    DuplicateNotationUseCase? duplicateUseCase,
  }) : _duplicateUseCase = duplicateUseCase;

  final NotationRepository _notationRepository;
  final TrashRepository _trashRepository;
  final DuplicateNotationUseCase? _duplicateUseCase;

  NotationDetailState _state = const NotationDetailStateIdle();
  String? _operationError;
  String? _lastDuplicatedId;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the notation detail screen.
  NotationDetailState get state => _state;

  /// Non-null when the most recent operation (softDelete / undoDelete /
  /// duplicate) failed.
  ///
  /// Clear with [clearOperationError] after the error has been surfaced.
  String? get operationError => _operationError;

  /// Non-null when the most recent [duplicate] call succeeded.
  ///
  /// Contains the new notation's UUID. Clear with [clearLastDuplicatedId]
  /// after the caller has consumed the value (e.g., navigated to detail).
  String? get lastDuplicatedId => _lastDuplicatedId;

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------

  /// Loads the notation identified by [id] and transitions state accordingly.
  ///
  /// Transitions to [NotationDetailStateLoading] while in flight, then to
  /// [NotationDetailStateSuccess], [NotationDetailStateNotFound] (when the
  /// repository returns null), or [NotationDetailStateError] on exception.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to load.
  Future<void> loadNotation(String id) async {
    _state = const NotationDetailStateLoading();
    notifyListeners();

    try {
      final detail = await _notationRepository.loadNotation(id);
      if (detail == null) {
        _state = const NotationDetailStateNotFound();
      } else {
        _state = NotationDetailStateSuccess(detail: detail);
      }
    } on Exception catch (e, st) {
      log(
        'NotationDetailViewModel: loadNotation failed — $e',
        name: 'NotationDetailViewModel',
        error: e,
        stackTrace: st,
      );
      _state = NotationDetailStateError(message: e.toString());
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Operations
  // -------------------------------------------------------------------------

  /// Soft-deletes the notation identified by [id].
  ///
  /// Sets `deleted_at` on the notation row, moving it to trash. On success
  /// the optional [onDeleted] callback is invoked so the caller can navigate
  /// back to the library. On failure [operationError] is populated.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the notation to soft-delete.
  /// - [onDeleted]: Optional callback invoked after a successful delete.
  Future<void> softDelete(String id, {VoidCallback? onDeleted}) async {
    try {
      await _notationRepository.softDelete(id);
      log(
        'NotationDetailViewModel: soft-deleted notation $id',
        name: 'NotationDetailViewModel',
      );
      onDeleted?.call();
    } on Exception catch (e, st) {
      log(
        'NotationDetailViewModel: softDelete failed — $e',
        name: 'NotationDetailViewModel',
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
      log(
        'NotationDetailViewModel: restored notation $id',
        name: 'NotationDetailViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'NotationDetailViewModel: undoDelete failed — $e',
        name: 'NotationDetailViewModel',
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
        'NotationDetailViewModel: duplicated notation $id → $newId',
        name: 'NotationDetailViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'NotationDetailViewModel: duplicate failed — $e',
        name: 'NotationDetailViewModel',
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
