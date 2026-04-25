// Unit tests for InstrumentDao.
//
// Covers all eight public methods against an in-memory Drift database:
//   insertClass, updateClass, getActiveClasses,
//   insertInstance, updateInstance, archiveInstance,
//   getActiveInstancesForClass, getInstanceById.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/instrument_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal [InstrumentClassesTableCompanion] and returns its id.
Future<String> _insertClass(
  AppDatabase db, {
  required String id,
  String name = 'String',
}) async {
  await db.into(db.instrumentClassesTable).insert(
        InstrumentClassesTableCompanion.insert(
          id: id,
          name: name,
          createdAt: _ts('10:00:00'),
          updatedAt: _ts('10:00:00'),
        ),
      );
  return id;
}

/// Inserts a minimal [InstrumentInstancesTableCompanion] and returns its id.
Future<String> _insertInstance(
  AppDatabase db, {
  required String id,
  required String classId,
  String? deletedAt,
}) async {
  await db.into(db.instrumentInstancesTable).insert(
        InstrumentInstancesTableCompanion.insert(
          id: id,
          classId: classId,
          colorHex: '#cba6f7',
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
  // -------------------------------------------------------------------------
  // insertClass
  // -------------------------------------------------------------------------

  group('InstrumentDao.insertClass', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
    });
    tearDown(() => db.close());

    test('inserts a class and it is retrievable via select', () async {
      final companion = InstrumentClassesTableCompanion.insert(
        id: 'c1',
        name: 'Percussion',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );

      await dao.insertClass(companion);

      final rows = await db.select(db.instrumentClassesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'c1');
      expect(rows.first.name, 'Percussion');
    });

    test('duplicate id throws', () async {
      final companion = InstrumentClassesTableCompanion.insert(
        id: 'c-dup',
        name: 'Wind',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );
      await dao.insertClass(companion);

      expect(
        () => dao.insertClass(companion),
        throwsA(anything),
      );
    });

    test('duplicate name throws due to UNIQUE constraint', () async {
      await dao.insertClass(
        InstrumentClassesTableCompanion.insert(
          id: 'c1',
          name: 'String',
          createdAt: _ts('09:00:00'),
          updatedAt: _ts('09:00:00'),
        ),
      );

      expect(
        () => dao.insertClass(
          InstrumentClassesTableCompanion.insert(
            id: 'c2',
            name: 'String',
            createdAt: _ts('09:00:00'),
            updatedAt: _ts('09:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateClass
  // -------------------------------------------------------------------------

  group('InstrumentDao.updateClass', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1', name: 'Original');
    });
    tearDown(() => db.close());

    test('updates the name of an existing class and returns true', () async {
      final companion = InstrumentClassesTableCompanion(
        id: const Value('c1'),
        name: const Value('Updated Class'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateClass(companion);

      expect(updated, isTrue);
      final row = await (db.select(db.instrumentClassesTable)
            ..where((t) => t.id.equals('c1')))
          .getSingle();
      expect(row.name, 'Updated Class');
    });

    test('returns false for a non-existent id', () async {
      final companion = InstrumentClassesTableCompanion(
        id: const Value('does-not-exist'),
        name: const Value('Ghost'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateClass(companion);
      expect(updated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getActiveClasses
  // -------------------------------------------------------------------------

  group('InstrumentDao.getActiveClasses', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
    });
    tearDown(() => db.close());

    test('returns empty list when no classes exist', () async {
      final classes = await dao.getActiveClasses();
      expect(classes, isEmpty);
    });

    test('returns all classes ordered by name', () async {
      await _insertClass(db, id: 'c1', name: 'Wind');
      await _insertClass(db, id: 'c2', name: 'Percussion');
      await _insertClass(db, id: 'c3', name: 'String');

      final classes = await dao.getActiveClasses();
      expect(classes, hasLength(3));
      expect(
        classes.map((c) => c.name).toList(),
        ['Percussion', 'String', 'Wind'],
      );
    });
  });

  // -------------------------------------------------------------------------
  // insertInstance
  // -------------------------------------------------------------------------

  group('InstrumentDao.insertInstance', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1');
    });
    tearDown(() => db.close());

    test('inserts an instance and it is retrievable via select', () async {
      final companion = InstrumentInstancesTableCompanion.insert(
        id: 'i1',
        classId: 'c1',
        colorHex: '#89b4fa',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );

      await dao.insertInstance(companion);

      final rows = await db.select(db.instrumentInstancesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'i1');
      expect(rows.first.classId, 'c1');
      expect(rows.first.colorHex, '#89b4fa');
    });

    test('duplicate id throws', () async {
      final companion = InstrumentInstancesTableCompanion.insert(
        id: 'i-dup',
        classId: 'c1',
        colorHex: '#cba6f7',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );
      await dao.insertInstance(companion);

      expect(
        () => dao.insertInstance(companion),
        throwsA(anything),
      );
    });

    test('throws when classId does not exist (FK RESTRICT)', () async {
      expect(
        () => dao.insertInstance(
          InstrumentInstancesTableCompanion.insert(
            id: 'i1',
            classId: 'ghost',
            colorHex: '#cba6f7',
            createdAt: _ts('09:00:00'),
            updatedAt: _ts('09:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateInstance
  // -------------------------------------------------------------------------

  group('InstrumentDao.updateInstance', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1');
      await _insertInstance(db, id: 'i1', classId: 'c1');
    });
    tearDown(() => db.close());

    test('updates optional fields of an existing instance and returns true',
        () async {
      final companion = InstrumentInstancesTableCompanion(
        id: const Value('i1'),
        brand: const Value('Yamaha'),
        model: const Value('C40'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateInstance(companion);

      expect(updated, isTrue);
      final row = await (db.select(db.instrumentInstancesTable)
            ..where((t) => t.id.equals('i1')))
          .getSingle();
      expect(row.brand, 'Yamaha');
      expect(row.model, 'C40');
    });

    test('returns false for a non-existent id', () async {
      final companion = InstrumentInstancesTableCompanion(
        id: const Value('does-not-exist'),
        brand: const Value('Ghost'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateInstance(companion);
      expect(updated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // archiveInstance
  // -------------------------------------------------------------------------

  group('InstrumentDao.archiveInstance', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1');
      await _insertInstance(db, id: 'i1', classId: 'c1');
    });
    tearDown(() => db.close());

    test('sets deleted_at to a non-null timestamp', () async {
      await dao.archiveInstance('i1');

      final row = await (db.select(db.instrumentInstancesTable)
            ..where((t) => t.id.equals('i1')))
          .getSingle();
      expect(row.deletedAt, isNotNull);
    });

    test('archived instance is excluded from getActiveInstancesForClass',
        () async {
      await dao.archiveInstance('i1');

      final active = await dao.getActiveInstancesForClass('c1');
      expect(active.any((r) => r.id == 'i1'), isFalse);
    });

    test('archived instance still exists in database (soft delete)', () async {
      await dao.archiveInstance('i1');

      final all = await db.select(db.instrumentInstancesTable).get();
      expect(all.any((r) => r.id == 'i1'), isTrue);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.archiveInstance('ghost');
    });
  });

  // -------------------------------------------------------------------------
  // getActiveInstancesForClass
  // -------------------------------------------------------------------------

  group('InstrumentDao.getActiveInstancesForClass', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1', name: 'String');
      await _insertClass(db, id: 'c2', name: 'Wind');
    });
    tearDown(() => db.close());

    test('returns empty list when class has no instances', () async {
      final instances = await dao.getActiveInstancesForClass('c1');
      expect(instances, isEmpty);
    });

    test('returns only active (non-archived) instances for the given class',
        () async {
      await _insertInstance(db, id: 'i1', classId: 'c1');
      await _insertInstance(db, id: 'i2', classId: 'c1');
      await _insertInstance(
        db,
        id: 'i3',
        classId: 'c1',
        deletedAt: _ts('08:00:00'),
      );
      // Instance belonging to a different class.
      await _insertInstance(db, id: 'i4', classId: 'c2');

      final instances = await dao.getActiveInstancesForClass('c1');
      expect(instances, hasLength(2));
      expect(instances.map((i) => i.id), containsAll(['i1', 'i2']));
      expect(instances.any((i) => i.id == 'i3'), isFalse);
      expect(instances.any((i) => i.id == 'i4'), isFalse);
    });

    test('returns empty list for a non-existent class id', () async {
      final instances = await dao.getActiveInstancesForClass('ghost');
      expect(instances, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getInstanceById
  // -------------------------------------------------------------------------

  group('InstrumentDao.getInstanceById', () {
    late AppDatabase db;
    late InstrumentDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = InstrumentDao(db);
      await _insertClass(db, id: 'c1');
      await _insertInstance(db, id: 'i1', classId: 'c1');
    });
    tearDown(() => db.close());

    test('returns the row for a known id', () async {
      final row = await dao.getInstanceById('i1');

      expect(row, isNotNull);
      expect(row!.id, 'i1');
      expect(row.classId, 'c1');
    });

    test('returns null for an unknown id', () async {
      final row = await dao.getInstanceById('missing');
      expect(row, isNull);
    });

    test('returns archived instance (getInstanceById ignores deleted_at)',
        () async {
      await dao.archiveInstance('i1');

      final row = await dao.getInstanceById('i1');
      expect(row, isNotNull);
      expect(row!.deletedAt, isNotNull);
    });
  });
}
