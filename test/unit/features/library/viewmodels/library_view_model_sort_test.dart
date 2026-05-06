// Unit tests for LibraryViewModel sort behaviour.
//
// Covers:
//   - Default sort is LibrarySort.dateDesc
//   - setSort changes the sort value and notifies listeners
//   - setSort with the same value is a no-op (no extra notification)
//   - After setSort the ViewModel re-subscribes (new stream used)

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeNotationRepository implements NotationRepository {
  final _allActiveController = StreamController<List<Notation>>.broadcast();

  /// List of [NotationSortBy] values passed to successive [watchAllActive]
  /// calls — used to assert that re-subscription uses the updated sort.
  final List<NotationSortBy> watchAllActiveSortArgs = [];

  void emitAllActive(List<Notation> notations) =>
      _allActiveController.add(notations);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) {
    watchAllActiveSortArgs.add(sortBy);
    return _allActiveController.stream;
  }

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

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

  void close() => _allActiveController.close();
}

class _FakeTrashRepository implements TrashRepository {
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeNotationRepository notationRepo;
  late _FakeTrashRepository trashRepo;
  late LibraryViewModel vm;

  setUp(() {
    notationRepo = _FakeNotationRepository();
    trashRepo = _FakeTrashRepository();
    vm = LibraryViewModel(notationRepo, trashRepo);
  });

  tearDown(() {
    vm.dispose();
    notationRepo.close();
  });

  group('LibraryViewModel — default sort', () {
    test('initial sort is dateDesc', () {
      expect(vm.sort, LibrarySort.dateDesc);
    });
  });

  group('LibraryViewModel — setSort', () {
    test('setSort changes sort value', () {
      vm.setSort(LibrarySort.titleAsc);
      expect(vm.sort, LibrarySort.titleAsc);
    });

    test('setSort notifies listeners', () {
      var notified = false;
      vm.addListener(() => notified = true);
      vm.setSort(LibrarySort.titleAsc);
      // setSort calls init() which immediately sets loading and notifies.
      expect(notified, isTrue);
    });

    test('setSort with same value does not re-subscribe', () {
      // Call init once to baseline the count.
      vm.init();
      final countBefore = notationRepo.watchAllActiveSortArgs.length;
      vm.setSort(LibrarySort.dateDesc); // same as default — no-op
      expect(
        notationRepo.watchAllActiveSortArgs.length,
        equals(countBefore),
        reason: 'setSort with same value must not re-subscribe',
      );
    });

    test('setSort re-subscribes with updated sort arg', () {
      vm.init(); // first subscription
      vm.setSort(LibrarySort.titleAsc); // triggers re-subscribe
      expect(
        notationRepo.watchAllActiveSortArgs,
        containsAll([
          NotationSortBy.dateDesc, // from init()
          NotationSortBy.titleAsc, // from setSort → init()
        ]),
      );
    });

    test('list reflects new sort after setSort emits', () async {
      final n1 = _makeNotation('1', title: 'Zara');
      final n2 = _makeNotation('2', title: 'Aarav');
      vm.init();
      notationRepo.emitAllActive([n1, n2]);
      await Future<void>.delayed(Duration.zero);
      // Now switch to title sort — caller is responsible for sorted data.
      vm.setSort(LibrarySort.titleAsc);
      notationRepo.emitAllActive([n2, n1]); // repo now emits title-sorted
      await Future<void>.delayed(Duration.zero);
      final state = vm.state;
      expect(state, isA<LibraryStateSuccess>());
      final notations = (state as LibraryStateSuccess).notations;
      expect(notations.first.title, 'Aarav');
    });
  });

  group('LibraryViewModel — sort enum coverage', () {
    test('setSort titleAsc updates sort field', () {
      vm.setSort(LibrarySort.titleAsc);
      expect(vm.sort, LibrarySort.titleAsc);
    });

    test('setSort titleDesc updates sort field', () {
      vm.setSort(LibrarySort.titleDesc);
      expect(vm.sort, LibrarySort.titleDesc);
    });

    test('setSort dateWrittenDesc updates sort field', () {
      vm.setSort(LibrarySort.dateWrittenDesc);
      expect(vm.sort, LibrarySort.dateWrittenDesc);
    });

    test('setSort dateWrittenAsc updates sort field', () {
      vm.setSort(LibrarySort.dateWrittenAsc);
      expect(vm.sort, LibrarySort.dateWrittenAsc);
    });

    test('setSort dateAsc updates sort field', () {
      vm.setSort(LibrarySort.dateAsc);
      expect(vm.sort, LibrarySort.dateAsc);
    });

    test('setSort playCountDesc updates sort field', () {
      vm.setSort(LibrarySort.playCountDesc);
      expect(vm.sort, LibrarySort.playCountDesc);
    });

    test('setSort playCountAsc updates sort field', () {
      vm.setSort(LibrarySort.playCountAsc);
      expect(vm.sort, LibrarySort.playCountAsc);
    });

    test('setSort lastPlayedDesc updates sort field', () {
      vm.setSort(LibrarySort.lastPlayedDesc);
      expect(vm.sort, LibrarySort.lastPlayedDesc);
    });

    test('setSort lastPlayedAsc updates sort field', () {
      vm.setSort(LibrarySort.lastPlayedAsc);
      expect(vm.sort, LibrarySort.lastPlayedAsc);
    });
  });
}
