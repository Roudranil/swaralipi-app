// Unit tests for TagDao.
//
// Covers all six public methods against an in-memory Drift database:
//   insertTag, updateTag, deleteTag, getAllTags, watchAllTags, getTagById.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/tag_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal [TagsTableCompanion] and returns its id.
Future<String> _insertTag(
  AppDatabase db, {
  required String id,
  String name = 'Raag',
  String colorHex = '#f38ba8',
}) async {
  await db.into(db.tagsTable).insert(
        TagsTableCompanion.insert(
          id: id,
          name: name,
          colorHex: colorHex,
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
        ),
      );
  return id;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TagDao.insertTag', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
    });
    tearDown(() => db.close());

    test('inserts a tag and it is retrievable via select', () async {
      final companion = TagsTableCompanion.insert(
        id: 't1',
        name: 'Classical',
        colorHex: '#89b4fa',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );

      await dao.insertTag(companion);

      final rows = await db.select(db.tagsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 't1');
      expect(rows.first.name, 'Classical');
      expect(rows.first.colorHex, '#89b4fa');
    });

    test('duplicate id throws', () async {
      final companion = TagsTableCompanion.insert(
        id: 't-dup',
        name: 'Folk',
        colorHex: '#fab387',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );
      await dao.insertTag(companion);

      expect(
        () => dao.insertTag(companion),
        throwsA(anything),
      );
    });

    test('duplicate name throws due to UNIQUE constraint', () async {
      await dao.insertTag(
        TagsTableCompanion.insert(
          id: 't1',
          name: 'Bhajan',
          colorHex: '#a6e3a1',
          createdAt: _ts('09:00:00'),
          updatedAt: _ts('09:00:00'),
        ),
      );

      expect(
        () => dao.insertTag(
          TagsTableCompanion.insert(
            id: 't2',
            name: 'Bhajan',
            colorHex: '#cba6f7',
            createdAt: _ts('09:00:00'),
            updatedAt: _ts('09:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  group('TagDao.updateTag', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
      await _insertTag(db, id: 't1', name: 'Original');
    });
    tearDown(() => db.close());

    test('updates the name of an existing tag and returns true', () async {
      final companion = TagsTableCompanion(
        id: const Value('t1'),
        name: const Value('Updated Name'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateTag(companion);

      expect(updated, isTrue);
      final row = await (db.select(db.tagsTable)
            ..where((t) => t.id.equals('t1')))
          .getSingle();
      expect(row.name, 'Updated Name');
    });

    test('returns false for a non-existent id', () async {
      final companion = TagsTableCompanion(
        id: const Value('does-not-exist'),
        name: const Value('Ghost'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateTag(companion);
      expect(updated, isFalse);
    });
  });

  group('TagDao.deleteTag', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
      await _insertTag(db, id: 't1');
    });
    tearDown(() => db.close());

    test('permanently removes a tag row', () async {
      await dao.deleteTag('t1');

      final rows = await db.select(db.tagsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.deleteTag('ghost');
    });
  });

  group('TagDao.getAllTags', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
    });
    tearDown(() => db.close());

    test('returns empty list when no tags exist', () async {
      final tags = await dao.getAllTags();
      expect(tags, isEmpty);
    });

    test('returns all inserted tags', () async {
      await _insertTag(db, id: 't1', name: 'Raag');
      await _insertTag(db, id: 't2', name: 'Folk');

      final tags = await dao.getAllTags();
      expect(tags, hasLength(2));
      expect(tags.map((t) => t.id), containsAll(['t1', 't2']));
    });
  });

  group('TagDao.watchAllTags', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
    });
    tearDown(() => db.close());

    test('emits empty list when no tags exist', () async {
      final rows = await dao.watchAllTags().first;
      expect(rows, isEmpty);
    });

    test('emits all tags ordered by name', () async {
      await _insertTag(db, id: 't1', name: 'Raag');
      await _insertTag(db, id: 't2', name: 'Bhajan');

      final rows = await dao.watchAllTags().first;
      expect(rows.map((r) => r.name).toList(), ['Bhajan', 'Raag']);
    });

    test('stream emits updated list after a new tag is inserted', () async {
      final stream = dao.watchAllTags();

      // First emission — empty.
      expect(await stream.first, isEmpty);

      await _insertTag(db, id: 't1', name: 'Folk');

      // Second emission — one row.
      final second = await dao.watchAllTags().first;
      expect(second, hasLength(1));
    });
  });

  group('TagDao.getTagById', () {
    late AppDatabase db;
    late TagDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = TagDao(db);
      await _insertTag(db, id: 't1', name: 'Devotional');
    });
    tearDown(() => db.close());

    test('returns the row for a known id', () async {
      final row = await dao.getTagById('t1');

      expect(row, isNotNull);
      expect(row!.id, 't1');
      expect(row.name, 'Devotional');
    });

    test('returns null for an unknown id', () async {
      final row = await dao.getTagById('missing');
      expect(row, isNull);
    });
  });
}
