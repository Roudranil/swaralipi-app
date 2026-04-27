// Unit tests for AppearanceViewModel.
//
// Covers all state transitions and methods using a
// FakePreferencesRepository:
//   init → idle / loading / success / error
//   setThemeMode → success and error paths
//   setColorSchemeMode → success and error paths
//   setSeedColor → success, null, and error paths
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/settings/viewmodels/appearance_view_model.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory [PreferencesRepository] fake for controlling state and errors.
class FakePreferencesRepository implements PreferencesRepository {
  UserPreferences _prefs = const UserPreferences(
    userName: 'Musician',
    themeMode: AppThemeMode.system,
    colorSchemeMode: ColorSchemeMode.catppuccin,
    defaultSort: SortOrder.createdAtDesc,
    defaultView: ViewMode.list,
  );

  Object? _getError;
  Object? _themeModeError;
  Object? _colorSchemeModeError;
  Object? _seedColorError;

  void setGetError(Object? error) => _getError = error;
  void setThemeModeError(Object? error) => _themeModeError = error;
  void setColorSchemeModeError(Object? error) => _colorSchemeModeError = error;
  void setSeedColorError(Object? error) => _seedColorError = error;

  @override
  Future<UserPreferences> getPreferences() async {
    if (_getError != null) throw _getError!;
    return _prefs;
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    _prefs = preferences;
  }

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {
    if (_themeModeError != null) throw _themeModeError!;
    _prefs = _prefs.copyWith(themeMode: mode);
  }

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {
    if (_colorSchemeModeError != null) throw _colorSchemeModeError!;
    _prefs = _prefs.copyWith(colorSchemeMode: mode);
  }

  @override
  Future<void> updateSeedColor(String? colorHex) async {
    if (_seedColorError != null) throw _seedColorError!;
    _prefs = _prefs.copyWith(seedColor: colorHex);
  }

  @override
  Future<void> updateTagsSeeded({required bool value}) async {
    _prefs = _prefs.copyWith(tagsSeeded: value);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Records all states emitted by [vm] during [action].
Future<List<AppearanceState>> collectStates(
  AppearanceViewModel vm,
  Future<void> Function() action,
) async {
  final states = <AppearanceState>[];
  void listener() => states.add(vm.state);
  vm.addListener(listener);
  await action();
  vm.removeListener(listener);
  return states;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('AppearanceViewModel.init', () {
    late FakePreferencesRepository repo;
    late AppearanceViewModel vm;

    setUp(() {
      repo = FakePreferencesRepository();
      vm = AppearanceViewModel(repo);
    });
    tearDown(() => vm.dispose());

    test('starts in idle state', () {
      expect(vm.state, isA<AppearanceStateIdle>());
    });

    test('transitions idle → loading → success on init', () async {
      final states = await collectStates(vm, vm.init);
      expect(states[0], isA<AppearanceStateLoading>());
      expect(states[1], isA<AppearanceStateSuccess>());
    });

    test('success state carries correct preferences', () async {
      await vm.init();
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.themeMode, AppThemeMode.system);
      expect(state.preferences.colorSchemeMode, ColorSchemeMode.catppuccin);
    });

    test('transitions idle → loading → error when getPreferences throws',
        () async {
      repo.setGetError(Exception('db error'));
      final states = await collectStates(vm, vm.init);
      expect(states[0], isA<AppearanceStateLoading>());
      expect(states[1], isA<AppearanceStateError>());
    });

    test('error state carries message when getPreferences throws', () async {
      repo.setGetError(Exception('db error'));
      await vm.init();
      final state = vm.state as AppearanceStateError;
      expect(state.message, isNotEmpty);
    });
  });

  group('AppearanceViewModel.setThemeMode', () {
    late FakePreferencesRepository repo;
    late AppearanceViewModel vm;

    setUp(() async {
      repo = FakePreferencesRepository();
      vm = AppearanceViewModel(repo);
      await vm.init();
    });
    tearDown(() => vm.dispose());

    test('light — updates preferences in success state', () async {
      await vm.setThemeMode(AppThemeMode.light);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.themeMode, AppThemeMode.light);
    });

    test('dark — updates preferences in success state', () async {
      await vm.setThemeMode(AppThemeMode.dark);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.themeMode, AppThemeMode.dark);
    });

    test('error — sets operationError field without replacing success state',
        () async {
      repo.setThemeModeError(Exception('write failed'));
      await vm.setThemeMode(AppThemeMode.light);
      expect(vm.state, isA<AppearanceStateSuccess>());
      expect(vm.operationError, isNotNull);
    });

    test('error — does not change themeMode in preferences', () async {
      repo.setThemeModeError(Exception('write failed'));
      await vm.setThemeMode(AppThemeMode.light);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.themeMode, AppThemeMode.system);
    });

    test('second call clears previous operationError', () async {
      repo.setThemeModeError(Exception('write failed'));
      await vm.setThemeMode(AppThemeMode.light);
      repo.setThemeModeError(null);
      await vm.setThemeMode(AppThemeMode.dark);
      expect(vm.operationError, isNull);
    });
  });

  group('AppearanceViewModel.setColorSchemeMode', () {
    late FakePreferencesRepository repo;
    late AppearanceViewModel vm;

    setUp(() async {
      repo = FakePreferencesRepository();
      vm = AppearanceViewModel(repo);
      await vm.init();
    });
    tearDown(() => vm.dispose());

    test('monet — updates preferences in success state', () async {
      await vm.setColorSchemeMode(ColorSchemeMode.monet);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.colorSchemeMode, ColorSchemeMode.monet);
    });

    test('catppuccin — updates preferences in success state', () async {
      await vm.setColorSchemeMode(ColorSchemeMode.monet);
      await vm.setColorSchemeMode(ColorSchemeMode.catppuccin);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.colorSchemeMode, ColorSchemeMode.catppuccin);
    });

    test('error — sets operationError without replacing success state',
        () async {
      repo.setColorSchemeModeError(Exception('write failed'));
      await vm.setColorSchemeMode(ColorSchemeMode.monet);
      expect(vm.state, isA<AppearanceStateSuccess>());
      expect(vm.operationError, isNotNull);
    });
  });

  group('AppearanceViewModel.setSeedColor', () {
    late FakePreferencesRepository repo;
    late AppearanceViewModel vm;

    setUp(() async {
      repo = FakePreferencesRepository();
      vm = AppearanceViewModel(repo);
      await vm.init();
    });
    tearDown(() => vm.dispose());

    test('hex — updates seedColor in preferences', () async {
      await vm.setSeedColor('#f38ba8');
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.seedColor, '#f38ba8');
    });

    test('null — clears seedColor in preferences', () async {
      await vm.setSeedColor('#f38ba8');
      await vm.setSeedColor(null);
      final state = vm.state as AppearanceStateSuccess;
      expect(state.preferences.seedColor, isNull);
    });

    test('error — sets operationError without replacing success state',
        () async {
      repo.setSeedColorError(Exception('write failed'));
      await vm.setSeedColor('#f38ba8');
      expect(vm.state, isA<AppearanceStateSuccess>());
      expect(vm.operationError, isNotNull);
    });
  });
}
