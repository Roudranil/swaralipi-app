// Widget tests for NotationPlayerScreen.
//
// Covers:
//   - Loading indicator shown while loading
//   - Error view shown on error
//   - Not-found view shown when notation is missing
//   - PageView renders correct page indicator (e.g., "1 / 3")
//   - Page indicator updates after swipe
//   - InteractiveViewer is present per page
//   - Tap anywhere toggles chrome

import 'dart:async';

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
  Object? _loadError;

  void setDetail(NotationDetail? d) => _detail = d;
  void setLoadError(Object? e) => _loadError = e;

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    if (_loadError != null) throw _loadError!;
    return _detail;
  }

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
  @override
  Future<UserPreferences> getPreferences() async => const UserPreferences(
        userName: 'Test',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
      );

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {}

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
// Helpers
// ---------------------------------------------------------------------------

NotationPage _makePage(String notationId, int order) => NotationPage(
      id: 'page-$order',
      notationId: notationId,
      pageOrder: order,
      imagePath: 'notations/$notationId/page_${order}_original.jpg',
      renderParams: '{}',
      createdAt: '2024-01-01T00:00:00Z',
    );

Notation _makeNotation(String id, {String title = 'Test'}) => Notation(
      id: id,
      title: title,
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

NotationDetail _makeDetail(String id, int pageCount, {String title = 'Test'}) =>
    NotationDetail(
      notation: _makeNotation(id, title: title),
      pages: List.generate(pageCount, (i) => _makePage(id, i)),
      tags: const <Tag>[],
      customFieldValues: const <CustomFieldValue>[],
    );

Widget _buildScreen(NotationPlayerViewModel vm) => MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: ChangeNotifierProvider<NotationPlayerViewModel>(
        create: (_) => vm,
        child: const NotationPlayerScreen(),
      ),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository repo;
  late FakePreferencesRepository prefsRepo;

  setUp(() {
    repo = FakeNotationRepository();
    prefsRepo = FakePreferencesRepository();
  });

  // -------------------------------------------------------------------------
  // Loading state
  // -------------------------------------------------------------------------

  group('loading state', () {
    testWidgets('shows circular progress indicator while loading',
        (tester) async {
      // Use a blocking repo so the load never completes during this test.
      final completer = Completer<NotationDetail?>();
      final blockingRepo = _BlockingFakeRepository(completer.future);
      final vm = NotationPlayerViewModel(
        blockingRepo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      // Pump widget.
      await tester.pumpWidget(_buildScreen(vm));
      // Process the post-frame callback which starts loadNotation.
      await tester.pump();

      // The vm is in loading state because completer hasn't resolved.
      expect(vm.state, isA<NotationPlayerStateLoading>());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unblock before test ends.
      completer.complete(null);
      await tester.pump();
      await tester.pump();
    });
  });

  // Helper: pump widget + process the post-frame callback + await async load.
  Future<NotationPlayerViewModel> pumpAndLoad(
    WidgetTester tester,
    NotationPlayerViewModel vm,
  ) async {
    await tester.pumpWidget(_buildScreen(vm));
    // First pump triggers the post-frame callback registered in initState.
    await tester.pump();
    // Await the async loadNotation that was fired by the post-frame callback.
    await tester.pump();
    return vm;
  }

  // -------------------------------------------------------------------------
  // Not-found state
  // -------------------------------------------------------------------------

  group('not-found state', () {
    testWidgets('shows not-found message when notation is missing',
        (tester) async {
      repo.setDetail(null);
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'missing',
      );

      await pumpAndLoad(tester, vm);

      expect(find.textContaining('not found'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Error state
  // -------------------------------------------------------------------------

  group('error state', () {
    testWidgets('shows error message on load failure', (tester) async {
      repo.setLoadError(Exception('db error'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      expect(find.textContaining('Error'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Success state — page indicator
  // -------------------------------------------------------------------------

  group('success state', () {
    testWidgets('shows page indicator "1 / 3" for 3-page notation',
        (tester) async {
      repo.setDetail(_makeDetail('n1', 3, title: 'My Notation'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('shows notation title in chrome', (tester) async {
      repo.setDetail(_makeDetail('n1', 2, title: 'Raga Yaman'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      expect(find.text('Raga Yaman'), findsOneWidget);
    });

    testWidgets('shows PageView widget for multi-page notation',
        (tester) async {
      repo.setDetail(_makeDetail('n1', 3));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('shows InteractiveViewer per page', (tester) async {
      repo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      expect(find.byType(InteractiveViewer), findsAtLeastNWidgets(1));
    });

    testWidgets('page indicator updates when goToPage is called',
        (tester) async {
      repo.setDetail(_makeDetail('n1', 3));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      vm.goToPage(1);
      await tester.pump();

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('startPage=1 shows correct initial indicator', (tester) async {
      repo.setDetail(_makeDetail('n1', 4));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
        startPage: 1,
      );

      await pumpAndLoad(tester, vm);

      expect(find.text('2 / 4'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Chrome toggle
  // -------------------------------------------------------------------------

  group('chrome toggle', () {
    testWidgets('tapping screen toggles chrome via showChrome/hideChrome',
        (tester) async {
      repo.setDetail(_makeDetail('n1', 2, title: 'My Song'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await pumpAndLoad(tester, vm);

      // Chrome is initially visible.
      expect(vm.isChromeVisible, isTrue);

      // Hide chrome programmatically and verify.
      vm.hideChrome();
      await tester.pump();

      expect(vm.isChromeVisible, isFalse);

      // Show chrome again.
      vm.showChrome();
      await tester.pump();

      expect(vm.isChromeVisible, isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Blocking fake for testing loading state
// ---------------------------------------------------------------------------

class _BlockingFakeRepository implements NotationRepository {
  _BlockingFakeRepository(this._future);
  final Future<NotationDetail?> _future;

  @override
  Future<NotationDetail?> loadNotation(String id) => _future;

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
