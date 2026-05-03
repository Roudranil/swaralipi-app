// NotationPlayerViewModel — ChangeNotifier for the full-screen notation player.
//
// Loads a [NotationDetail] via [NotationRepository.loadNotation], records the
// play-count on successful load via [NotationRepository.updatePlayCount], and
// exposes state as a sealed [NotationPlayerState] hierarchy.
//
// Also tracks the active page index, chrome-visibility flag, player-
// orientation lock, and auto-scroll state used by [NotationPlayerScreen].
//
// Construction:
//   NotationPlayerViewModel(
//     notationRepository,
//     preferencesRepository: prefsRepo,
//     notationId: id,
//     startPage: 0,    // optional, defaults to 0
//   )
//
// Lifecycle:
//   Call [loadNotation] once per navigation to the player screen.
//   Call [loadPersistedSpeed] after [loadNotation] to restore the saved speed.
//   Call [dispose] when the screen is removed from the tree (ChangeNotifier
//   lifecycle handles this automatically when used with ChangeNotifierProvider).

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// Public constants
// ---------------------------------------------------------------------------

/// Duration after which the chrome (title + toolbar) fades out.
///
/// Exposed as a top-level constant so widget tests can assert on it
/// without needing access to private state.
const Duration kChromeFadeDuration = Duration(seconds: 3);

/// Default auto-scroll speed multiplier.
///
/// Applied on first use and after factory reset of preferences.
const double kDefaultAutoScrollSpeed = 1.0;

/// Minimum auto-scroll speed multiplier (0.1×).
const double kMinAutoScrollSpeed = 0.1;

/// Maximum auto-scroll speed multiplier (3.0×).
const double kMaxAutoScrollSpeed = 3.0;

/// Tick interval for the auto-scroll [Timer.periodic] in milliseconds.
///
/// A 50 ms tick gives 20 updates per second — smooth enough for reading
/// without excessive battery drain.
const int kAutoScrollTickIntervalMs = 50;

/// The fraction of the viewport height scrolled per second at 1× speed.
///
/// At speed 1.0 and a viewport height of 800 px, the content scrolls at
/// `800 × kScrollViewportFractionPerSecond = 80` px/s.
const double kScrollViewportFractionPerSecond = 0.1;

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
/// per-page navigation state, chrome-visibility state, and orientation lock
/// used by the [NotationPlayerScreen].
///
/// State management contract:
/// - [state] drives the primary display state.
/// - [currentPage] is the 0-indexed currently-visible page.
/// - [isChromeVisible] controls whether the title bar and toolbar are shown.
/// - [playerOrientation] is the active screen orientation lock.
class NotationPlayerViewModel extends ChangeNotifier {
  /// Creates a [NotationPlayerViewModel].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for notation loading and play-count.
  /// - [preferencesRepository]: Persists the player orientation setting.
  /// - [notationId]: UUIDv4 of the notation to load.
  /// - [startPage]: 0-indexed page to open initially. Defaults to `0`.
  NotationPlayerViewModel(
    this._repository, {
    required PreferencesRepository preferencesRepository,
    required this.notationId,
    int startPage = 0,
  })  : _preferencesRepository = preferencesRepository,
        _currentPage = startPage;

  final NotationRepository _repository;
  final PreferencesRepository _preferencesRepository;

  /// UUIDv4 of the notation being displayed.
  final String notationId;

  NotationPlayerState _state = const NotationPlayerStateIdle();
  int _currentPage;
  bool _isChromeVisible = true;
  PlayerOrientation _playerOrientation = PlayerOrientation.auto;
  bool _autoScrollEnabled = false;
  double _autoScrollSpeed = kDefaultAutoScrollSpeed;

  // -------------------------------------------------------------------------
  // Public getters
  // -------------------------------------------------------------------------

  /// The current display state of the player screen.
  NotationPlayerState get state => _state;

  /// 0-indexed index of the currently-visible page.
  int get currentPage => _currentPage;

  /// Whether the title bar and bottom toolbar are visible.
  ///
  /// Fades out after [kChromeFadeDuration] of inactivity; restored on tap.
  bool get isChromeVisible => _isChromeVisible;

  /// The active screen orientation lock for the player.
  ///
  /// Defaults to [PlayerOrientation.auto].
  PlayerOrientation get playerOrientation => _playerOrientation;

  /// Total number of pages in the loaded notation.
  ///
  /// Returns `0` when the state is not [NotationPlayerStateSuccess].
  int get pageCount => switch (_state) {
        NotationPlayerStateSuccess(:final detail) => detail.pages.length,
        _ => 0,
      };

  /// Whether auto-scroll is currently active.
  bool get autoScrollEnabled => _autoScrollEnabled;

  /// The current auto-scroll speed multiplier.
  ///
  /// Always in the range [[kMinAutoScrollSpeed], [kMaxAutoScrollSpeed]].
  double get autoScrollSpeed => _autoScrollSpeed;

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

  // -------------------------------------------------------------------------
  // Orientation lock
  // -------------------------------------------------------------------------

