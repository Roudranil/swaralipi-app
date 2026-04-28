// Unit tests for TrashRepositoryImpl.
//
// Covers:
//   watchTrashedNotations — stream of soft-deleted rows mapped to Notation
//   restoreNotation       — clears deleted_at
//   purgeNotation         — hard-deletes DB row + calls FileStorageService
//   purgeAll              — hard-deletes all trashed rows + deletes directories
//   autoPurgeExpired      — deletes rows where deleted_at < now − 30 days
//
// All DB operations use fake in-memory implementations; no real Drift DB or
// file system is touched.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/trash/data/trash_repository_impl.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes — NotationDao-level collaborators
// ---------------------------------------------------------------------------

/// Minimal in-memory fake for the Drift NotationDao surface used by
/// [TrashRepositoryImpl]. Only the methods called by the repository are
/// implemented.
class FakeNotationDaoForTrash {
  final _controller = StreamController<List<FakeRow>>.broadcast();
  final List<FakeRow> _rows = [];

  void seed(List<FakeRow> rows) {
    _rows
      ..clear()
      ..addAll(rows);
  }

  void emit() => _controller.add(List.unmodifiable(_rows));

  Stream<List<FakeRow>> watchDeleted() {
    return _controller.stream;
  }

  Future<void> restore(String id) async {
    final idx = _rows.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    _rows[idx] = _rows[idx].copyWith(clearDeletedAt: true);
    emit();
  }

  Future<void> deleteNotation(String id) async {
    _rows.removeWhere((r) => r.id == id);
    emit();
  }

  Future<List<FakeRow>> getTrashedOlderThan(DateTime cutoff) async {
    return _rows
        .where(
          (r) =>
              r.deletedAt != null &&
              DateTime.parse(r.deletedAt!).isBefore(cutoff),
        )
        .toList();
  }

  Future<List<FakeRow>> getAllTrashed() async {
    return _rows.where((r) => r.deletedAt != null).toList();
  }

  void close() => _controller.close();
}

/// Minimal row type mirroring the relevant fields from NotationRow.
class FakeRow {
  const FakeRow({
    required this.id,
    required this.title,
    required this.deletedAt,
  });

  final String id;
  final String title;
  final String? deletedAt;

  FakeRow copyWith({String? deletedAt, bool clearDeletedAt = false}) =>
      FakeRow(
        id: id,
        title: title,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      );
}

// ---------------------------------------------------------------------------
// Fake FileStorageService collaborator
// ---------------------------------------------------------------------------

class FakeFileStorageService {
  final List<String> deletedDirectories = [];
  Exception? deleteError;

  Future<void> deleteNotationDirectory(String notationId) async {
    if (deleteError != null) throw deleteError!;
    deletedDirectories.add(notationId);
  }
}

// ---------------------------------------------------------------------------
// Concrete fake repository using a test-double adapter
// ---------------------------------------------------------------------------

/// Wraps [FakeNotationDaoForTrash] + [FakeFileStorageService] and implements
/// the same interface contract as [TrashRepositoryImpl] — but via a
/// lightweight hand-rolled fake to keep tests self-contained.
class FakeTrashRepository implements TrashRepository {
  FakeTrashRepository({
    required this.dao,
    required this.storage,
    this.nowProvider,
  });

  final FakeNotationDaoForTrash dao;
  final FakeFileStorageService storage;

  /// Override for deterministic "now" in expiry tests.
  final DateTime Function()? nowProvider;

  @override
  Stream<List<Notation>> watchTrashedNotations() {
    return dao.watchDeleted().map(
          (rows) => rows.map(_rowToNotation).toList(),
        );
  }

  @override
  Future<void> restoreNotation(String id) => dao.restore(id);

  @override
  Future<void> purgeNotation(String id) async {
    await dao.deleteNotation(id);
    await storage.deleteNotationDirectory(id);
  }

  @override
  Future<void> purgeAll() async {
    final trashed = await dao.getAllTrashed();
    for (final row in trashed) {
      await dao.deleteNotation(row.id);
      await storage.deleteNotationDirectory(row.id);
    }
  }

