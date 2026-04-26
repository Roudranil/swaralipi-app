// Unit tests for CustomFieldDao.
//
// Covers all public methods against an in-memory Drift database:
//   insertDefinition, updateDefinition, deleteDefinition,
//   getAllDefinitions, watchAllDefinitions,
//   setCustomFieldValue, getValuesForNotation.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/custom_field_dao.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Inserts a minimal notation row required for FK constraints.
Future<void> _insertNotation(AppDatabase db, String id) async {
  await db.into(db.notationsTable).insert(
        NotationsTableCompanion.insert(
          id: id,
          title: 'Test Notation $id',
          createdAt: _ts('09:00:00'),
          updatedAt: _ts('09:00:00'),
        ),
      );
}

/// Inserts a custom field definition and returns its id.
Future<String> _insertDefinition(
  AppDatabase db, {
  required String id,
  String keyName = 'tempo',
  String fieldType = 'number',
}) async {
  await db.into(db.customFieldDefinitionsTable).insert(
        CustomFieldDefinitionsTableCompanion.insert(
          id: id,
          keyName: keyName,
          fieldType: fieldType,
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
  // -------------------------------------------------------------------------
  // insertDefinition
  // -------------------------------------------------------------------------

  group('CustomFieldDao.insertDefinition', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
    });
    tearDown(() => db.close());

    test('inserts a definition and it is retrievable via select', () async {
      final companion = CustomFieldDefinitionsTableCompanion.insert(
        id: 'def1',
        keyName: 'tempo',
        fieldType: 'number',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );

      await dao.insertDefinition(companion);

      final rows = await db.select(db.customFieldDefinitionsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'def1');
      expect(rows.first.keyName, 'tempo');
      expect(rows.first.fieldType, 'number');
    });

    test('duplicate id throws', () async {
      final companion = CustomFieldDefinitionsTableCompanion.insert(
        id: 'def-dup',
        keyName: 'key1',
        fieldType: 'text',
        createdAt: _ts('09:00:00'),
        updatedAt: _ts('09:00:00'),
      );
      await dao.insertDefinition(companion);

      expect(
        () => dao.insertDefinition(companion),
        throwsA(anything),
      );
    });

    test('duplicate keyName throws due to UNIQUE constraint', () async {
      await dao.insertDefinition(
        CustomFieldDefinitionsTableCompanion.insert(
          id: 'def1',
          keyName: 'unique_key',
          fieldType: 'text',
          createdAt: _ts('09:00:00'),
          updatedAt: _ts('09:00:00'),
        ),
      );

      expect(
        () => dao.insertDefinition(
          CustomFieldDefinitionsTableCompanion.insert(
            id: 'def2',
            keyName: 'unique_key',
            fieldType: 'boolean',
            createdAt: _ts('09:00:00'),
            updatedAt: _ts('09:00:00'),
          ),
        ),
        throwsA(anything),
      );
    });
  });

  // -------------------------------------------------------------------------
  // updateDefinition
  // -------------------------------------------------------------------------

  group('CustomFieldDao.updateDefinition', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertDefinition(db, id: 'def1', keyName: 'original_key');
    });
    tearDown(() => db.close());

    test('updates keyName and returns true', () async {
      final companion = CustomFieldDefinitionsTableCompanion(
        id: const Value('def1'),
        keyName: const Value('updated_key'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateDefinition(companion);

      expect(updated, isTrue);
      final row = await (db.select(db.customFieldDefinitionsTable)
            ..where((t) => t.id.equals('def1')))
          .getSingle();
      expect(row.keyName, 'updated_key');
    });

    test('returns false for a non-existent id', () async {
      final companion = CustomFieldDefinitionsTableCompanion(
        id: const Value('ghost'),
        keyName: const Value('noop'),
        updatedAt: Value(_ts('11:00:00')),
      );

      final updated = await dao.updateDefinition(companion);
      expect(updated, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // deleteDefinition
  // -------------------------------------------------------------------------

  group('CustomFieldDao.deleteDefinition', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertDefinition(db, id: 'def1');
    });
    tearDown(() => db.close());

    test('permanently removes a definition row', () async {
      await dao.deleteDefinition('def1');

      final rows = await db.select(db.customFieldDefinitionsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for a non-existent id', () async {
      // Must not throw.
      await dao.deleteDefinition('ghost');
    });

    test('cascades and removes associated notation_custom_fields rows',
        () async {
      await _insertNotation(db, 'n1');
      // Insert a value linked to def1.
      await db.into(db.notationCustomFieldsTable).insert(
            NotationCustomFieldsTableCompanion.insert(
              notationId: 'n1',
              definitionId: 'def1',
              valueNumber: const Value(120.0),
            ),
          );

      await dao.deleteDefinition('def1');

      final values = await db.select(db.notationCustomFieldsTable).get();
      expect(values, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // getAllDefinitions
  // -------------------------------------------------------------------------

  group('CustomFieldDao.getAllDefinitions', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
    });
    tearDown(() => db.close());

    test('returns empty list when no definitions exist', () async {
      final defs = await dao.getAllDefinitions();
      expect(defs, isEmpty);
    });

    test('returns all inserted definitions ordered by keyName', () async {
      await _insertDefinition(db, id: 'def2', keyName: 'zebra');
      await _insertDefinition(db, id: 'def1', keyName: 'alpha');

      final defs = await dao.getAllDefinitions();
      expect(defs, hasLength(2));
      expect(defs.map((d) => d.keyName).toList(), ['alpha', 'zebra']);
    });
  });

  // -------------------------------------------------------------------------
  // watchAllDefinitions
  // -------------------------------------------------------------------------

  group('CustomFieldDao.watchAllDefinitions', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
    });
    tearDown(() => db.close());

    test('emits empty list when no definitions exist', () async {
      final rows = await dao.watchAllDefinitions().first;
      expect(rows, isEmpty);
    });

    test('emits definitions ordered by keyName', () async {
      await _insertDefinition(db, id: 'def2', keyName: 'zebra');
      await _insertDefinition(db, id: 'def1', keyName: 'alpha');

      final rows = await dao.watchAllDefinitions().first;
      expect(rows.map((r) => r.keyName).toList(), ['alpha', 'zebra']);
    });

    test('stream emits updated list after a new definition is inserted',
        () async {
      expect(await dao.watchAllDefinitions().first, isEmpty);

      await _insertDefinition(db, id: 'def1', keyName: 'tempo');

      final rows = await dao.watchAllDefinitions().first;
      expect(rows, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  // setCustomFieldValue
  // -------------------------------------------------------------------------

  group('CustomFieldDao.setCustomFieldValue — text', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertDefinition(
        db,
        id: 'def-text',
        keyName: 'lyrics',
        fieldType: 'text',
      );
    });
    tearDown(() => db.close());

    test('inserts a text value with only value_text populated', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-text',
        fieldType: 'text',
        textValue: 'Sa Re Ga Ma',
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.valueText, 'Sa Re Ga Ma');
      expect(rows.first.valueNumber, isNull);
      expect(rows.first.valueDate, isNull);
      expect(rows.first.valueBoolean, isNull);
    });

    test('upserts existing value when called again', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-text',
        fieldType: 'text',
        textValue: 'first',
      );
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-text',
        fieldType: 'text',
        textValue: 'second',
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.valueText, 'second');
    });
  });

  group('CustomFieldDao.setCustomFieldValue — number', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertDefinition(
        db,
        id: 'def-num',
        keyName: 'tempo',
        fieldType: 'number',
      );
    });
    tearDown(() => db.close());

    test('inserts a number value with only value_number populated', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-num',
        fieldType: 'number',
        numberValue: 120.5,
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows.first.valueNumber, 120.5);
      expect(rows.first.valueText, isNull);
      expect(rows.first.valueDate, isNull);
      expect(rows.first.valueBoolean, isNull);
    });
  });

  group('CustomFieldDao.setCustomFieldValue — date', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertDefinition(
        db,
        id: 'def-date',
        keyName: 'recorded_on',
        fieldType: 'date',
      );
    });
    tearDown(() => db.close());

    test('inserts a date value with only value_date populated', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-date',
        fieldType: 'date',
        dateValue: '2024-06-15',
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows.first.valueDate, '2024-06-15');
      expect(rows.first.valueText, isNull);
      expect(rows.first.valueNumber, isNull);
      expect(rows.first.valueBoolean, isNull);
    });
  });

  group('CustomFieldDao.setCustomFieldValue — boolean', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertDefinition(
        db,
        id: 'def-bool',
        keyName: 'is_favorite',
        fieldType: 'boolean',
      );
    });
    tearDown(() => db.close());

    test('inserts a boolean true value with only value_boolean populated',
        () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-bool',
        fieldType: 'boolean',
        booleanValue: true,
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows.first.valueBoolean, 1);
      expect(rows.first.valueText, isNull);
      expect(rows.first.valueNumber, isNull);
      expect(rows.first.valueDate, isNull);
    });

    test('inserts a boolean false value as 0', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def-bool',
        fieldType: 'boolean',
        booleanValue: false,
      );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows.first.valueBoolean, 0);
    });
  });

  group('CustomFieldDao.setCustomFieldValue — invalid fieldType', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertDefinition(
        db,
        id: 'def1',
        keyName: 'tempo',
        fieldType: 'number',
      );
    });
    tearDown(() => db.close());

    test('throws ArgumentError for unknown fieldType', () async {
      expect(
        () => dao.setCustomFieldValue(
          notationId: 'n1',
          definitionId: 'def1',
          fieldType: 'unknown',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  // getValuesForNotation
  // -------------------------------------------------------------------------

  group('CustomFieldDao.getValuesForNotation', () {
    late AppDatabase db;
    late CustomFieldDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = CustomFieldDao(db);
      await _insertNotation(db, 'n1');
      await _insertNotation(db, 'n2');
      await _insertDefinition(db, id: 'def1', keyName: 'tempo');
      await _insertDefinition(
        db,
        id: 'def2',
        keyName: 'lyrics',
        fieldType: 'text',
      );
    });
    tearDown(() => db.close());

    test('returns empty list when no values exist for notation', () async {
      final values = await dao.getValuesForNotation('n1');
      expect(values, isEmpty);
    });

    test('returns only values for the requested notation', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def1',
        fieldType: 'number',
        numberValue: 100.0,
      );
      await dao.setCustomFieldValue(
        notationId: 'n2',
        definitionId: 'def1',
        fieldType: 'number',
        numberValue: 200.0,
      );

      final values = await dao.getValuesForNotation('n1');
      expect(values, hasLength(1));
      expect(values.first.notationId, 'n1');
      expect(values.first.valueNumber, 100.0);
    });

    test('returns multiple values for different definitions', () async {
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def1',
        fieldType: 'number',
        numberValue: 80.0,
      );
      await dao.setCustomFieldValue(
        notationId: 'n1',
        definitionId: 'def2',
        fieldType: 'text',
        textValue: 'Sa Pa',
      );

      final values = await dao.getValuesForNotation('n1');
      expect(values, hasLength(2));
    });
  });
}
