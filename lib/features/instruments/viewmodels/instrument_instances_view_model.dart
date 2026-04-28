// InstrumentInstancesViewModel — ChangeNotifier-based ViewModel for the
// InstrumentInstances feature.
//
// Subscribes to [InstrumentRepository.watchActiveInstancesForClass] and
// exposes state as a sealed [InstrumentInstancesState] hierarchy:
// idle / loading / success / error.
//
// Separate per-operation error fields (createError, updateError, archiveError)
// allow the UI to surface operation-specific feedback without replacing the
// entire list state.
//
// Construction:
//   InstrumentInstancesViewModel(instrumentRepository, classId: classId)
//
// Lifecycle:
//   Call [init] once from the screen's initState / didChangeDependencies.
//   Dispose is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [InstrumentInstancesViewModel].
///
/// Variants: [InstrumentInstancesStateIdle],
/// [InstrumentInstancesStateLoading], [InstrumentInstancesStateSuccess],
/// [InstrumentInstancesStateError].
sealed class InstrumentInstancesState {
  /// Creates an [InstrumentInstancesState].
  const InstrumentInstancesState();
}

/// Initial state before [InstrumentInstancesViewModel.init] is called.
final class InstrumentInstancesStateIdle extends InstrumentInstancesState {
  /// Creates an [InstrumentInstancesStateIdle].
  const InstrumentInstancesStateIdle();
}

/// State while awaiting the first stream emission.
final class InstrumentInstancesStateLoading extends InstrumentInstancesState {
  /// Creates an [InstrumentInstancesStateLoading].
  const InstrumentInstancesStateLoading();
}

/// State when the instance list has been successfully received.
final class InstrumentInstancesStateSuccess extends InstrumentInstancesState {
  /// Creates an [InstrumentInstancesStateSuccess] with the given [instances].
  ///
  /// Parameters:
  /// - [instances]: The current list of active instrument instances.
  const InstrumentInstancesStateSuccess({required this.instances});

  /// The current list of all active instrument instances for this class.
  final List<InstrumentInstance> instances;
}

/// State when the stream emitted an error.
final class InstrumentInstancesStateError extends InstrumentInstancesState {
  /// Creates an [InstrumentInstancesStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const InstrumentInstancesStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Instrument Instances management screen.
///
/// Observes [InstrumentRepository.watchActiveInstancesForClass] and translates
/// stream events into [InstrumentInstancesState] values. Exposes CRUD
/// operations that delegate to the repository and surface per-operation errors
/// via dedicated nullable fields.
///
/// State management contract:
/// - [state] is the primary display state.
/// - [createError], [updateError], [archiveError] are auxiliary error fields.
class InstrumentInstancesViewModel extends ChangeNotifier {
  /// Creates an [InstrumentInstancesViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for all instrument instance operations.
  /// - [classId]: The UUIDv4 of the instrument class whose instances to watch.
  InstrumentInstancesViewModel(
    this._repository, {
    required this.classId,
  });

  final InstrumentRepository _repository;

  /// The instrument class this ViewModel manages instances for.
  final String classId;

  StreamSubscription<List<InstrumentInstance>>? _subscription;

  InstrumentInstancesState _state = const InstrumentInstancesStateIdle();
  String? _createError;
  String? _updateError;
  String? _archiveError;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the instrument instances screen.
  InstrumentInstancesState get state => _state;

  /// Non-null when the most recent [createInstance] call failed.
  ///
  /// Clear with [clearCreateError] after the error has been surfaced.
  String? get createError => _createError;

  /// Non-null when the most recent [updateInstance] call failed.
  ///
  /// Clear with [clearUpdateError] after the error has been surfaced.
  String? get updateError => _updateError;

