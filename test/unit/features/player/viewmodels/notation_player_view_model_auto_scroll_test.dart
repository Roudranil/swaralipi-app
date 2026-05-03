// Unit tests for auto-scroll behaviour in NotationPlayerViewModel (#94).
//
// Covers:
//   autoScrollEnabled   → initial false; toggleAutoScroll flips it
//   autoScrollSpeed     → initial default; setScrollSpeed clamps to range
//   scroll step calc    → calculateScrollStep returns correct px/tick
//   persistence         → setScrollSpeed calls updateAutoScrollSpeed
//   loadPersistedSpeed  → speed loaded from repository on init
//   auto-scroll stops   → stopAutoScroll resets flag

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/player/viewmodels/notation_player_view_model.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  NotationDetail? _detail;

  void setDetail(NotationDetail? d) => _detail = d;

  @override
  Future<NotationDetail?> loadNotation(String id) async => _detail;

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> softDelete(String id) async => throw UnimplementedError();

  @override
  Stream<List<Notation>> watchAllActive() => const Stream.empty();

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async =>
      throw UnimplementedError();
}

class FakePreferencesRepository implements PreferencesRepository {
  double? lastSavedSpeed;
  bool updateAutoScrollSpeedCalled = false;

  UserPreferences _prefs = const UserPreferences(
    userName: 'Test',
    themeMode: AppThemeMode.system,
    colorSchemeMode: ColorSchemeMode.catppuccin,
    defaultSort: SortOrder.createdAtDesc,
    defaultView: ViewMode.list,
    autoScrollSpeed: kDefaultAutoScrollSpeed,
  );

  void setPrefs(UserPreferences prefs) => _prefs = prefs;

