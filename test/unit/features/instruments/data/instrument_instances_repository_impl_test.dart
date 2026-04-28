// Unit tests for InstrumentRepositoryImpl — instance methods.
//
// Covers: watchActiveInstancesForClass, createInstance, updateInstance,
// archiveInstance against an in-memory Drift database.
//
// Each group sets up a fresh AppDatabase.forTesting() in setUp and closes in
// tearDown to ensure full isolation.
//
// Naming: <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/instruments/data/instrument_repository_impl.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kColorHex = '#cba6f7';
const _kClassId = 'class-1';

Future<void> _insertClass(AppDatabase db, String id, {String? name}) async {
  final now = DateTime.now().toUtc().toIso8601String();
  await db.instrumentDao.insertClass(
    InstrumentClassesTableCompanion.insert(
      id: id,
      name: name ?? 'Class-$id',
      createdAt: now,
      updatedAt: now,
    ),
  );
}

void main() {
  // -------------------------------------------------------------------------
  // watchActiveInstancesForClass
  // -------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.watchActiveInstancesForClass', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      await _insertClass(db, _kClassId);
    });
    tearDown(() => db.close());

    test('emits empty list when no instances exist', () async {
      final instances =
          await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(instances, isEmpty);
    });

    test('emits active instances for the class', () async {
      await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
        brand: 'Radha',
      );
      final instances =
          await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(instances, hasLength(1));
      expect(instances.first.classId, _kClassId);
      expect(instances.first.brand, 'Radha');
    });

    test('excludes archived instances', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
      );
      await repo.archiveInstance(inst.id);
      final instances =
          await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(instances, isEmpty);
    });

    test('does not include instances from other classes', () async {
      const otherId = 'class-2';
      await _insertClass(db, otherId);
      await repo.createInstance(_kClassId, colorHex: _kColorHex);
      await repo.createInstance(otherId, colorHex: _kColorHex);
      final instances =
          await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(instances, hasLength(1));
    });

    test('re-emits when a new instance is created', () async {
      expect(
        await repo.watchActiveInstancesForClass(_kClassId).first,
        isEmpty,
      );
      await repo.createInstance(_kClassId, colorHex: _kColorHex);
      final instances =
          await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(instances, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // createInstance
  // -------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.createInstance', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      await _insertClass(db, _kClassId);
    });
    tearDown(() => db.close());

    test('returns persisted InstrumentInstance with generated id', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
      );
      expect(inst.id, isNotEmpty);
      expect(inst.classId, _kClassId);
      expect(inst.colorHex, _kColorHex);
      expect(inst.deletedAt, isNull);
    });

    test('persists optional brand, model, price, photo, notes', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
        brand: 'Yamaha',
        model: 'C40',
        priceInr: 15000,
        photoPath: 'instruments/inst-1/photo.jpg',
        notes: 'My favourite',
      );
      expect(inst.brand, 'Yamaha');
      expect(inst.model, 'C40');
      expect(inst.priceInr, 15000);
      expect(inst.photoPath, 'instruments/inst-1/photo.jpg');
      expect(inst.notes, 'My favourite');
    });

    test('defaults notes to empty string', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
      );
      expect(inst.notes, '');
    });
  });

  // -------------------------------------------------------------------------
  // updateInstance
  // -------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.updateInstance', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;
    late InstrumentInstance existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      await _insertClass(db, _kClassId);
      existing = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
        brand: 'Old Brand',
      );
    });
    tearDown(() => db.close());

    test('updates brand when provided', () async {
      final updated =
          await repo.updateInstance(existing.id, brand: 'New Brand');
      expect(updated.brand, 'New Brand');
      expect(updated.id, existing.id);
    });

    test('updates photoPath when provided', () async {
      final updated = await repo.updateInstance(
        existing.id,
        photoPath: 'instruments/id/photo.jpg',
      );
      expect(updated.photoPath, 'instruments/id/photo.jpg');
    });

    test('preserves other fields when only brand is updated', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
        brand: 'X',
        model: 'Y',
        notes: 'keep',
      );
      final updated = await repo.updateInstance(inst.id, brand: 'Z');
      expect(updated.model, 'Y');
      expect(updated.notes, 'keep');
    });

    test('throws InstrumentInstanceNotFoundException for unknown id', () async {
      await expectLater(
        () => repo.updateInstance('no-such-id', brand: 'X'),
        throwsA(isA<InstrumentInstanceNotFoundException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // archiveInstance
  // -------------------------------------------------------------------------

  group('InstrumentRepositoryImpl.archiveInstance', () {
    late AppDatabase db;
    late InstrumentRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = InstrumentRepositoryImpl(db.instrumentDao);
      await _insertClass(db, _kClassId);
    });
    tearDown(() => db.close());

    test('sets deletedAt so instance disappears from active list', () async {
      final inst = await repo.createInstance(
        _kClassId,
        colorHex: _kColorHex,
      );
      await repo.archiveInstance(inst.id);
      final active = await repo.watchActiveInstancesForClass(_kClassId).first;
      expect(active, isEmpty);
    });

    test('is idempotent for unknown id', () async {
      // Should not throw.
      await expectLater(
        () => repo.archiveInstance('no-such-id'),
        returnsNormally,
      );
    });
  });
}
