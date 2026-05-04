// Unit tests for LibraryViewModel — recently-played stream state.
//
// Covers:
//   - recentlyPlayedState starts idle
//   - transitions to success when watchRecentlyPlayed emits
//   - transitions to empty list correctly
//   - stream error does not crash the ViewModel

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  final _activeController = StreamController<List<Notation>>.broadcast();
  final _recentController = StreamController<List<Notation>>.broadcast();

  void emitActive(List<Notation> list) => _activeController.add(list);
  void emitRecent(List<Notation> list) => _recentController.add(list);
  void emitRecentError(Object e) => _recentController.addError(e);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      _activeController.stream;

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      _recentController.stream;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) =>
      throw UnimplementedError();

  @override
  Future<NotationDetail?> loadNotation(String id) async => null;

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}

  void close() {
    _activeController.close();
    _recentController.close();
  }
}

class FakeTrashRepository implements TrashRepository {
  @override
  Future<void> restoreNotation(String id) async {}

  @override
  Stream<List<Notation>> watchTrashedNotations() => const Stream.empty();

  @override
  Future<void> purgeNotation(String id) async {}

  @override
  Future<void> purgeAll() async {}

  @override
  Future<int> autoPurgeExpired() async => 0;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation(String id, {String? lastPlayedAt}) => Notation(
      id: id,
      title: 'Song $id',
      artists: const [],
      languages: const [],
      notes: '',
      playCount: lastPlayedAt != null ? 1 : 0,
      lastPlayedAt: lastPlayedAt,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository notationRepo;
  late FakeTrashRepository trashRepo;
  late LibraryViewModel vm;

  setUp(() {
    notationRepo = FakeNotationRepository();
    trashRepo = FakeTrashRepository();
    vm = LibraryViewModel(notationRepo, trashRepo);
  });

  tearDown(() {
    vm.dispose();
    notationRepo.close();
  });

  group('recentlyPlayedState', () {
    test('starts as RecentlyPlayedStateIdle before init', () {
      expect(vm.recentlyPlayedState, isA<RecentlyPlayedStateIdle>());
    });

    test('transitions to success when stream emits notations', () async {
      final notations = [
        _makeNotation('1', lastPlayedAt: '2024-01-03T00:00:00Z'),
        _makeNotation('2', lastPlayedAt: '2024-01-02T00:00:00Z'),
      ];

      vm.init();
      notationRepo.emitActive([]);
      notationRepo.emitRecent(notations);
      await Future<void>.delayed(Duration.zero);

      expect(vm.recentlyPlayedState, isA<RecentlyPlayedStateSuccess>());
      final success = vm.recentlyPlayedState as RecentlyPlayedStateSuccess;
      expect(success.notations, hasLength(2));
      expect(success.notations.first.id, '1');
    });

    test('transitions to success with empty list', () async {
      vm.init();
      notationRepo.emitActive([]);
      notationRepo.emitRecent([]);
      await Future<void>.delayed(Duration.zero);

      expect(vm.recentlyPlayedState, isA<RecentlyPlayedStateSuccess>());
      final success = vm.recentlyPlayedState as RecentlyPlayedStateSuccess;
      expect(success.notations, isEmpty);
    });

    test('stream error does not overwrite main state or crash', () async {
      vm.init();
      notationRepo.emitActive([]);
      notationRepo.emitRecentError(Exception('recent error'));
      await Future<void>.delayed(Duration.zero);

      // Main state should still be success (or whatever it was)
      expect(vm.recentlyPlayedState, isA<RecentlyPlayedStateIdle>());
    });

    test('notifies listeners when recently-played stream emits', () async {
      var callCount = 0;
      vm.addListener(() => callCount++);

      vm.init();
      final beforeInit = callCount;

      notationRepo.emitActive([]);
      notationRepo.emitRecent([
        _makeNotation('1', lastPlayedAt: '2024-01-01T00:00:00Z'),
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(callCount, greaterThan(beforeInit));
    });

    test('re-calling init resets recentlyPlayedState to idle', () async {
      vm.init();
      notationRepo.emitRecent([
        _makeNotation('1', lastPlayedAt: '2024-01-01T00:00:00Z'),
      ]);
      await Future<void>.delayed(Duration.zero);

      vm.init();
      expect(vm.recentlyPlayedState, isA<RecentlyPlayedStateIdle>());
    });
  });
}