  @override
  Future<UserPreferences> getPreferences() async => _prefs;

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    _prefs = preferences;
  }

  @override
  Future<void> updateAutoScrollSpeed(double speed) async {
    updateAutoScrollSpeedCalled = true;
    lastSavedSpeed = speed;
    _prefs = _prefs.copyWith(autoScrollSpeed: speed);
  }

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {}

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {}

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {}

  @override
  Future<void> updateSeedColor(String? colorHex) async {}

  @override
  Future<void> updateTagsSeeded({required bool value}) async {}
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository notationRepo;
  late FakePreferencesRepository prefsRepo;

  setUp(() {
    notationRepo = FakeNotationRepository();
    prefsRepo = FakePreferencesRepository();
  });

  // -------------------------------------------------------------------------
  // Constants
  // -------------------------------------------------------------------------

  group('auto-scroll constants', () {
    test('kDefaultAutoScrollSpeed is within valid range', () {
      expect(
          kDefaultAutoScrollSpeed, greaterThanOrEqualTo(kMinAutoScrollSpeed));
      expect(kDefaultAutoScrollSpeed, lessThanOrEqualTo(kMaxAutoScrollSpeed));
    });

    test('kMinAutoScrollSpeed is 0.1', () {
      expect(kMinAutoScrollSpeed, closeTo(0.1, 0.001));
    });

    test('kMaxAutoScrollSpeed is 3.0', () {
      expect(kMaxAutoScrollSpeed, closeTo(3.0, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // Initial auto-scroll state
  // -------------------------------------------------------------------------

  group('initial auto-scroll state', () {
    test('autoScrollEnabled is false initially', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.autoScrollEnabled, isFalse);
    });

    test('autoScrollSpeed defaults to kDefaultAutoScrollSpeed', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.autoScrollSpeed, equals(kDefaultAutoScrollSpeed));
    });
  });

  // -------------------------------------------------------------------------
  // toggleAutoScroll
  // -------------------------------------------------------------------------

  group('toggleAutoScroll', () {
    test('enables auto-scroll when disabled', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      vm.toggleAutoScroll();

      expect(vm.autoScrollEnabled, isTrue);
    });

    test('disables auto-scroll when enabled', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      vm.toggleAutoScroll();

      vm.toggleAutoScroll();

      expect(vm.autoScrollEnabled, isFalse);
    });

    test('notifies listeners on toggle', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      var notified = false;
      vm.addListener(() => notified = true);
      vm.toggleAutoScroll();

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // setScrollSpeed
  // -------------------------------------------------------------------------

  group('setScrollSpeed', () {
    test('updates autoScrollSpeed to valid value', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setScrollSpeed(1.5);

      expect(vm.autoScrollSpeed, closeTo(1.5, 0.001));
    });

    test('clamps speed below kMinAutoScrollSpeed to minimum', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setScrollSpeed(0.0);

      expect(vm.autoScrollSpeed, closeTo(kMinAutoScrollSpeed, 0.001));
    });

    test('clamps speed above kMaxAutoScrollSpeed to maximum', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setScrollSpeed(10.0);

      expect(vm.autoScrollSpeed, closeTo(kMaxAutoScrollSpeed, 0.001));
    });

    test('notifies listeners when speed changes', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      var notified = false;
      vm.addListener(() => notified = true);
      await vm.setScrollSpeed(2.0);

      expect(notified, isTrue);
    });

    test('does not notify when same speed is set again', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.setScrollSpeed(1.5);

      var notified = false;
      vm.addListener(() => notified = true);
      await vm.setScrollSpeed(1.5);

      expect(notified, isFalse);
    });

    test('persists speed to PreferencesRepository', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setScrollSpeed(2.0);

      expect(prefsRepo.updateAutoScrollSpeedCalled, isTrue);
      expect(prefsRepo.lastSavedSpeed, closeTo(2.0, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // loadPersistedSpeed
  // -------------------------------------------------------------------------

  group('loadPersistedSpeed', () {
    test('loads persisted speed from repository', () async {
      prefsRepo.setPrefs(const UserPreferences(
        userName: 'Test',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
        autoScrollSpeed: 2.5,
      ));

      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadPersistedSpeed();

      expect(vm.autoScrollSpeed, closeTo(2.5, 0.001));
    });

    test('notifies listeners after loading persisted speed', () async {
      prefsRepo.setPrefs(const UserPreferences(
        userName: 'Test',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
        autoScrollSpeed: 1.8,
      ));

      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      var notified = false;
      vm.addListener(() => notified = true);
      await vm.loadPersistedSpeed();

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // stopAutoScroll
  // -------------------------------------------------------------------------

  group('stopAutoScroll', () {
    test('disables auto-scroll', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      vm.toggleAutoScroll(); // enable first

      vm.stopAutoScroll();

      expect(vm.autoScrollEnabled, isFalse);
    });

    test('notifies listeners when stopping', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      vm.toggleAutoScroll(); // enable first

      var notified = false;
      vm.addListener(() => notified = true);
      vm.stopAutoScroll();

      expect(notified, isTrue);
    });

    test('does nothing (no notification) when already disabled', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      var notified = false;
      vm.addListener(() => notified = true);
      vm.stopAutoScroll();

      expect(notified, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // calculateScrollStep
  // -------------------------------------------------------------------------

  group('calculateScrollStep', () {
    test('returns positive step for valid viewport and speed', () {
      final step = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 800.0,
        tickIntervalMs: 50,
      );
      expect(step, greaterThan(0));
    });

    test('step scales linearly with speed multiplier', () {
      final step1 = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 800.0,
        tickIntervalMs: 50,
      );
      final step2 = NotationPlayerViewModel.calculateScrollStep(
        speed: 2.0,
        viewportHeight: 800.0,
        tickIntervalMs: 50,
      );
      expect(step2, closeTo(step1 * 2.0, 0.001));
    });

    test('step scales with viewport height', () {
      final step400 = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 400.0,
        tickIntervalMs: 50,
      );
      final step800 = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 800.0,
        tickIntervalMs: 50,
      );
      expect(step800, greaterThan(step400));
    });

    test('step is smaller for shorter tick interval', () {
      final step50ms = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 800.0,
        tickIntervalMs: 50,
      );
      final step100ms = NotationPlayerViewModel.calculateScrollStep(
        speed: 1.0,
        viewportHeight: 800.0,
        tickIntervalMs: 100,
      );
      // 100ms tick fires half as often as 50ms, so each tick must move more
      expect(step100ms, greaterThan(step50ms));
    });
  });
}
