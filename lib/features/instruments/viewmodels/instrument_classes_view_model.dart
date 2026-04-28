// InstrumentClassesViewModel — ChangeNotifier-based ViewModel for the
// InstrumentClasses feature.
//
// Subscribes to [InstrumentRepository.watchActiveClasses] and exposes state
// as a sealed [InstrumentClassesState] hierarchy:
// idle / loading / success / error.
//
// Separate per-operation error fields (createError, updateError, archiveError)
// allow the UI to surface operation-specific feedback without replacing the
// entire list state.
//
// Construction:
//   InstrumentClassesViewModel(instrumentRepository)
//
// Lifecycle:
//   Call [init] once from the screen's initState / didChangeDependencies.
//   Dispose is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [InstrumentClassesViewModel].
///
/// Variants: [InstrumentClassesStateIdle], [InstrumentClassesStateLoading],
/// [InstrumentClassesStateSuccess], [InstrumentClassesStateError].
sealed class InstrumentClassesState {
  /// Creates an [InstrumentClassesState].
  const InstrumentClassesState();
}

/// Initial state before [InstrumentClassesViewModel.init] is called.
final class InstrumentClassesStateIdle extends InstrumentClassesState {
  /// Creates an [InstrumentClassesStateIdle].
  const InstrumentClassesStateIdle();
}

/// State while awaiting the first stream emission.
final class InstrumentClassesStateLoading extends InstrumentClassesState {
  /// Creates an [InstrumentClassesStateLoading].
  const InstrumentClassesStateLoading();
}

/// State when the class list has been successfully received from the stream.
final class InstrumentClassesStateSuccess extends InstrumentClassesState {
  /// Creates an [InstrumentClassesStateSuccess] with the given [classes].
  ///
  /// Parameters:
  /// - [classes]: The current list of all active instrument classes.
  const InstrumentClassesStateSuccess({required this.classes});

  /// The current list of all active instrument classes, ordered alphabetically.
  final List<InstrumentClass> classes;
}

/// State when the stream emitted an error.
final class InstrumentClassesStateError extends InstrumentClassesState {
  /// Creates an [InstrumentClassesStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const InstrumentClassesStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Instrument Classes management screen.
///
/// Observes [InstrumentRepository.watchActiveClasses] and translates stream
/// events into [InstrumentClassesState] values. Exposes CRUD operations that
/// delegate to the repository and surface per-operation errors via dedicated
/// nullable fields.
///
/// State management contract:
/// - [state] is the primary display state.
/// - [createError], [updateError], [archiveError] are auxiliary error fields;
///   they do not affect [state] so the class list remains visible while an
///   operation-specific error is surfaced.
class InstrumentClassesViewModel extends ChangeNotifier {
  /// Creates an [InstrumentClassesViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for all instrument class operations.
  InstrumentClassesViewModel(this._repository);

  final InstrumentRepository _repository;
  StreamSubscription<List<InstrumentClass>>? _subscription;

  InstrumentClassesState _state = const InstrumentClassesStateIdle();
  String? _createError;
  String? _updateError;
  String? _archiveError;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the instrument classes screen.
  InstrumentClassesState get state => _state;

  /// Non-null when the most recent [createClass] call failed.
  ///
  /// Clear with [clearCreateError] after the error has been surfaced.
  String? get createError => _createError;

  /// Non-null when the most recent [updateClass] call failed.
  ///
  /// Clear with [clearUpdateError] after the error has been surfaced.
  String? get updateError => _updateError;

  /// Non-null when the most recent [archiveClass] call failed.
  ///
  /// Clear with [clearArchiveError] after the error has been surfaced.
  String? get archiveError => _archiveError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the class stream and begins emitting state updates.
  ///
  /// Transitions immediately to [InstrumentClassesStateLoading], then to
  /// [InstrumentClassesStateSuccess] or [InstrumentClassesStateError] as the
  /// stream emits. Calling [init] again cancels the previous subscription
  /// before restarting.
  void init() {
    _subscription?.cancel();
    _state = const InstrumentClassesStateLoading();
    notifyListeners();

    _subscription = _repository.watchActiveClasses().listen(
      (classes) {
        _state = InstrumentClassesStateSuccess(classes: classes);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'InstrumentClassesViewModel: stream error — $error',
          name: 'InstrumentClassesViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = InstrumentClassesStateError(message: error.toString());
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

  /// Creates a new instrument class with [name].
  ///
  /// Returns the persisted [InstrumentClass] on success, or `null` on failure.
  /// On failure [createError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [name]: Unique human-readable display name for the new class.
  Future<InstrumentClass?> createClass(String name) async {
    try {
      final cls = await _repository.createClass(name);
      log(
        'InstrumentClassesViewModel: created class "${cls.name}"',
        name: 'InstrumentClassesViewModel',
      );
      return cls;
    } on Exception catch (e, st) {
      log(
        'InstrumentClassesViewModel: createClass failed — $e',
        name: 'InstrumentClassesViewModel',
        error: e,
        stackTrace: st,
      );
      _createError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates the instrument class identified by [id] with new [name].
  ///
  /// Returns the updated [InstrumentClass] on success, or `null` on failure.
  /// On failure [updateError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the class to update.
  /// - [name]: New display name for the class.
  Future<InstrumentClass?> updateClass(String id, String name) async {
    try {
      final cls = await _repository.updateClass(id, name);
      log(
        'InstrumentClassesViewModel: updated class "$id"',
        name: 'InstrumentClassesViewModel',
      );
      return cls;
    } on Exception catch (e, st) {
      log(
        'InstrumentClassesViewModel: updateClass failed — $e',
        name: 'InstrumentClassesViewModel',
        error: e,
        stackTrace: st,
      );
      _updateError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Archives the instrument class identified by [id].
  ///
  /// On failure [archiveError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the class to archive.
  Future<void> archiveClass(String id) async {
    try {
      await _repository.archiveClass(id);
      log(
        'InstrumentClassesViewModel: archived class "$id"',
        name: 'InstrumentClassesViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'InstrumentClassesViewModel: archiveClass failed — $e',
        name: 'InstrumentClassesViewModel',
        error: e,
        stackTrace: st,
      );
      _archiveError = e.toString();
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

  /// Clears [archiveError] and notifies listeners.
  void clearArchiveError() {
    _archiveError = null;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Test helpers
  // -------------------------------------------------------------------------

  /// Sets the [state] directly. Used exclusively in widget tests to drive
  /// specific UI states without requiring a live stream.
  ///
  /// Parameters:
  /// - [state]: The [InstrumentClassesState] to display.
  // ignore: invalid_use_of_visible_for_testing_member
  @visibleForTesting
  void testSetState(InstrumentClassesState state) {
    _state = state;
    notifyListeners();
  }
}