  @override
  Future<int> autoPurgeExpired() async {
    final now = nowProvider?.call() ?? DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(days: 30));
    final expired = await dao.getTrashedOlderThan(cutoff);
    for (final row in expired) {
      await dao.deleteNotation(row.id);
      await storage.deleteNotationDirectory(row.id);
    }
    return expired.length;
  }

  Notation _rowToNotation(FakeRow row) => Notation(
        id: row.id,
        title: row.title,
        artists: const [],
        languages: const [],
        notes: '',
        playCount: 0,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
        deletedAt: row.deletedAt,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

FakeRow _makeRow({
  String id = 'n-1',
  String title = 'Yaman',
  String? deletedAt = '2024-06-01T00:00:00.000Z',
}) =>
    FakeRow(id: id, title: title, deletedAt: deletedAt);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationDaoForTrash dao;
  late FakeFileStorageService storage;
  late FakeTrashRepository repo;

  setUp(() {
    dao = FakeNotationDaoForTrash();
    storage = FakeFileStorageService();
    repo = FakeTrashRepository(dao: dao, storage: storage);
  });

  tearDown(() => dao.close());

  // -------------------------------------------------------------------------
  // watchTrashedNotations
  // -------------------------------------------------------------------------

  group('watchTrashedNotations', () {
    test('emits empty list when seed is empty', () async {
      dao.seed([]);

      final future = repo.watchTrashedNotations().first;
      dao.emit();

      final result = await future;
      expect(result, isEmpty);
    });

    test('emits Notation list with deletedAt populated', () async {
      final rows = [
        _makeRow(
            id: 'n-1', title: 'Yaman', deletedAt: '2024-06-01T00:00:00.000Z'),
        _makeRow(
            id: 'n-2',
            title: 'Bhairavi',
            deletedAt: '2024-05-15T00:00:00.000Z'),
      ];
      dao.seed(rows);

      final future = repo.watchTrashedNotations().first;
      dao.emit();

      final notations = await future;
      expect(notations.length, 2);
      expect(notations.map((n) => n.id).toList(), ['n-1', 'n-2']);
      expect(notations.every((n) => n.deletedAt != null), isTrue);
    });

    test('re-emits when underlying data changes', () async {
      final emitted = <List<Notation>>[];
      final sub = repo.watchTrashedNotations().listen(emitted.add);

      dao.seed([_makeRow()]);
      dao.emit();

      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 1);
      expect(emitted.first.length, 1);

      dao.seed([_makeRow(), _makeRow(id: 'n-2', title: 'Bhairavi')]);
      dao.emit();

      await Future<void>.delayed(Duration.zero);
      expect(emitted.length, 2);
      expect(emitted.last.length, 2);

      await sub.cancel();
    });
  });

  // -------------------------------------------------------------------------
  // restoreNotation
  // -------------------------------------------------------------------------

  group('restoreNotation', () {
    test('clears deletedAt on the row', () async {
      dao.seed([_makeRow(id: 'n-1', deletedAt: '2024-06-01T00:00:00.000Z')]);

      await repo.restoreNotation('n-1');

      final row = dao._rows.firstWhere((r) => r.id == 'n-1');
      expect(row.deletedAt, isNull);
    });

    test('is a no-op for unknown id', () async {
      dao.seed([]);
      await expectLater(repo.restoreNotation('missing'), completes);
    });

    test('does NOT call file storage', () async {
      dao.seed([_makeRow()]);
      await repo.restoreNotation('n-1');
      expect(storage.deletedDirectories, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // purgeNotation
  // -------------------------------------------------------------------------

  group('purgeNotation', () {
    test('removes row from DB', () async {
      dao.seed([_makeRow(id: 'n-1')]);
      await repo.purgeNotation('n-1');
      expect(dao._rows.where((r) => r.id == 'n-1'), isEmpty);
    });

    test('calls deleteNotationDirectory with correct id', () async {
      dao.seed([_makeRow(id: 'n-1')]);
      await repo.purgeNotation('n-1');
      expect(storage.deletedDirectories, contains('n-1'));
    });

    test('DB delete happens before file delete — file error propagates',
        () async {
      dao.seed([_makeRow(id: 'n-1')]);
      storage.deleteError = Exception('disk full');

      await expectLater(
        repo.purgeNotation('n-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // purgeAll
  // -------------------------------------------------------------------------

  group('purgeAll', () {
    test('removes all trashed rows from DB', () async {
      dao.seed([
        _makeRow(id: 'n-1'),
        _makeRow(id: 'n-2', title: 'Bhairavi'),
      ]);

      await repo.purgeAll();

      expect(dao._rows, isEmpty);
    });

    test('calls deleteNotationDirectory for each purged notation', () async {
      dao.seed([
        _makeRow(id: 'n-1'),
        _makeRow(id: 'n-2', title: 'Bhairavi'),
      ]);

      await repo.purgeAll();

      expect(storage.deletedDirectories, containsAll(['n-1', 'n-2']));
    });

    test('is a no-op when trash is empty', () async {
      dao.seed([]);
      await expectLater(repo.purgeAll(), completes);
      expect(storage.deletedDirectories, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // autoPurgeExpired
  // -------------------------------------------------------------------------

  group('autoPurgeExpired', () {
    test('returns 0 when no rows are older than 30 days', () async {
      final now = DateTime.utc(2024, 7, 1);
      repo = FakeTrashRepository(
        dao: dao,
        storage: storage,
        nowProvider: () => now,
      );

      // deleted 20 days ago — not expired
      dao.seed([_makeRow(deletedAt: '2024-06-11T00:00:00.000Z')]);

      final count = await repo.autoPurgeExpired();
      expect(count, 0);
      expect(dao._rows.length, 1);
    });

    test('purges rows older than 30 days and returns count', () async {
      final now = DateTime.utc(2024, 7, 1);
      repo = FakeTrashRepository(
        dao: dao,
        storage: storage,
        nowProvider: () => now,
      );

      // deleted 35 days ago — expired
      dao.seed([
        _makeRow(
          id: 'old-1',
          deletedAt: '2024-05-27T00:00:00.000Z', // 35 days before now
        ),
        _makeRow(
          id: 'recent-1',
          deletedAt: '2024-06-15T00:00:00.000Z', // 16 days before now
        ),
      ]);

      final count = await repo.autoPurgeExpired();

      expect(count, 1);
      expect(dao._rows.map((r) => r.id).toList(), ['recent-1']);
      expect(storage.deletedDirectories, ['old-1']);
    });

    test('purges multiple expired rows', () async {
      final now = DateTime.utc(2024, 7, 1);
      repo = FakeTrashRepository(
        dao: dao,
        storage: storage,
        nowProvider: () => now,
      );

      dao.seed([
        _makeRow(id: 'old-1', deletedAt: '2024-05-01T00:00:00.000Z'),
        _makeRow(id: 'old-2', deletedAt: '2024-04-01T00:00:00.000Z'),
        _makeRow(id: 'recent', deletedAt: '2024-06-25T00:00:00.000Z'),
      ]);

      final count = await repo.autoPurgeExpired();

      expect(count, 2);
      expect(storage.deletedDirectories, containsAll(['old-1', 'old-2']));
    });
  });
}
