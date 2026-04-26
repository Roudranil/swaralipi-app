// Unit tests for SearchService.
//
// Covers all branches of search() and reindexAll():
//   - Empty / whitespace-only query returns all active notation IDs ordered
//     by updated_at DESC
//   - Non-empty query delegates to FtsDao and returns notation IDs
//   - Prefix matching is forwarded correctly to FtsDao
//   - Pagination (limit / offset) is respected
//   - Consistent pages with no duplicates across page boundaries
//   - reindexAll() rebuilds the FTS index via AppDatabase.createFtsSchema
//
// FtsDao is tested end-to-end via AppDatabase.forTesting(), meaning these
// tests exercise the real SQLite FTS5 engine, matching the approach used in
// fts_dao_test.dart.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/fts_dao.dart';
import 'package:swaralipi/core/search/search_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal notation row and returns its id.
Future<String> _insertNotation(
  AppDatabase db, {
  required String id,
  String title = 'Yaman Kalyan',
  String artists = '["Ravi Shankar"]',
  String notes = '',
  String updatedAt = '10:00:00',
  String? deletedAt,
}) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: title,
          artists: Value(artists),
          notes: Value(notes),
          createdAt: _ts('09:00:00'),
          updatedAt: _ts(updatedAt),
          deletedAt: Value(deletedAt),
        ),
      );
  return id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SearchService.search — empty query', () {
    late AppDatabase db;
    late SearchService service;

    setUp(() async {
      db = AppDatabase.forTesting();
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
      service = SearchService(db: db, ftsDao: FtsDao(db));
    });
    tearDown(() => db.close());

    test('returns empty list when database has no notations', () async {
      final ids = await service.search('');
      expect(ids, isEmpty);
    });

    test('returns all active notation IDs for empty query', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');
      await _insertNotation(db, id: 'n2', title: 'Yaman');

      final ids = await service.search('');
      expect(ids, containsAll(['n1', 'n2']));
      expect(ids, hasLength(2));
    });

    test('whitespace-only query is treated as empty and returns all active',
        () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');

      final ids = await service.search('   ');
      expect(ids, equals(['n1']));
    });

    test('empty query excludes soft-deleted notations', () async {
      await _insertNotation(db, id: 'n1', title: 'Active Raag');
      await _insertNotation(
        db,
        id: 'n2',
        title: 'Deleted Raag',
        deletedAt: '11:00:00',
      );

      final ids = await service.search('');
      expect(ids, equals(['n1']));
    });

    test(
        'empty query returns IDs ordered by updated_at DESC '
        '(most-recently updated first)', () async {
      await _insertNotation(db, id: 'n1', updatedAt: '10:00:00');
      await _insertNotation(db, id: 'n2', updatedAt: '12:00:00');
      await _insertNotation(db, id: 'n3', updatedAt: '11:00:00');

      final ids = await service.search('');

      expect(ids, equals(['n2', 'n3', 'n1']));
    });

    test('empty query with limit restricts number of returned IDs', () async {
      for (var i = 0; i < 5; i++) {
        await _insertNotation(db, id: 'n$i', title: 'Raag $i');
      }

      final ids = await service.search('', limit: 3);
      expect(ids, hasLength(3));
    });

    test('empty query with offset skips leading results', () async {
      // Insert with distinct updatedAt so ordering is deterministic.
      for (var i = 0; i < 5; i++) {
        await _insertNotation(
          db,
          id: 'n$i',
          updatedAt: '${10 + i}:00:00',
        );
      }

      final all = await service.search('');
      final paged = await service.search('', limit: 5, offset: 2);

      expect(paged, equals(all.sublist(2)));
    });

    test('empty query pages are non-overlapping', () async {
      for (var i = 0; i < 6; i++) {
        await _insertNotation(
          db,
          id: 'n$i',
          updatedAt: '${10 + i}:00:00',
        );
      }

      final page1 = await service.search('', limit: 3, offset: 0);
      final page2 = await service.search('', limit: 3, offset: 3);

      expect(page1.toSet().intersection(page2.toSet()), isEmpty);
      expect(<String>{...page1, ...page2}, hasLength(6));
    });
  });

  group('SearchService.search — non-empty query', () {
    late AppDatabase db;
    late SearchService service;

    setUp(() async {
      db = AppDatabase.forTesting();
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
      service = SearchService(db: db, ftsDao: FtsDao(db));
    });
    tearDown(() => db.close());

    test('returns matching notation ID by title', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairavi Raag');

      final ids = await service.search('Bhairavi');
      expect(ids, equals(['n1']));
    });

    test('prefix matching: "Bhai" matches notation titled "Bhairavi"',
        () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairavi Raag');

      final ids = await service.search('Bhai');
      expect(ids, contains('n1'));
    });

    test('returns only IDs (strings), not full rows', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairavi');

      final ids = await service.search('Bhai');
      expect(ids, isA<List<String>>());
    });

    test('returns empty list when no notation matches', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');

      final ids = await service.search('Todi');
      expect(ids, isEmpty);
    });

    test('excludes soft-deleted notations', () async {
      await _insertNotation(db, id: 'n1', title: 'Raag Active');
      await _insertNotation(
        db,
        id: 'n2',
        title: 'Raag Deleted',
        deletedAt: '11:00:00',
      );

      final ids = await service.search('Raag');
      expect(ids, equals(['n1']));
    });

    test('limit restricts the number of returned IDs', () async {
      for (var i = 0; i < 5; i++) {
        await _insertNotation(db, id: 'n$i', title: 'Raag Number $i');
      }

      final ids = await service.search('Raag', limit: 3);
      expect(ids, hasLength(3));
    });

    test('offset skips leading results', () async {
      for (var i = 0; i < 5; i++) {
        await _insertNotation(db, id: 'n$i', title: 'Raag Number $i');
      }

      final all = await service.search('Raag', limit: 5, offset: 0);
      final paged = await service.search('Raag', limit: 5, offset: 2);

      expect(paged, hasLength(all.length - 2));
      expect(paged.first, equals(all[2]));
    });

    test('paginated results have no duplicates across pages', () async {
      for (var i = 0; i < 6; i++) {
        await _insertNotation(db, id: 'n$i', title: 'Raag Item $i');
      }

      final page1 = await service.search('Raag', limit: 3, offset: 0);
      final page2 = await service.search('Raag', limit: 3, offset: 3);

      expect(page1.toSet().intersection(page2.toSet()), isEmpty);
      expect(<String>{...page1, ...page2}, hasLength(6));
    });

    test('matches by artists field', () async {
      await _insertNotation(
        db,
        id: 'n1',
        title: 'Morning Raga',
        artists: '["Bismillah Khan"]',
      );

      final ids = await service.search('Bismil');
      expect(ids, contains('n1'));
    });

    test('matches by notes field', () async {
      await _insertNotation(
        db,
        id: 'n1',
        title: 'Evening Raga',
        notes: 'Monsoon season composition',
      );

      final ids = await service.search('Monsoon');
      expect(ids, contains('n1'));
    });
  });

  group('SearchService.reindexAll', () {
    late AppDatabase db;
    late SearchService service;

    setUp(() async {
      db = AppDatabase.forTesting();
      await db.customSelect('SELECT 1').getSingle();
      await db.createFtsSchema();
      service = SearchService(db: db, ftsDao: FtsDao(db));
    });
    tearDown(() => db.close());

    test('reindexAll completes without throwing', () async {
      await _insertNotation(db, id: 'n1', title: 'Bhairav');
      await expectLater(service.reindexAll(), completes);
    });

    test('after reindexAll, existing notations are still findable via search',
        () async {
      await _insertNotation(db, id: 'n1', title: 'Darbari Kanada');

      await service.reindexAll();

      final ids = await service.search('Darbari');
      expect(ids, contains('n1'));
    });

    test('after reindexAll, notations inserted after the rebuild are findable',
        () async {
      // Insert a row before reindex.
      await _insertNotation(db, id: 'n1', title: 'Puriya Dhanashri');

      await service.reindexAll();

      // Insert a row after reindex.
      await _insertNotation(db, id: 'n2', title: 'Bhimpalasi');

      final ids = await service.search('Bhimpal');
      expect(ids, contains('n2'));
    });
  });
}
