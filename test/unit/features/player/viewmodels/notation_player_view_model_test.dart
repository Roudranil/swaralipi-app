// Unit tests for NotationPlayerViewModel.
//
// Covers:
//   loadNotation  → loading / success / notFound / error
//   pageCount     → derived from loaded pages
//   currentPage   → initial value matches startPage; goToPage bounds-checks
//   recordPlay    → delegates to NotationRepository.updatePlayCount
//   chrome fade   → chromeFadeTimer fires; isChromVisible toggles

import 'dart:async';

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
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  NotationDetail? _detail;
  Object? _loadError;
  Object? _updatePlayCountError;

  final List<String> updatedPlayCountIds = [];

  void setDetail(NotationDetail? d) => _detail = d;
  void setLoadError(Object? e) => _loadError = e;
  void setUpdatePlayCountError(Object? e) => _updatePlayCountError = e;

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    if (_loadError != null) throw _loadError!;
    return _detail;
  }

  @override
  Future<void> updatePlayCount(String id) async {
    if (_updatePlayCountError != null) throw _updatePlayCountError!;
    updatedPlayCountIds.add(id);
  }

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

Notation _makeNotation(String id) => Notation(
      id: id,
      title: 'Test Notation',
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

NotationDetail _makeDetail(String id, int pageCount) => NotationDetail(
      notation: _makeNotation(id),
      pages: List.generate(pageCount, (i) => _makePage(id, i)),
      tags: const <Tag>[],
      customFieldValues: const <CustomFieldValue>[],
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
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('state is idle before loadNotation is called', () {
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.state, isA<NotationPlayerStateIdle>());
    });

    test('isChromVisible is true initially', () {
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.isChromeVisible, isTrue);
    });

    test('currentPage equals startPage parameter', () {
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
        startPage: 2,
      );
      expect(vm.currentPage, equals(2));
    });

    test('currentPage defaults to 0 when startPage not provided', () {
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.currentPage, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // loadNotation — success path
  // -------------------------------------------------------------------------

  group('loadNotation — success', () {
    test('transitions through loading to success', () async {
      repo.setDetail(_makeDetail('n1', 3));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      final states = <NotationPlayerState>[];
      vm.addListener(() => states.add(vm.state));

      await vm.loadNotation();

      expect(states.first, isA<NotationPlayerStateLoading>());
      expect(states.last, isA<NotationPlayerStateSuccess>());
    });

    test('success state contains correct detail', () async {
      final detail = _makeDetail('n1', 3);
      repo.setDetail(detail);
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      final success = vm.state as NotationPlayerStateSuccess;
      expect(success.detail.notation.id, equals('n1'));
      expect(success.detail.pages.length, equals(3));
    });

    test('pageCount returns number of pages after success', () async {
      repo.setDetail(_makeDetail('n1', 4));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      expect(vm.pageCount, equals(4));
    });

    test('calls updatePlayCount with notationId after success', () async {
      repo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      expect(repo.updatedPlayCountIds, contains('n1'));
    });
  });

  // -------------------------------------------------------------------------
  // loadNotation — notFound
  // -------------------------------------------------------------------------

  group('loadNotation — notFound', () {
    test('transitions to notFound when repository returns null', () async {
      repo.setDetail(null);
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'missing',
      );

      await vm.loadNotation();

      expect(vm.state, isA<NotationPlayerStateNotFound>());
    });

    test('does not call updatePlayCount when not found', () async {
      repo.setDetail(null);
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'missing',
      );

      await vm.loadNotation();

      expect(repo.updatedPlayCountIds, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // loadNotation — error
  // -------------------------------------------------------------------------

  group('loadNotation — error', () {
    test('transitions to error state on exception', () async {
      repo.setLoadError(Exception('db error'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      expect(vm.state, isA<NotationPlayerStateError>());
    });

    test('error message is propagated', () async {
      repo.setLoadError(Exception('db error'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      final error = vm.state as NotationPlayerStateError;
      expect(error.message, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // pageCount
  // -------------------------------------------------------------------------

  group('pageCount', () {
    test('returns 0 before load', () {
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      expect(vm.pageCount, equals(0));
    });

    test('returns 0 in error state', () async {
      repo.setLoadError(Exception('err'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      expect(vm.pageCount, equals(0));
    });
  });

  // -------------------------------------------------------------------------
  // goToPage
  // -------------------------------------------------------------------------

  group('goToPage', () {
    test('updates currentPage to valid index', () async {
      repo.setDetail(_makeDetail('n1', 5));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      vm.goToPage(3);

      expect(vm.currentPage, equals(3));
    });

    test('clamps negative index to 0', () async {
      repo.setDetail(_makeDetail('n1', 5));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      vm.goToPage(-1);

      expect(vm.currentPage, equals(0));
    });

    test('clamps out-of-bounds index to last page', () async {
      repo.setDetail(_makeDetail('n1', 5));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      vm.goToPage(10);

      expect(vm.currentPage, equals(4));
    });

    test('notifies listeners on page change', () async {
      repo.setDetail(_makeDetail('n1', 3));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      var notified = false;
      vm.addListener(() => notified = true);
      vm.goToPage(2);

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Chrome visibility
  // -------------------------------------------------------------------------

  group('chrome visibility', () {
    test('showChrome sets isChromeVisible to true and notifies', () async {
      repo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      var notified = false;
      vm.addListener(() => notified = true);
      vm.showChrome();

      expect(vm.isChromeVisible, isTrue);
      expect(notified, isTrue);
    });

    test('hideChrome sets isChromeVisible to false and notifies', () async {
      repo.setDetail(_makeDetail('n1', 2));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );
      await vm.loadNotation();

      var notified = false;
      vm.addListener(() => notified = true);
      vm.hideChrome();

      expect(vm.isChromeVisible, isFalse);
      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // updatePlayCount error is silently logged
  // -------------------------------------------------------------------------

  group('updatePlayCount error handling', () {
    test('does not transition to error state when updatePlayCount fails',
        () async {
      repo.setDetail(_makeDetail('n1', 2));
      repo.setUpdatePlayCountError(Exception('update failed'));
      final vm = NotationPlayerViewModel(
        repo,
        preferencesRepository: prefsRepo,
        notationId: 'n1',
      );

      await vm.loadNotation();

      // The main state should still be success despite play count failure.
      expect(vm.state, isA<NotationPlayerStateSuccess>());
    });
  });
}
