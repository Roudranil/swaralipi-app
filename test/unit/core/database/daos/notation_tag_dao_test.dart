// Unit tests for NotationTagDao.
//
// Covers all four public methods against an in-memory Drift database:
//   assignTag, removeTag, getTagsForNotation, getNotationsForTag.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/notation_tag_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal notation row into [db].
Future<void> _insertNotation(AppDatabase db, String id) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: 'Test Notation $id',
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
        ),
      );
}

/// Inserts a minimal tag row into [db].
Future<void> _insertTag(AppDatabase db, String id, String name) async {
  await db.into(db.tagsTable).insert(
        TagsTableCompanion.insert(
          id: id,
          name: name,
          colorHex: '#f38ba8',
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
        ),
      );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('NotationTagDao.assignTag', () {
    late AppDatabase db;
    late NotationTagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationTagDao(db);
      await _insertNotation(db, 'n1');
      await _insertTag(db, 't1', 'Raag');
    });
    tearDown(() => db.close());

    test('creates a join row between notation and tag', () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');

      final rows = await db.select(db.notationTagsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.notationId, 'n1');
      expect(rows.first.tagId, 't1');
    });

    test('assigning the same tag twice throws (primary key violation)',
        () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');

      expect(
        () => dao.assignTag(notationId: 'n1', tagId: 't1'),
        throwsA(anything),
      );
    });

    test('throws when notationId does not exist (FK constraint)', () async {
      expect(
        () => dao.assignTag(notationId: 'ghost', tagId: 't1'),
        throwsA(anything),
      );
    });

    test('throws when tagId does not exist (FK constraint)', () async {
      expect(
        () => dao.assignTag(notationId: 'n1', tagId: 'ghost'),
        throwsA(anything),
      );
    });
  });

  group('NotationTagDao.removeTag', () {
    late AppDatabase db;
    late NotationTagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationTagDao(db);
      await _insertNotation(db, 'n1');
      await _insertTag(db, 't1', 'Raag');
      await dao.assignTag(notationId: 'n1', tagId: 't1');
    });
    tearDown(() => db.close());

    test('removes the join row between notation and tag', () async {
      await dao.removeTag(notationId: 'n1', tagId: 't1');

      final rows = await db.select(db.notationTagsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op when the pair does not exist', () async {
      // Must not throw.
      await dao.removeTag(notationId: 'n1', tagId: 'ghost');
    });
  });

  group('NotationTagDao.getTagsForNotation', () {
    late AppDatabase db;
    late NotationTagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationTagDao(db);
      await _insertNotation(db, 'n1');
      await _insertNotation(db, 'n2');
      await _insertTag(db, 't1', 'Raag');
      await _insertTag(db, 't2', 'Folk');
    });
    tearDown(() => db.close());

    test('returns empty list when notation has no tags', () async {
      final tags = await dao.getTagsForNotation('n1');
      expect(tags, isEmpty);
    });

    test('returns only tags assigned to the specified notation', () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');
      await dao.assignTag(notationId: 'n1', tagId: 't2');
      await dao.assignTag(notationId: 'n2', tagId: 't1');

      final tags = await dao.getTagsForNotation('n1');
      expect(tags, hasLength(2));
      expect(tags.map((t) => t.id), containsAll(['t1', 't2']));
    });

    test('returns null for unknown notationId', () async {
      final tags = await dao.getTagsForNotation('ghost');
      expect(tags, isEmpty);
    });

    test('tag deleted from tags table cascades and removes from notation tags',
        () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');

      // Hard-delete the tag — ON DELETE CASCADE should remove the join row.
      await (db.delete(db.tagsTable)..where((t) => t.id.equals('t1'))).go();

      final tags = await dao.getTagsForNotation('n1');
      expect(tags, isEmpty);
    });
  });

  group('NotationTagDao.getNotationsForTag', () {
    late AppDatabase db;
    late NotationTagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = NotationTagDao(db);
      await _insertNotation(db, 'n1');
      await _insertNotation(db, 'n2');
      await _insertTag(db, 't1', 'Raag');
      await _insertTag(db, 't2', 'Folk');
    });
    tearDown(() => db.close());

    test('returns empty list when tag has no notations', () async {
      final notations = await dao.getNotationsForTag('t1');
      expect(notations, isEmpty);
    });

    test('returns only notations assigned to the specified tag', () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');
      await dao.assignTag(notationId: 'n2', tagId: 't1');
      await dao.assignTag(notationId: 'n1', tagId: 't2');

      final notations = await dao.getNotationsForTag('t1');
      expect(notations, hasLength(2));
      expect(
        notations.map((r) => r.id),
        containsAll(['n1', 'n2']),
      );
    });

    test('notation deleted cascades and removes from notation tags', () async {
      await dao.assignTag(notationId: 'n1', tagId: 't1');

      // Hard-delete the notation — ON DELETE CASCADE removes join row.
      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final notations = await dao.getNotationsForTag('t1');
      expect(notations, isEmpty);
    });
  });
}
