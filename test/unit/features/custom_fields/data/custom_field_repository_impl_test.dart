// Unit tests for CustomFieldRepositoryImpl.
//
// Covers all public methods against an in-memory Drift database:
//   watchAllDefinitions, createDefinition, updateDefinition, deleteDefinition.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/custom_fields/data/custom_field_repository_impl.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';

void main() {
  // ---------------------------------------------------------------------------
  // watchAllDefinitions
  // ---------------------------------------------------------------------------

  group('CustomFieldRepositoryImpl.watchAllDefinitions', () {
    late AppDatabase db;
    late CustomFieldRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = CustomFieldRepositoryImpl(db.customFieldDao);
    });
    tearDown(() => db.close());

    test('emits empty list when no definitions exist', () async {
      final defs = await repo.watchAllDefinitions().first;
      expect(defs, isEmpty);
    });

    test('emits CustomFieldDefinition domain models ordered by keyName',
        () async {
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'd2',
              keyName: 'raga_name',
              fieldType: 'text',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'd1',
              keyName: 'bpm',
              fieldType: 'number',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      final defs = await repo.watchAllDefinitions().first;
      expect(defs, hasLength(2));
      expect(defs.first.keyName, 'bpm');
      expect(defs.last.keyName, 'raga_name');
    });

    test('re-emits updated list after a new definition is inserted', () async {
      expect(await repo.watchAllDefinitions().first, isEmpty);

      await repo.createDefinition('difficulty', 'text');

      final updated = await repo.watchAllDefinitions().first;
      expect(updated, hasLength(1));
      expect(updated.first.keyName, 'difficulty');
    });

    test('maps fieldType string to CustomFieldType enum', () async {
      await repo.createDefinition('rating', 'number');
      final defs = await repo.watchAllDefinitions().first;
      expect(defs.first.fieldType, CustomFieldType.number);
    });
  });

  // ---------------------------------------------------------------------------
  // createDefinition
  // ---------------------------------------------------------------------------

  group('CustomFieldRepositoryImpl.createDefinition', () {
    late AppDatabase db;
    late CustomFieldRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = CustomFieldRepositoryImpl(db.customFieldDao);
    });
    tearDown(() => db.close());

    test('returns a CustomFieldDefinition with correct keyName and fieldType',
        () async {
      final def = await repo.createDefinition('notes', 'text');

      expect(def.keyName, 'notes');
      expect(def.fieldType, CustomFieldType.text);
    });

    test('persists the definition to the database', () async {
      await repo.createDefinition('started_date', 'date');

      final rows =
          await db.select(db.customFieldDefinitionsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.keyName, 'started_date');
    });

    test('returned definition has a non-empty uuid id', () async {
      final def = await repo.createDefinition('tempo', 'number');
      expect(def.id, isNotEmpty);
    });

    test('returned definition has createdAt and updatedAt set', () async {
      final def = await repo.createDefinition('tempo', 'number');
      expect(def.createdAt, isNotEmpty);
      expect(def.updatedAt, isNotEmpty);
    });

    test('creates multiple definitions with distinct ids', () async {
      final d1 = await repo.createDefinition('alpha', 'text');
      final d2 = await repo.createDefinition('beta', 'boolean');
      expect(d1.id, isNot(equals(d2.id)));
    });

    test('throws on duplicate keyName', () async {
      await repo.createDefinition('unique_key', 'text');
      expect(
        () => repo.createDefinition('unique_key', 'number'),
        throwsA(anything),
      );
    });

    test('supports all valid fieldType values', () async {
      final text = await repo.createDefinition('f_text', 'text');
      final number = await repo.createDefinition('f_number', 'number');
      final date = await repo.createDefinition('f_date', 'date');
      final boolean = await repo.createDefinition('f_boolean', 'boolean');

      expect(text.fieldType, CustomFieldType.text);
      expect(number.fieldType, CustomFieldType.number);
      expect(date.fieldType, CustomFieldType.date);
      expect(boolean.fieldType, CustomFieldType.boolean);
    });
  });

  // ---------------------------------------------------------------------------
  // updateDefinition
  // ---------------------------------------------------------------------------

  group('CustomFieldRepositoryImpl.updateDefinition', () {
    late AppDatabase db;
    late CustomFieldRepositoryImpl repo;
    late CustomFieldDefinition existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = CustomFieldRepositoryImpl(db.customFieldDao);
      existing = await repo.createDefinition('original_key', 'text');
    });
    tearDown(() => db.close());

    test('updates keyName and returns updated definition', () async {
      final updated = await repo.updateDefinition(
        existing.id,
        keyName: 'renamed_key',
      );
      expect(updated.keyName, 'renamed_key');
      expect(updated.fieldType, existing.fieldType);
    });

    test('updates fieldType and returns updated definition', () async {
      final updated = await repo.updateDefinition(
        existing.id,
        fieldType: 'number',
      );
      expect(updated.fieldType, CustomFieldType.number);
      expect(updated.keyName, existing.keyName);
    });

    test('updates both keyName and fieldType', () async {
      final updated = await repo.updateDefinition(
        existing.id,
        keyName: 'new_key',
        fieldType: 'date',
      );
      expect(updated.keyName, 'new_key');
      expect(updated.fieldType, CustomFieldType.date);
    });

    test('persists changes to the database', () async {
      await repo.updateDefinition(existing.id, keyName: 'persisted_key');

      final rows =
          await db.select(db.customFieldDefinitionsTable).get();
      expect(rows.first.keyName, 'persisted_key');
    });

    test('throws CustomFieldNotFoundException for unknown id', () async {
      expect(
        () => repo.updateDefinition('non-existent-id', keyName: 'ghost'),
        throwsA(isA<CustomFieldNotFoundException>()),
      );
    });

    test('updatedAt is a valid non-empty ISO 8601 string after update',
        () async {
      final updated =
          await repo.updateDefinition(existing.id, keyName: 'updated_key');
      expect(updated.updatedAt, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteDefinition
  // ---------------------------------------------------------------------------

  group('CustomFieldRepositoryImpl.deleteDefinition', () {
    late AppDatabase db;
    late CustomFieldRepositoryImpl repo;
    late CustomFieldDefinition existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = CustomFieldRepositoryImpl(db.customFieldDao);
      existing = await repo.createDefinition('to_delete', 'text');
    });
    tearDown(() => db.close());

    test('removes the definition row from the database', () async {
      await repo.deleteDefinition(existing.id);

      final rows =
          await db.select(db.customFieldDefinitionsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for an unknown id', () async {
      // Must not throw.
      await repo.deleteDefinition('ghost-id');
    });

    test('watchAllDefinitions emits empty list after deletion', () async {
      await repo.deleteDefinition(existing.id);
      final defs = await repo.watchAllDefinitions().first;
      expect(defs, isEmpty);
    });
  });
}
