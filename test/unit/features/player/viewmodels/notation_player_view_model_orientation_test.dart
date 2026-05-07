// Unit tests for orientation-lock and chrome-fade behaviour added to
// NotationPlayerViewModel in task #93.
//
// Covers:
//   playerOrientation    → initial value / setOrientation / persistence
//   chrome fade timer    → 3 s constant (not 2 s)
//   PreferencesRepository interaction → updatePlayerOrientation called on change

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/player/viewmodels/notation_player_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
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
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      const Stream.empty();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

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
  PlayerOrientation? lastSavedOrientation;
  UserPreferences _prefs = const UserPreferences(
    userName: 'Test',
    themeMode: AppThemeMode.system,
    colorSchemeMode: ColorSchemeMode.catppuccin,
    defaultSort: SortOrder.createdAtDesc,
    defaultView: ViewMode.list,
    playerOrientation: PlayerOrientation.auto,
  );

  @override
  Future<UserPreferences> getPreferences() async => _prefs;

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    _prefs = preferences;
  }

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {
    lastSavedOrientation = orientation;
    _prefs = _prefs.copyWith(playerOrientation: orientation);
  }

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {}

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {}

  @override
  Future<void> updateSeedColor(String? colorHex) async {}

  @override
  Future<void> updateAutoScrollSpeed(double speed) async {}

  @override
  Future<void> updateTagsSeeded({required bool value}) async {}

  @override
  Future<void> updateUserName(String name) async {
    _prefs = _prefs.copyWith(userName: name);
  }

  @override
  Stream<UserPreferences> watchPreferences() => Stream.value(_prefs);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NotationDetail _makeDetail(String id, int pageCount) => NotationDetail(
      notation: Notation(
        id: id,
        title: 'Test Notation',
        artists: const [],
        languages: const [],
        notes: '',
        playCount: 0,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
      ),
      pages: List.generate(
        pageCount,
        (i) => NotationPage(
          id: 'page-$i',
          notationId: id,
          pageOrder: i,
          imagePath: 'notations/$id/page_${i}_original.jpg',
          renderParams: '{}',
          createdAt: '2024-01-01T00:00:00Z',
        ),
      ),
      tags: const <Tag>[],
      customFieldValues: const <CustomFieldValue>[],
    );

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
  // Chrome fade duration constant
  // -------------------------------------------------------------------------

  group('chrome fade duration', () {
    test('_kChromeFadeDuration is 3 seconds', () {
      expect(
        kChromeFadeDuration,
        equals(const Duration(seconds: 3)),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Initial orientation state
  // -------------------------------------------------------------------------

  group('initial orientation', () {
    test('playerOrientation defaults to auto before load', () {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.playerOrientation, equals(PlayerOrientation.auto));
    });
  });

  // -------------------------------------------------------------------------
  // setOrientation
  // -------------------------------------------------------------------------

  group('setOrientation', () {
    test('updates playerOrientation to portrait', () async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setOrientation(PlayerOrientation.portrait);

      expect(vm.playerOrientation, equals(PlayerOrientation.portrait));
    });

    test('updates playerOrientation to landscape', () async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setOrientation(PlayerOrientation.landscape);

      expect(vm.playerOrientation, equals(PlayerOrientation.landscape));
    });

    test('notifies listeners when orientation changes', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.setOrientation(PlayerOrientation.portrait);

      expect(notified, isTrue);
    });

    test('persists orientation to PreferencesRepository', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.setOrientation(PlayerOrientation.landscape);

      expect(
        prefsRepo.lastSavedOrientation,
        equals(PlayerOrientation.landscape),
      );
    });

    test('does not notify when same orientation is set again', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.setOrientation(PlayerOrientation.portrait);

      var notified = false;
      vm.addListener(() => notified = true);

      await vm.setOrientation(PlayerOrientation.portrait);

      expect(notified, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Orientation cycle
  // -------------------------------------------------------------------------

  group('cycleOrientation', () {
    test('cycles auto → portrait → landscape → auto', () async {
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      expect(vm.playerOrientation, equals(PlayerOrientation.auto));

      await vm.cycleOrientation();
      expect(vm.playerOrientation, equals(PlayerOrientation.portrait));

      await vm.cycleOrientation();
      expect(vm.playerOrientation, equals(PlayerOrientation.landscape));

      await vm.cycleOrientation();
      expect(vm.playerOrientation, equals(PlayerOrientation.auto));
    });
  });

  // -------------------------------------------------------------------------
  // Orientation preserved across page swipes
  // -------------------------------------------------------------------------

  group('orientation preserved across page swipes', () {
    test('goToPage does not reset orientation', () async {
      notationRepo.setDetail(_makeDetail('n1', 3));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();
      await vm.setOrientation(PlayerOrientation.landscape);

      vm.goToPage(2);

      expect(vm.playerOrientation, equals(PlayerOrientation.landscape));
    });
  });
}
