// Unit tests for FtsDao.
//
// Covers the FTS5 virtual table, triggers, and the search() method:
//   - INSERT trigger keeps FTS in sync
//   - DELETE trigger removes rows from FTS
//   - UPDATE trigger replaces old FTS entry with new one
//   - Soft-deleted notations are excluded from search results
//   - BM25-ranked prefix matching works correctly
//   - Empty query returns empty list
//   - Limit and offset are respected
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/fts_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal notation row directly into the table and returns its id.
Future<String> _insertNotation(
  AppDatabase db, {
  required String id,
  String title = 'Yaman Kalyan',
  String artists = '["Ravi Shankar"]',
  String notes = '',
  String? deletedAt,
}) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: title,
          artists: Value(artists),
          notes: Value(notes),
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
  group('FtsDao — INSERT trigger', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      // Force schema creation then set up FTS outside the migration zone.
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('newly inserted notation is findable by title prefix', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav Raag');

      final results = await dao.search('Bhai', limit: 10, offset: 0);

      expect(results, hasLength(1));
      expect(results.first.id, equals('n1'));
    });

    test('newly inserted notation is findable by artists prefix', () async {
      await _insertNotation(
        db,
        id: 'n1',
        title: 'Morning Raga',
        artists: '["Bismillah Khan"]',
      );

      final results = await dao.search('Bismil', limit: 10, offset: 0);

      expect(results, hasLength(1));
      expect(results.first.id, equals('n1'));
    });

    test('newly inserted notation is findable by notes prefix', () async {
      await _insertNotation(
        db,
        id: 'n1',
        title: 'Evening Raga',
        notes: 'Monsoon season composition',
      );

      final results = await dao.search('Monsoon', limit: 10, offset: 0);

      expect(results, hasLength(1));
      expect(results.first.id, equals('n1'));
    });
  });

  group('FtsDao — DELETE trigger', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('hard-deleted notation is no longer findable via FTS', () async {
      await _insertNotation(db, id: 'n1', title: 'Darbari Kanada');

      // Verify it was inserted and is findable.
      final before = await dao.search('Darbari', limit: 10, offset: 0);
      expect(before, hasLength(1));

      // Hard-delete the notation.
      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final after = await dao.search('Darbari', limit: 10, offset: 0);
      expect(after, isEmpty);
    });
  });

  group('FtsDao — UPDATE trigger', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('updated title is findable via new title and not old title', () async {
      await _insertNotation(db, id: 'n1', title: 'Old Title');

      // Update the title.
      await (db.update(db.notationsTable)..where((t) => t.id.equals('n1')))
          .write(
        NotationsTableCompanion(
          title: const Value('New Title'),
          updatedAt: Value(_ts('11:00:00')),
        ),
      );

      final byNew = await dao.search('New', limit: 10, offset: 0);
      expect(byNew, hasLength(1));
      expect(byNew.first.id, equals('n1'));

      final byOld = await dao.search('Old', limit: 10, offset: 0);
      expect(byOld, isEmpty);
    });
  });

  group('FtsDao — soft-delete filtering', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('soft-deleted notation is excluded from search results', () async {
      await _insertNotation(
        db,
        id: 'n1',
        title: 'Puriya Dhanashri',
        deletedAt: _ts('11:00:00'),
      );

      final results = await dao.search('Puriya', limit: 10, offset: 0);
      expect(results, isEmpty);
    });

    test(
        'active notation is returned while soft-deleted one with same '
        'keyword is excluded', () async {
      await _insertNotation(db, id: 'n1', title: 'Raag Yaman Active');
      await _insertNotation(
        db,
        id: 'n2',
        title: 'Raag Yaman Deleted',
        deletedAt: _ts('11:00:00'),
      );

      final results = await dao.search('Raag', limit: 10, offset: 0);
      expect(results, hasLength(1));
      expect(results.first.id, equals('n1'));
    });
  });

  group('FtsDao.search — query semantics', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('returns empty list when query matches no notation', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');

      final results = await dao.search('Todi', limit: 10, offset: 0);
      expect(results, isEmpty);
    });

    test('returns empty list when database has no notations', () async {
      final results = await dao.search('anything', limit: 10, offset: 0);
      expect(results, isEmpty);
    });

    test('prefix matching finds partial word matches', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhimpalasi Raag');

      final results = await dao.search('Bhimpal', limit: 10, offset: 0);
      expect(results, hasLength(1));
    });

    test('limit restricts number of returned rows', () async {
      for (var i = 0; i < 5; i++) {
        await _insertNotation(
          db,
          id: 'n$i',
          title: 'Raag Number $i',
        );
      }

      final results = await dao.search('Raag', limit: 3, offset: 0);
      expect(results, hasLength(3));
    });

    test('offset skips leading rows', () async {
      for (var i = 0; i < 5; i++) {
        await _insertNotation(
          db,
          id: 'n$i',
          title: 'Raag Number $i',
        );
      }

      final all = await dao.search('Raag', limit: 5, offset: 0);
      final paged = await dao.search('Raag', limit: 5, offset: 2);

      expect(paged, hasLength(all.length - 2));
      expect(paged.first.id, equals(all[2].id));
    });

    test('multiple notations matching same query are all returned', () async {
      await _insertNotation(db, id: 'n1', title: 'Raag Yaman');
      await _insertNotation(db, id: 'n2', title: 'Raag Bhairav');
      await _insertNotation(db, id: 'n3', title: 'Raag Todi');

      final results = await dao.search('Raag', limit: 10, offset: 0);
      expect(results, hasLength(3));
    });
  });

  group('FtsDao.search — empty or trivial query', () {
    late AppDatabase db;
    late FtsDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = FtsDao(db);
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
    });
    tearDown(() => db.close());

    test('empty string query returns empty list without throwing', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');

      final results = await dao.search('', limit: 10, offset: 0);
      expect(results, isEmpty);
    });

    test('whitespace-only query returns empty list without throwing', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');

      final results = await dao.search('   ', limit: 10, offset: 0);
      expect(results, isEmpty);
    });
  });
}
