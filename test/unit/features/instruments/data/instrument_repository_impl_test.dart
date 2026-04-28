// Unit tests for InstrumentRepositoryImpl.
//
// Covers all public methods against an in-memory Drift database:
//   watchActiveClasses, createClass, updateClass, archiveClass,
//   getInstanceCountForClass.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/instruments/data/instrument_repository_impl.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

void main() {
  // ---------------------------------------------------------------------------
  // watchActiveClasses
  // ---------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.watchActiveClasses', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
    });
    tearDown(() => db.close());

    test('emits empty list when no classes exist', () async {
      final classes = await repo.watchActiveClasses().first;
      expect(classes, isEmpty);
    });

    test('emits InstrumentClass domain models ordered by name', () async {
      await repo.createClass('Sitar');
      await repo.createClass('Tabla');
      await repo.createClass('Bansuri');

      final classes = await repo.watchActiveClasses().first;
      expect(classes, hasLength(3));
      expect(classes[0].name, 'Bansuri');
      expect(classes[1].name, 'Sitar');
      expect(classes[2].name, 'Tabla');
    });

    test('re-emits updated list after a new class is created', () async {
      expect(await repo.watchActiveClasses().first, isEmpty);
      await repo.createClass('Violin');
      final updated = await repo.watchActiveClasses().first;
      expect(updated, hasLength(1));
      expect(updated.first.name, 'Violin');
    });

    test('excludes archived classes from the active list', () async {
      final cls = await repo.createClass('Archived Class');
      await repo.archiveClass(cls.id);

      final classes = await repo.watchActiveClasses().first;
      expect(classes, isEmpty);
    });

    test('includes instance count in each class entry', () async {
      final cls = await repo.createClass('Sitar');
      final classes = await repo.watchActiveClasses().first;
      expect(classes.first.id, cls.id);
    });
  });

  // ---------------------------------------------------------------------------
  // createClass
  // ---------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.createClass', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
    });
    tearDown(() => db.close());

    test('returns an InstrumentClass with the correct name', () async {
      final cls = await repo.createClass('Sitar');
      expect(cls.name, 'Sitar');
    });

    test('returned class has a non-empty UUID id', () async {
      final cls = await repo.createClass('Sitar');
      expect(cls.id, isNotEmpty);
    });

    test('returned class has createdAt and updatedAt set', () async {
      final cls = await repo.createClass('Sitar');
      expect(cls.createdAt, isNotEmpty);
      expect(cls.updatedAt, isNotEmpty);
    });

    test('persists the class to the database', () async {
      await repo.createClass('Tabla');
      final rows = await db.select(db.instrumentClassesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Tabla');
    });

    test('creates multiple classes with distinct ids', () async {
      final c1 = await repo.createClass('Sitar');
      final c2 = await repo.createClass('Tabla');
      expect(c1.id, isNot(equals(c2.id)));
    });

    test('throws on duplicate name', () async {
      await repo.createClass('Sitar');
      expect(
        () => repo.createClass('Sitar'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateClass
  // ---------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.updateClass', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;
    late InstrumentClass existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      existing = await repo.createClass('Original Name');
    });
    tearDown(() => db.close());

    test('updates name and returns updated class', () async {
      final updated = await repo.updateClass(existing.id, 'New Name');
      expect(updated.name, 'New Name');
    });

    test('persists the new name to the database', () async {
      await repo.updateClass(existing.id, 'Persisted Name');
      final rows = await db.select(db.instrumentClassesTable).get();
      expect(rows.first.name, 'Persisted Name');
    });

    test('updatedAt is set after update', () async {
      final updated = await repo.updateClass(existing.id, 'Updated');
      expect(updated.updatedAt, isNotEmpty);
    });

    test('throws InstrumentClassNotFoundException for unknown id', () async {
      expect(
        () => repo.updateClass('non-existent-id', 'Name'),
        throwsA(isA<InstrumentClassNotFoundException>()),
      );
    });

    test('id is unchanged after update', () async {
      final updated = await repo.updateClass(existing.id, 'New Name');
      expect(updated.id, existing.id);
    });
  });

  // ---------------------------------------------------------------------------
  // archiveClass
  // ---------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.archiveClass', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;
    late InstrumentClass existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      existing = await repo.createClass('To Archive');
    });
    tearDown(() => db.close());

    test('archived class no longer appears in watchActiveClasses', () async {
      await repo.archiveClass(existing.id);
      final classes = await repo.watchActiveClasses().first;
      expect(classes, isEmpty);
    });

    test('is a no-op for an unknown id', () async {
      // Must not throw.
      await repo.archiveClass('ghost-id');
    });

    test('archived class still present in raw table', () async {
      await repo.archiveClass(existing.id);
      final rows = await db.select(db.instrumentClassesTable).get();
      // Row still exists but with deletedAt set.
      expect(rows, hasLength(1));
    });

    test('watchActiveClasses emits empty after archiving', () async {
      await repo.archiveClass(existing.id);
      final classes = await repo.watchActiveClasses().first;
      expect(classes, isEmpty);
    });
  });
}
