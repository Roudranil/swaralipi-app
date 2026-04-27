// AppearanceViewModel — ChangeNotifier-based ViewModel for the Appearance
// settings screen.
//
// Loads [UserPreferences] via [PreferencesRepository] and exposes targeted
// write operations for theme mode, color scheme mode, and seed color. Each
// write persists to the repository and immediately rebuilds the in-memory
// state so the UI reflects the change without a round-trip read.
//
// State hierarchy:
//   AppearanceStateIdle       — before [init] is called
//   AppearanceStateLoading    — while [init] is awaiting the repository
//   AppearanceStateSuccess    — preferences loaded; targeted writes succeed
//   AppearanceStateError      — [init] failed; message carries the reason
//
// Per-operation write errors are surfaced via [operationError] without
// replacing the primary [state], so the UI remains usable while showing an
// error snackbar.
//
// Construction:
//   AppearanceViewModel(preferencesRepository)
//
// Lifecycle:
//   Call [init] once from the screen's initState/postFrameCallback.

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed state for [AppearanceViewModel].
///
/// Variants: [AppearanceStateIdle], [AppearanceStateLoading],
/// [AppearanceStateSuccess], [AppearanceStateError].
sealed class AppearanceState {
  /// Creates an [AppearanceState].
  const AppearanceState();
}

/// Initial state before [AppearanceViewModel.init] is called.
final class AppearanceStateIdle extends AppearanceState {
  /// Creates an [AppearanceStateIdle].
  const AppearanceStateIdle();
}

/// State while [AppearanceViewModel.init] is awaiting the repository.
final class AppearanceStateLoading extends AppearanceState {
  /// Creates an [AppearanceStateLoading].
  const AppearanceStateLoading();
}

/// State when preferences have been successfully loaded.
final class AppearanceStateSuccess extends AppearanceState {
  /// Creates an [AppearanceStateSuccess] with the given [preferences].
  ///
  /// Parameters:
  /// - [preferences]: The current user preferences.
  const AppearanceStateSuccess({required this.preferences});

  /// The current user preferences.
  final UserPreferences preferences;
}

/// State when [AppearanceViewModel.init] failed to load preferences.
final class AppearanceStateError extends AppearanceState {
  /// Creates an [AppearanceStateError] with the given [message].
  ///
  /// Parameters:
  /// - [message]: Human-readable description of the error.
  const AppearanceStateError({required this.message});

  /// Human-readable description of the load error.
  final String message;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ViewModel for the Appearance settings screen.
///
/// Loads [UserPreferences] on [init] and exposes targeted write operations
/// ([setThemeMode], [setColorSchemeMode], [setSeedColor]) that delegate to
/// [PreferencesRepository] and immediately update the in-memory state.
///
/// Write errors are isolated to [operationError]; [state] stays as
/// [AppearanceStateSuccess] so the rest of the screen remains interactive.
class AppearanceViewModel extends ChangeNotifier {
  /// Creates an [AppearanceViewModel] backed by [_repository].
  ///
  /// Parameters:
  /// - [_repository]: Source of truth for user preference persistence.
  AppearanceViewModel(this._repository);

  final PreferencesRepository _repository;

  AppearanceState _state = const AppearanceStateIdle();
  String? _operationError;

  /// The current display state of the Appearance screen.
  AppearanceState get state => _state;

  /// A non-null string when a write operation (theme mode, color scheme, seed
  /// color) failed. Cleared automatically on the next successful write.
  String? get operationError => _operationError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Loads preferences from the repository and transitions to
  /// [AppearanceStateSuccess] or [AppearanceStateError].
  ///
  /// Safe to call multiple times; each call re-fetches the current row.
  Future<void> init() async {
    _state = const AppearanceStateLoading();
    notifyListeners();

    try {
      final prefs = await _repository.getPreferences();
      _state = AppearanceStateSuccess(preferences: prefs);
    } on Exception catch (e, st) {
      log(
        'AppearanceViewModel.init failed: $e',
        name: 'AppearanceViewModel',
        error: e,
        stackTrace: st,
      );
      _state = AppearanceStateError(message: e.toString());
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Persists [mode] as the new theme mode and updates [state] optimistically.
  ///
  /// If the repository write fails, [operationError] is set and [state] is
  /// not changed.
  ///
  /// Parameters:
  /// - [mode]: The new [AppThemeMode] to apply.
  Future<void> setThemeMode(AppThemeMode mode) async {
    _operationError = null;
    final current = _currentPreferences;
    if (current == null) return;

    try {
      await _repository.updateThemeMode(mode);
      _state = AppearanceStateSuccess(
        preferences: current.copyWith(themeMode: mode),
      );
    } on Exception catch (e, st) {
      _operationError = e.toString();
      log(
        'AppearanceViewModel.setThemeMode failed: $e',
        name: 'AppearanceViewModel',
        error: e,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  /// Persists [mode] as the new color scheme mode and updates [state].
  ///
  /// If the repository write fails, [operationError] is set and [state] is
  /// not changed.
  ///
  /// Parameters:
  /// - [mode]: The new [ColorSchemeMode] to apply.
  Future<void> setColorSchemeMode(ColorSchemeMode mode) async {
    _operationError = null;
    final current = _currentPreferences;
    if (current == null) return;

    try {
      await _repository.updateColorSchemeMode(mode);
      _state = AppearanceStateSuccess(
        preferences: current.copyWith(colorSchemeMode: mode),
      );
    } on Exception catch (e, st) {
      _operationError = e.toString();
      log(
        'AppearanceViewModel.setColorSchemeMode failed: $e',
        name: 'AppearanceViewModel',
        error: e,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  /// Persists [colorHex] as the seed color and updates [state].
  ///
  /// Pass `null` to clear the seed color. If the repository write fails,
  /// [operationError] is set and [state] is not changed.
  ///
  /// Parameters:
  /// - [colorHex]: A Catppuccin hex string (e.g. `'#f38ba8'`), or `null`.
  Future<void> setSeedColor(String? colorHex) async {
    _operationError = null;
    final current = _currentPreferences;
    if (current == null) return;

    try {
      await _repository.updateSeedColor(colorHex);
      // copyWith(seedColor: null) won't clear the field because null is treated
      // as "absent". Construct a new preferences object directly to support
      // explicit null clearing.
      _state = AppearanceStateSuccess(
        preferences: UserPreferences(
          userName: current.userName,
          themeMode: current.themeMode,
          colorSchemeMode: current.colorSchemeMode,
          seedColor: colorHex,
          defaultSort: current.defaultSort,
          defaultView: current.defaultView,
          tagsSeeded: current.tagsSeeded,
        ),
      );
    } on Exception catch (e, st) {
      _operationError = e.toString();
      log(
        'AppearanceViewModel.setSeedColor failed: $e',
        name: 'AppearanceViewModel',
        error: e,
        stackTrace: st,
      );
    }
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Returns the current [UserPreferences] when in the success state, or
  /// `null` otherwise.
  UserPreferences? get _currentPreferences {
    final s = _state;
    return switch (s) {
      AppearanceStateSuccess(:final preferences) => preferences,
      _ => null,
    };
  }
}
