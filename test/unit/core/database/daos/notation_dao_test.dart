// Unit tests for NotationDao.
//
// Covers all nine public methods against an in-memory Drift database:
//   insertNotation, updateNotation, deleteNotation, getNotationById,
//   watchAllActive, watchDeleted, softDelete, restore, updatePlayCount.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal [NotationsTableCompanion] and returns its id.
Future<String> _insertNotation(
  AppDatabase db, {
  required String id,
  String title = 'Yaman Kalyan',
  String? deletedAt,
}) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: title,
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
          deletedAt: Value(deletedAt),
        ),
      );
  return id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotationDao.insertNotation', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
    });
    tearDown(() => db.close());

    test('inserts a notation and it is retrievable via select', () async {
      final companion = NotationsTableCompanion.insert(
        id: 'n1',
        title: 'Bhairav',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );

      await dao.insertNotation(companion);

      final rows = await db.select(db.notationsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'n1');
      expect(rows.first.title, 'Bhairav');
    });

    test('duplicate id throws', () async {
      final companion = NotationsTableCompanion.insert(
        id: 'n-dup',
        title: 'First',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );
      await dao.insertNotation(companion);

      expect(
        () => dao.insertNotation(companion),
        throwsA(anything),
      );
    });
  });

  group('NotationDao.updateNotation', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1', title: 'Original');
    });
    tearDown(() => db.close());

    test('updates the title of an existing notation', () async {
      final companion = NotationsTableCompanion(
        id: const Value('n1'),
        title: const Value('Updated Title'),
        updatedAt: Value(_ts('11:00:00')),
      );

      await dao.updateNotation(companion);

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('n1')))
          .getSingle();
      expect(row.title, 'Updated Title');
    });

    test('returns false for a non-existent id', () async {
      final companion = NotationsTableCompanion(
        id: const Value('does-not-exist'),
        title: const Value('Ghost'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateNotation(companion);
      expect(updated, isFalse);
    });
  });

  group('NotationDao.deleteNotation (hard delete)', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1');
    });
    tearDown(() => db.close());

    test('permanently removes a notation row', () async {
      await dao.deleteNotation('n1');

      final rows = await db.select(db.notationsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.deleteNotation('ghost');
    });
  });

  group('NotationDao.getNotationById', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1', title: 'Darbari');
    });
    tearDown(() => db.close());

    test('returns the row for a known id', () async {
      final row = await dao.getNotationById('n1');

      expect(row, isNotNull);
      expect(row!.id, 'n1');
      expect(row.title, 'Darbari');
    });

    test('returns null for an unknown id', () async {
      final row = await dao.getNotationById('missing');
      expect(row, isNull);
    });
  });

  group('NotationDao.watchAllActive', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
    });
    tearDown(() => db.close());

    test('emits only rows where deleted_at IS NULL', () async {
      await _insertNotation(db, id: 'active-1');
      await _insertNotation(db, id: 'active-2');
      await _insertNotation(
        db,
        id: 'deleted-1',
        deletedAt: _ts('08:00:00'),
      );

      final rows = await dao.watchAllActive().first;

      expect(rows.map((r) => r.id).toList(),
          containsAll(['active-1', 'active-2']));
      expect(rows.any((r) => r.id == 'deleted-1'), isFalse);
    });

    test('emits empty list when all notations are soft-deleted', () async {
      await _insertNotation(db, id: 'n1', deletedAt: _ts('08:00:00'));

      final rows = await dao.watchAllActive().first;
      expect(rows, isEmpty);
    });

    test('stream emits updated list after a new active notation is inserted',
        () async {
      final stream = dao.watchAllActive();

      // First emission — empty.
      expect(await stream.first, isEmpty);

      await _insertNotation(db, id: 'n1');

      // Second emission — one active row.
      final second = await dao.watchAllActive().first;
      expect(second, hasLength(1));
    });
  });

  group('NotationDao.watchDeleted', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
    });
    tearDown(() => db.close());

    test('emits only rows where deleted_at IS NOT NULL', () async {
      await _insertNotation(db, id: 'active-1');
      await _insertNotation(
        db,
        id: 'deleted-1',
        deletedAt: _ts('08:00:00'),
      );

      final rows = await dao.watchDeleted().first;

      expect(rows.map((r) => r.id).toList(), contains('deleted-1'));
      expect(rows.any((r) => r.id == 'active-1'), isFalse);
    });

    test('emits empty list when no notation is soft-deleted', () async {
      await _insertNotation(db, id: 'n1');

      final rows = await dao.watchDeleted().first;
      expect(rows, isEmpty);
    });
  });

  group('NotationDao.softDelete', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1');
    });
    tearDown(() => db.close());

    test('sets deleted_at to a non-null timestamp', () async {
      await dao.softDelete('n1');

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('n1')))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('row disappears from watchAllActive after soft delete', () async {
      await dao.softDelete('n1');

      final active = await dao.watchAllActive().first;
      expect(active.any((r) => r.id == 'n1'), isFalse);
    });

    test('row appears in watchDeleted after soft delete', () async {
      await dao.softDelete('n1');

      final deleted = await dao.watchDeleted().first;
      expect(deleted.any((r) => r.id == 'n1'), isTrue);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.softDelete('ghost');
    });
  });

  group('NotationDao.restore', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1', deletedAt: _ts('08:00:00'));
    });
    tearDown(() => db.close());

    test('clears deleted_at so the row is active again', () async {
      await dao.restore('n1');

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('n1')))
          .getSingle();
      expect(row.deletedAt, isNull);
    });

    test('restored row reappears in watchAllActive', () async {
      await dao.restore('n1');

      final active = await dao.watchAllActive().first;
      expect(active.any((r) => r.id == 'n1'), isTrue);
    });

    test('restored row disappears from watchDeleted', () async {
      await dao.restore('n1');

      final deleted = await dao.watchDeleted().first;
      expect(deleted.any((r) => r.id == 'n1'), isFalse);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.restore('ghost');
    });
  });

  group('NotationDao.updatePlayCount', () {
    late AppDatabase db;
    late NotationDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationDao(db);
      await _insertNotation(db, id: 'n1');
    });
    tearDown(() => db.close());

    test('increments play_count and sets last_played_at', () async {
      await dao.updatePlayCount('n1');

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('n1')))
          .getSingle();
      expect(row.playCount, 1);
      expect(row.lastPlayedAt, isNotNull);
    });

    test('each call increments play_count by one', () async {
      await dao.updatePlayCount('n1');
      await dao.updatePlayCount('n1');

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('n1')))
          .getSingle();
      expect(row.playCount, 2);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.updatePlayCount('ghost');
    });
  });
}
