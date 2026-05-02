// NotationPlayerViewModel — ChangeNotifier for the full-screen notation player.
//
// Loads a [NotationDetail] via [NotationRepository.loadNotation], records the
// play-count on successful load via [NotationRepository.updatePlayCount], and
// exposes state as a sealed [NotationPlayerState] hierarchy.
//
// Also tracks the active page index and chrome-visibility flag used by
// [NotationPlayerScreen] for the fade-in/fade-out UI affordance.
//
// Construction:
//   NotationPlayerViewModel(
//     notationRepository,
//     notationId: id,
//     startPage: 0,    // optional, defaults to 0
//   )
//
// Lifecycle:
//   Call [loadNotation] once per navigation to the player screen.
//   Call [dispose] when the screen is removed from the tree (ChangeNotifier
//   lifecycle handles this automatically when used with ChangeNotifierProvider).

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [NotationPlayerViewModel].
///
/// Variants: [NotationPlayerStateIdle], [NotationPlayerStateLoading],
/// [NotationPlayerStateSuccess], [NotationPlayerStateNotFound],
/// [NotationPlayerStateError].
sealed class NotationPlayerState {
  /// Creates a [NotationPlayerState].
  const NotationPlayerState();
}

/// Initial state before [NotationPlayerViewModel.loadNotation] is called.
final class NotationPlayerStateIdle extends NotationPlayerState {
  /// Creates a [NotationPlayerStateIdle].
  const NotationPlayerStateIdle();
}

/// State while [NotationPlayerViewModel.loadNotation] is in progress.
final class NotationPlayerStateLoading extends NotationPlayerState {
  /// Creates a [NotationPlayerStateLoading].
  const NotationPlayerStateLoading();
}

/// State when the notation was successfully loaded.
final class NotationPlayerStateSuccess extends NotationPlayerState {
  /// Creates a [NotationPlayerStateSuccess] with the given [detail].
  ///
  /// Parameters:
  /// - [detail]: Fully-hydrated notation aggregate.
  const NotationPlayerStateSuccess({required this.detail});

  /// Fully-hydrated notation aggregate for display.
  final NotationDetail detail;
}

/// State when no notation with the requested id exists.
final class NotationPlayerStateNotFound extends NotationPlayerState {
  /// Creates a [NotationPlayerStateNotFound].
  const NotationPlayerStateNotFound();
}

/// State when loading the notation failed with an exception.
final class NotationPlayerStateError extends NotationPlayerState {
  /// Creates a [NotationPlayerStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const NotationPlayerStateError({required this.message});

  /// Human-readable description of the load error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the full-screen notation player screen.
///
/// Loads a [NotationDetail], records the play count on success, and exposes
/// per-page navigation state and chrome-visibility state used by the
/// [NotationPlayerScreen].
///
/// State management contract:
/// - [state] drives the primary display state.
/// - [currentPage] is the 0-indexed currently-visible page.
/// - [isChromeVisible] controls whether the title bar and toolbar are shown.
class NotationPlayerViewModel extends ChangeNotifier {
  /// Creates a [NotationPlayerViewModel].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for notation loading and play-count.
  /// - [notationId]: UUIDv4 of the notation to load.
  /// - [startPage]: 0-indexed page to open initially. Defaults to `0`.
  NotationPlayerViewModel(
    this._repository, {
    required this.notationId,
    int startPage = 0,
  }) : _currentPage = startPage;

  final NotationRepository _repository;

  /// UUIDv4 of the notation being displayed.
  final String notationId;

  NotationPlayerState _state = const NotationPlayerStateIdle();
  int _currentPage;
  bool _isChromeVisible = true;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the player screen.
  NotationPlayerState get state => _state;

  /// 0-indexed index of the currently-visible page.
  int get currentPage => _currentPage;

  /// Whether the title bar and bottom toolbar are visible.
  ///
  /// Fades out after 2 seconds of inactivity; restored on tap.
  bool get isChromeVisible => _isChromeVisible;

  /// Total number of pages in the loaded notation.
  ///
  /// Returns `0` when the state is not [NotationPlayerStateSuccess].
  int get pageCount => switch (_state) {
        NotationPlayerStateSuccess(:final detail) => detail.pages.length,
        _ => 0,
      };

  // -------------------------------------------------------------------------
  // Load
  // -------------------------------------------------------------------------

  /// Loads the notation identified by [notationId] and transitions state.
  ///
  /// Transitions to [NotationPlayerStateLoading] while in flight, then to
  /// [NotationPlayerStateSuccess], [NotationPlayerStateNotFound] (when the
  /// repository returns null), or [NotationPlayerStateError] on exception.
  ///
  /// On success also calls [NotationRepository.updatePlayCount]; a failure
  /// there is logged but does not affect the main state.
  Future<void> loadNotation() async {
    _state = const NotationPlayerStateLoading();
    notifyListeners();

    try {
      final detail = await _repository.loadNotation(notationId);
      if (detail == null) {
        _state = const NotationPlayerStateNotFound();
        notifyListeners();
        return;
      }

      _state = NotationPlayerStateSuccess(detail: detail);
      notifyListeners();

      // Record the play — failure must not disrupt the success state.
      try {
        await _repository.updatePlayCount(notationId);
      } on Exception catch (e, st) {
        log(
          'NotationPlayerViewModel: updatePlayCount failed — $e',
          name: 'NotationPlayerViewModel',
          error: e,
          stackTrace: st,
        );
      }
    } on Exception catch (e, st) {
      log(
        'NotationPlayerViewModel: loadNotation failed — $e',
        name: 'NotationPlayerViewModel',
        error: e,
        stackTrace: st,
      );
      _state = NotationPlayerStateError(message: e.toString());
      notifyListeners();
    }
  }

  // -------------------------------------------------------------------------
  // Page navigation
  // -------------------------------------------------------------------------

  /// Navigates to [page], clamping to [0, pageCount - 1].
  ///
  /// Does nothing when [pageCount] is 0 (no notation loaded). Notifies
  /// listeners after updating [currentPage].
  ///
  /// Parameters:
  /// - [page]: The 0-indexed page index to navigate to.
  void goToPage(int page) {
    final count = pageCount;
    if (count == 0) return;
    final clamped = page.clamp(0, count - 1);
    if (_currentPage == clamped) return;
    _currentPage = clamped;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Chrome visibility
  // -------------------------------------------------------------------------

  /// Shows the title bar and bottom toolbar, then notifies listeners.
  void showChrome() {
    _isChromeVisible = true;
    notifyListeners();
  }

  /// Hides the title bar and bottom toolbar, then notifies listeners.
  void hideChrome() {
    _isChromeVisible = false;
    notifyListeners();
  }
}
