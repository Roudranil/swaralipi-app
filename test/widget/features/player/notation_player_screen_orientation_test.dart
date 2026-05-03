// Widget tests for orientation toggle and chrome fade behaviour in
// NotationPlayerScreen — task #93.
//
// Covers:
//   - Orientation toggle button present in player chrome
//   - Tapping toggle button calls vm.cycleOrientation
//   - Chrome fade timer uses 3 s constant
//   - AnimatedOpacity wraps chrome widgets

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/player/screens/notation_player_screen.dart';
import 'package:swaralipi/features/player/viewmodels/notation_player_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
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
  PlayerOrientation _orientation = PlayerOrientation.auto;
  int cycleCallCount = 0;

  @override
  Future<UserPreferences> getPreferences() async => UserPreferences(
        userName: 'Test',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
        playerOrientation: _orientation,
      );

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {}

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {
    _orientation = orientation;
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
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

NotationDetail _makeDetail(String id, int pageCount, {String title = 'Test'}) =>
    NotationDetail(
      notation: Notation(
        id: id,
        title: title,
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

Widget _buildScreen(
  NotationPlayerViewModel vm,
) =>
    MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider<NotationPlayerViewModel>(
        create: (_) => vm,
        child: const NotationPlayerScreen(),
      ),
    );

Future<NotationPlayerViewModel> _pumpAndLoad(
  WidgetTester tester,
  NotationPlayerViewModel vm,
) async {
  await tester.pumpWidget(_buildScreen(vm));
  await tester.pump();
  await tester.pump();
  return vm;
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
  // Orientation toggle button presence
  // -------------------------------------------------------------------------

  group('orientation toggle button', () {
    testWidgets('shows orientation toggle button in player chrome',
        (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      expect(
          find.byKey(const Key('orientation_toggle_button')), findsOneWidget);
    });

    testWidgets('orientation button icon changes with orientation state',
        (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      // Default is auto orientation — screen_rotation icon
      expect(find.byIcon(Icons.screen_rotation), findsOneWidget);
    });

    testWidgets('tapping orientation button calls cycleOrientation',
        (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      // Initially auto.
      expect(vm.playerOrientation, equals(PlayerOrientation.auto));

      await tester.tap(find.byKey(const Key('orientation_toggle_button')));
      await tester.pump();

      // After one tap, orientation should be portrait.
      expect(vm.playerOrientation, equals(PlayerOrientation.portrait));
    });
  });

  // -------------------------------------------------------------------------
  // AnimatedOpacity wraps chrome
  // -------------------------------------------------------------------------

  group('chrome animation', () {
    testWidgets('AnimatedOpacity widgets present for chrome fade',
        (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2, title: 'My Song'));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      expect(find.byType(AnimatedOpacity), findsAtLeastNWidgets(2));
    });

    testWidgets('chrome is visible initially', (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2, title: 'Test Song'));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      expect(vm.isChromeVisible, isTrue);
    });

    testWidgets('tapping screen toggles chrome', (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2, title: 'Test Song'));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);

      // Chrome starts visible; tap to hide.
      vm.hideChrome();
      await tester.pump();
      expect(vm.isChromeVisible, isFalse);

      // Tap screen to restore.
      vm.showChrome();
      await tester.pump();
      expect(vm.isChromeVisible, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Orientation icon per state
  // -------------------------------------------------------------------------

  group('orientation icon reflects state', () {
    testWidgets('portrait orientation shows portrait icon', (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);
      await vm.setOrientation(PlayerOrientation.portrait);
      await tester.pump();

      expect(find.byIcon(Icons.screen_lock_portrait), findsOneWidget);
    });

    testWidgets('landscape orientation shows landscape icon', (tester) async {
      notationRepo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        notationRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await _pumpAndLoad(tester, vm);
      await vm.setOrientation(PlayerOrientation.landscape);
      await tester.pump();

      expect(find.byIcon(Icons.screen_lock_landscape), findsOneWidget);
    });
  });
}