  /// Non-null when the most recent [archiveInstance] call failed.
  ///
  /// Clear with [clearArchiveError] after the error has been surfaced.
  String? get archiveError => _archiveError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the instance stream and begins emitting state updates.
  ///
  /// Transitions immediately to [InstrumentInstancesStateLoading], then to
  /// [InstrumentInstancesStateSuccess] or [InstrumentInstancesStateError] as
  /// the stream emits. Calling [init] again cancels the previous subscription
  /// before restarting.
  void init() {
    _subscription?.cancel();
    _state = const InstrumentInstancesStateLoading();
    notifyListeners();

    _subscription = _repository.watchActiveInstancesForClass(classId).listen(
      (instances) {
        _state = InstrumentInstancesStateSuccess(instances: instances);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'InstrumentInstancesViewModel: stream error — $error',
          name: 'InstrumentInstancesViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = InstrumentInstancesStateError(message: error.toString());
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

  /// Creates a new instrument instance under [classId].
  ///
  /// Returns the persisted [InstrumentInstance] on success, or `null` on
  /// failure. On failure [createError] is populated and [notifyListeners] is
  /// called.
  ///
  /// Parameters:
  /// - [colorHex]: Catppuccin hex string for UI display.
  /// - [brand]: Optional brand name.
  /// - [model]: Optional model name.
  /// - [priceInr]: Optional purchase price in INR.
  /// - [photoPath]: Relative path of the instrument photo.
  /// - [notes]: Free-form notes.
  Future<InstrumentInstance?> createInstance({
    required String colorHex,
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  }) async {
    try {
      final inst = await _repository.createInstance(
        classId,
        colorHex: colorHex,
        brand: brand,
        model: model,
        priceInr: priceInr,
        photoPath: photoPath,
        notes: notes,
      );
      log(
        'InstrumentInstancesViewModel: created instance "${inst.id}"',
        name: 'InstrumentInstancesViewModel',
      );
      return inst;
    } on Exception catch (e, st) {
      log(
        'InstrumentInstancesViewModel: createInstance failed — $e',
        name: 'InstrumentInstancesViewModel',
        error: e,
        stackTrace: st,
      );
      _createError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates fields of the instance identified by [id].
  ///
  /// Returns the updated [InstrumentInstance] on success, or `null` on
  /// failure. On failure [updateError] is populated and [notifyListeners] is
  /// called.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 of the instance to update.
  /// - [brand]: New brand name.
  /// - [model]: New model name.
  /// - [colorHex]: New Catppuccin hex color.
  /// - [priceInr]: New price in INR.
  /// - [photoPath]: New relative photo path.
  /// - [notes]: New free-form notes.
  Future<InstrumentInstance?> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  }) async {
    try {
      final inst = await _repository.updateInstance(
        id,
        brand: brand,
        model: model,
        colorHex: colorHex,
        priceInr: priceInr,
        photoPath: photoPath,
        notes: notes,
      );
      log(
        'InstrumentInstancesViewModel: updated instance "$id"',
        name: 'InstrumentInstancesViewModel',
      );
      return inst;
    } on Exception catch (e, st) {
      log(
        'InstrumentInstancesViewModel: updateInstance failed — $e',
        name: 'InstrumentInstancesViewModel',
        error: e,
        stackTrace: st,
      );
      _updateError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Archives the instance identified by [id].
  ///
  /// On failure [archiveError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 of the instance to archive.
  Future<void> archiveInstance(String id) async {
    try {
      await _repository.archiveInstance(id);
      log(
        'InstrumentInstancesViewModel: archived instance "$id"',
        name: 'InstrumentInstancesViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'InstrumentInstancesViewModel: archiveInstance failed — $e',
        name: 'InstrumentInstancesViewModel',
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

  /// Sets [state] directly. Used exclusively in widget tests to drive specific
  /// UI states without a live stream.
  ///
  /// Parameters:
  /// - [state]: The [InstrumentInstancesState] to display.
  @visibleForTesting
  void testSetState(InstrumentInstancesState state) {
    _state = state;
    notifyListeners();
  }
}