  /// Sets the screen orientation lock to [orientation].
  ///
  /// Persists the new value to [PreferencesRepository.updatePlayerOrientation]
  /// and notifies listeners. Does nothing if [orientation] equals the current
  /// value.
  ///
  /// Parameters:
  /// - [orientation]: The new [PlayerOrientation] to apply.
  Future<void> setOrientation(PlayerOrientation orientation) async {
    if (_playerOrientation == orientation) return;
    _playerOrientation = orientation;
    notifyListeners();
    try {
      await _preferencesRepository.updatePlayerOrientation(orientation);
    } on Exception catch (e, st) {
      log(
        'NotationPlayerViewModel: updatePlayerOrientation failed — $e',
        name: 'NotationPlayerViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Cycles the orientation lock through auto → portrait → landscape → auto.
  ///
  /// Persists the new value via [setOrientation].
  Future<void> cycleOrientation() async {
    final next = switch (_playerOrientation) {
      PlayerOrientation.auto => PlayerOrientation.portrait,
      PlayerOrientation.portrait => PlayerOrientation.landscape,
      PlayerOrientation.landscape => PlayerOrientation.auto,
    };
    await setOrientation(next);
  }

  // -------------------------------------------------------------------------
  // Auto-scroll
  // -------------------------------------------------------------------------

  /// Toggles the auto-scroll feature on or off and notifies listeners.
  ///
  /// When enabled, the screen layer is responsible for starting the scroll
  /// timer. When disabled, the timer should be cancelled.
  void toggleAutoScroll() {
    _autoScrollEnabled = !_autoScrollEnabled;
    notifyListeners();
  }

  /// Disables auto-scroll and notifies listeners.
  ///
  /// Does nothing (no notification) when auto-scroll is already disabled.
  /// Called by the screen when a swipe gesture is detected.
  void stopAutoScroll() {
    if (!_autoScrollEnabled) return;
    _autoScrollEnabled = false;
    notifyListeners();
  }

  /// Updates the in-memory auto-scroll speed to [speed] without persisting.
  ///
  /// Intended for use during continuous slider drag so the ViewModel notifies
  /// on every frame without triggering a DB write. Call [setScrollSpeed] on
  /// drag end to persist the final value.
  ///
  /// The speed is clamped to [[kMinAutoScrollSpeed], [kMaxAutoScrollSpeed]].
  /// Does nothing (no notification) when the clamped value equals the current
  /// speed.
  ///
  /// Parameters:
  /// - [speed]: The desired speed multiplier before clamping.
  void updateScrollSpeedLocal(double speed) {
    final clamped = speed.clamp(kMinAutoScrollSpeed, kMaxAutoScrollSpeed);
    if (clamped == _autoScrollSpeed) return;
    _autoScrollSpeed = clamped;
    notifyListeners();
  }

  /// Sets the auto-scroll speed to [speed], clamped to
  /// [[kMinAutoScrollSpeed], [kMaxAutoScrollSpeed]], and persists the value.
  ///
  /// Does nothing (no notification) when the clamped value equals the
  /// current speed.
  ///
  /// Parameters:
  /// - [speed]: The desired speed multiplier before clamping.
  Future<void> setScrollSpeed(double speed) async {
    final clamped = speed.clamp(kMinAutoScrollSpeed, kMaxAutoScrollSpeed);
    if (clamped == _autoScrollSpeed) return;
    _autoScrollSpeed = clamped;
    notifyListeners();
    try {
      await _preferencesRepository.updateAutoScrollSpeed(clamped);
    } on Exception catch (e, st) {
      log(
        'NotationPlayerViewModel: updateAutoScrollSpeed failed — $e',
        name: 'NotationPlayerViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Loads the persisted auto-scroll speed from [PreferencesRepository] and
  /// applies it, notifying listeners.
  ///
  /// Should be called once after [loadNotation] completes. Failures are
  /// logged and silently ignored (the default speed is retained).
  Future<void> loadPersistedSpeed() async {
    try {
      final prefs = await _preferencesRepository.getPreferences();
      final clamped =
          prefs.autoScrollSpeed.clamp(kMinAutoScrollSpeed, kMaxAutoScrollSpeed);
      _autoScrollSpeed = clamped;
      notifyListeners();
    } on Exception catch (e, st) {
      log(
        'NotationPlayerViewModel: loadPersistedSpeed failed — $e',
        name: 'NotationPlayerViewModel',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Calculates the number of pixels to scroll per timer tick.
  ///
  /// The step is derived from [viewportHeight], [speed], and the
  /// [tickIntervalMs] so that at 1× speed the viewport scrolls at
  /// [kScrollViewportFractionPerSecond] of its height per second.
  ///
  /// Returns the computed pixel step as a [double].
  ///
  /// Parameters:
  /// - [speed]: Auto-scroll speed multiplier.
  /// - [viewportHeight]: The visible height of the scroll area in logical pixels.
  /// - [tickIntervalMs]: Timer tick interval in milliseconds.
  static double calculateScrollStep({
    required double speed,
    required double viewportHeight,
    required int tickIntervalMs,
  }) {
    final pixelsPerSecond =
        viewportHeight * kScrollViewportFractionPerSecond * speed;
    return pixelsPerSecond * tickIntervalMs / 1000.0;
  }
}
