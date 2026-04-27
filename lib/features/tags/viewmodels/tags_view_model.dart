// TagsViewModel — ChangeNotifier-based ViewModel for the Tags feature.
//
// Subscribes to [TagRepository.watchAllTags] and exposes state as a sealed
// [TagsState] hierarchy: idle / loading / success / error.
//
// Separate per-operation error fields (createError, updateError, deleteError)
// allow the UI to surface operation-specific error feedback without replacing
// the entire list state.
//
// Construction:
//   TagsViewModel(tagRepository)
//
// Lifecycle:
//   Call [init] once from the screen's initState / DidChangeDependencies.
//   Dispose is handled by the ChangeNotifier lifecycle.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for the [TagsViewModel].
///
/// Variants: [TagsStateIdle], [TagsStateLoading], [TagsStateSuccess],
/// [TagsStateError].
sealed class TagsState {
  /// Creates a [TagsState].
  const TagsState();
}

/// Initial state before [TagsViewModel.init] is called.
final class TagsStateIdle extends TagsState {
  /// Creates a [TagsStateIdle].
  const TagsStateIdle();
}

/// State while awaiting the first stream emission.
final class TagsStateLoading extends TagsState {
  /// Creates a [TagsStateLoading].
  const TagsStateLoading();
}

/// State when the tag list has been successfully received from the stream.
final class TagsStateSuccess extends TagsState {
  /// Creates a [TagsStateSuccess] with the given [tags].
  ///
  /// Parameters:
  /// - [tags]: The current list of all user-defined tags.
  const TagsStateSuccess({required this.tags});

  /// The current list of all tags, ordered alphabetically.
  final List<Tag> tags;
}

/// State when the stream emitted an error.
final class TagsStateError extends TagsState {
  /// Creates a [TagsStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const TagsStateError({required this.message});

  /// Human-readable description of the stream error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Tags management screen.
///
/// Observes [TagRepository.watchAllTags] and translates stream events into
/// [TagsState] values. Exposes CRUD operations that delegate to the repository
/// and surface per-operation errors via dedicated nullable fields.
///
/// State management contract:
/// - [state] is the primary display state (idle / loading / success / error).
/// - [createError], [updateError], [deleteError] are auxiliary error fields;
///   they do not affect [state] so the tag list remains visible while an
///   operation-specific error is surfaced.
class TagsViewModel extends ChangeNotifier {
  /// Creates a [TagsViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for all tag data operations.
  TagsViewModel(this._repository);

  final TagRepository _repository;
  StreamSubscription<List<Tag>>? _subscription;

  TagsState _state = const TagsStateIdle();
  String? _createError;
  String? _updateError;
  String? _deleteError;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the tags screen.
  TagsState get state => _state;

  /// Non-null when the most recent [createTag] call failed.
  ///
  /// Clear with [clearCreateError] after the error has been surfaced.
  String? get createError => _createError;

  /// Non-null when the most recent [updateTag] call failed.
  ///
  /// Clear with [clearUpdateError] after the error has been surfaced.
  String? get updateError => _updateError;

  /// Non-null when the most recent [deleteTag] call failed.
  ///
  /// Clear with [clearDeleteError] after the error has been surfaced.
  String? get deleteError => _deleteError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Subscribes to the tag stream and begins emitting state updates.
  ///
  /// Transitions immediately to [TagsStateLoading], then to
  /// [TagsStateSuccess] or [TagsStateError] as the stream emits. Calling
  /// [init] again cancels the previous subscription before restarting.
  void init() {
    _subscription?.cancel();
    _state = const TagsStateLoading();
    notifyListeners();

    _subscription = _repository.watchAllTags().listen(
      (tags) {
        _state = TagsStateSuccess(tags: tags);
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        log(
          'TagsViewModel: stream error — $error',
          name: 'TagsViewModel',
          error: error,
          stackTrace: stack,
        );
        _state = TagsStateError(message: error.toString());
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

  /// Creates a new tag with [name] and [colorHex].
  ///
  /// Returns the persisted [Tag] on success, or `null` on failure. On failure
  /// [createError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [name]: Unique display name for the new tag.
  /// - [colorHex]: Catppuccin hex color string, e.g. `'#f38ba8'`.
  Future<Tag?> createTag(String name, String colorHex) async {
    try {
      final tag = await _repository.createTag(name, colorHex);
      log(
        'TagsViewModel: created tag "${tag.name}"',
        name: 'TagsViewModel',
      );
      return tag;
    } on Exception catch (e, st) {
      log(
        'TagsViewModel: createTag failed — $e',
        name: 'TagsViewModel',
        error: e,
        stackTrace: st,
      );
      _createError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Updates the tag identified by [id] with optional new [name] and
  /// [colorHex].
  ///
  /// Returns the updated [Tag] on success, or `null` on failure. On failure
  /// [updateError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the tag to update.
  /// - [name]: New display name; omit to leave unchanged.
  /// - [colorHex]: New Catppuccin hex color string; omit to leave unchanged.
  Future<Tag?> updateTag(
    String id, {
    String? name,
    String? colorHex,
  }) async {
    try {
      final tag =
          await _repository.updateTag(id, name: name, colorHex: colorHex);
      log(
        'TagsViewModel: updated tag "$id"',
        name: 'TagsViewModel',
      );
      return tag;
    } on Exception catch (e, st) {
      log(
        'TagsViewModel: updateTag failed — $e',
        name: 'TagsViewModel',
        error: e,
        stackTrace: st,
      );
      _updateError = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Deletes the tag identified by [id].
  ///
  /// On failure [deleteError] is populated and [notifyListeners] is called.
  ///
  /// Parameters:
  /// - [id]: UUIDv4 of the tag to delete.
  Future<void> deleteTag(String id) async {
    try {
      await _repository.deleteTag(id);
      log(
        'TagsViewModel: deleted tag "$id"',
        name: 'TagsViewModel',
      );
    } on Exception catch (e, st) {
      log(
        'TagsViewModel: deleteTag failed — $e',
        name: 'TagsViewModel',
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
