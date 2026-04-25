// Unit tests for NotationPageDao.
//
// Covers all five public methods against an in-memory Drift database:
//   insertPage, updatePage, deletePage, getPagesByNotationId,
//   deleteAllPagesForNotation.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/notation_page_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a parent notation row and returns its id.
Future<String> _insertParentNotation(AppDatabase db, String id) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: 'Parent Notation',
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
        ),
      );
  return id;
}

/// Inserts a notation page row.
Future<void> _insertPage(
  AppDatabase db, {
  required String id,
  required String notationId,
  required int pageOrder,
  String imagePath = 'notations/n1/page_original.jpg',
}) async {
  await db.into(db.notationPagesTable).insert(
        NotationPagesTableCompanion.insert(
          id: id,
          notationId: notationId,
          pageOrder: pageOrder,
          imagePath: imagePath,
          createdAt: _ts('10:00:00'),
        ),
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotationPageDao.insertPage', () {
    late AppDatabase db;
    late NotationPageDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationPageDao(db);
      await _insertParentNotation(db, 'n1');
    });
    tearDown(() => db.close());

    test('inserts a page and it is retrievable via select', () async {
      final companion = NotationPagesTableCompanion.insert(
        id: 'p1',
        notationId: 'n1',
        pageOrder: 0,
        imagePath: 'notations/n1/page_p1_original.jpg',
        createdAt: _ts('10:00:00'),
      );

      await dao.insertPage(companion);

      final rows = await db.select(db.notationPagesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'p1');
      expect(rows.first.pageOrder, 0);
    });

    test('duplicate id throws', () async {
      final companion = NotationPagesTableCompanion.insert(
        id: 'p-dup',
        notationId: 'n1',
        pageOrder: 0,
        imagePath: 'path/a',
        createdAt: _ts('10:00:00'),
      );
      await dao.insertPage(companion);

      expect(
        () => dao.insertPage(companion),
        throwsA(anything),
      );
    });

    test('duplicate (notation_id, page_order) throws', () async {
      await dao.insertPage(
        NotationPagesTableCompanion.insert(
          id: 'p1',
          notationId: 'n1',
          pageOrder: 0,
          imagePath: 'path/a',
          createdAt: _ts('10:00:00'),
        ),
      );

      expect(
        () => dao.insertPage(
          NotationPagesTableCompanion.insert(
            id: 'p2', // different id, same order
            notationId: 'n1',
            pageOrder: 0,
            imagePath: 'path/b',
            createdAt: _ts('10:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });

    test('FK violation throws when notation_id does not exist', () async {
      expect(
        () => dao.insertPage(
          NotationPagesTableCompanion.insert(
            id: 'p-orphan',
            notationId: 'no-such-notation',
            pageOrder: 0,
            imagePath: 'path/a',
            createdAt: _ts('10:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  group('NotationPageDao.updatePage', () {
    late AppDatabase db;
    late NotationPageDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationPageDao(db);
      await _insertParentNotation(db, 'n1');
      await _insertPage(
        db,
        id: 'p1',
        notationId: 'n1',
        pageOrder: 0,
        imagePath: 'notations/n1/page_p1_original.jpg',
      );
    });
    tearDown(() => db.close());

    test('updates imagePath of an existing page', () async {
      final companion = NotationPagesTableCompanion(
        id: const Value('p1'),
        imagePath: const Value('notations/n1/page_p1_edited.jpg'),
      );

      await dao.updatePage(companion);

      final row = await (db.select(db.notationPagesTable)
            ..where((t) => t.id.equals('p1')))
          .getSingle();
      expect(row.imagePath, 'notations/n1/page_p1_edited.jpg');
    });

    test('returns false for a non-existent id', () async {
      final companion = NotationPagesTableCompanion(
        id: const Value('ghost'),
        imagePath: const Value('any/path'),
      );

      final updated = await dao.updatePage(companion);
      expect(updated, isFalse);
    });
  });

  group('NotationPageDao.deletePage', () {
    late AppDatabase db;
    late NotationPageDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationPageDao(db);
      await _insertParentNotation(db, 'n1');
      await _insertPage(db, id: 'p1', notationId: 'n1', pageOrder: 0);
    });
    tearDown(() => db.close());

    test('permanently removes the page row', () async {
      await dao.deletePage('p1');

      final rows = await db.select(db.notationPagesTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.deletePage('ghost');
    });
  });

  group('NotationPageDao.getPagesByNotationId', () {
    late AppDatabase db;
    late NotationPageDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationPageDao(db);
      await _insertParentNotation(db, 'n1');
      await _insertParentNotation(db, 'n2');
    });
    tearDown(() => db.close());

    test('returns pages ordered by page_order ascending', () async {
      await _insertPage(db, id: 'p3', notationId: 'n1', pageOrder: 2);
      await _insertPage(db, id: 'p1', notationId: 'n1', pageOrder: 0);
      await _insertPage(db, id: 'p2', notationId: 'n1', pageOrder: 1);

      final pages = await dao.getPagesByNotationId('n1');

      expect(pages.map((p) => p.pageOrder).toList(), [0, 1, 2]);
    });

    test('returns only pages belonging to the requested notation', () async {
      await _insertPage(db, id: 'p1', notationId: 'n1', pageOrder: 0);
      await _insertPage(db, id: 'p2', notationId: 'n2', pageOrder: 0);

      final pages = await dao.getPagesByNotationId('n1');

      expect(pages, hasLength(1));
      expect(pages.first.id, 'p1');
    });

    test('returns empty list for a notation with no pages', () async {
      final pages = await dao.getPagesByNotationId('n1');
      expect(pages, isEmpty);
    });

    test('returns empty list for an unknown notation id', () async {
      final pages = await dao.getPagesByNotationId('no-such-notation');
      expect(pages, isEmpty);
    });
  });

  group('NotationPageDao.deleteAllPagesForNotation', () {
    late AppDatabase db;
    late NotationPageDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationPageDao(db);
      await _insertParentNotation(db, 'n1');
      await _insertParentNotation(db, 'n2');
    });
    tearDown(() => db.close());

    test('removes all pages for the given notation', () async {
      await _insertPage(db, id: 'p1', notationId: 'n1', pageOrder: 0);
      await _insertPage(db, id: 'p2', notationId: 'n1', pageOrder: 1);

      await dao.deleteAllPagesForNotation('n1');

      final rows = await db.select(db.notationPagesTable).get();
      expect(rows, isEmpty);
    });

    test('does not affect pages belonging to a different notation', () async {
      await _insertPage(db, id: 'p1', notationId: 'n1', pageOrder: 0);
      await _insertPage(db, id: 'p2', notationId: 'n2', pageOrder: 0);

      await dao.deleteAllPagesForNotation('n1');

      final rows = await db.select(db.notationPagesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'p2');
    });

    test('is a no-op when the notation has no pages', () async {
      // Must not throw.
      await dao.deleteAllPagesForNotation('n1');
    });
  });
}
