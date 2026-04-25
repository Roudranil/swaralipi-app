// Unit tests for AppDatabase — verifies table schema, constraints, and
// database-level behaviors (FK cascades, CHECK constraints, singleton
// enforcement) using an in-memory Drift database.
//
// Coverage targets:
// - All 10 table classes instantiate in AppDatabase
// - Insert / select round-trips for each table
// - UNIQUE constraints are enforced
// - CHECK constraints are enforced (user_preferences, custom_field_definitions)
// - ON DELETE CASCADE propagates correctly
// - ON DELETE RESTRICT blocks deletion correctly
// - Singleton constraint on user_preferences

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';

/// Opens a fresh in-memory [AppDatabase] for each test.
///
/// Foreign keys are enabled and seed data is suppressed so tests start clean.
AppDatabase _openInMemory() => AppDatabase.forTesting();

void main() {
  group('AppDatabase — notations table', () {
    late AppDatabase db;

    setUp(() => db = _openInMemory());
    tearDown(() => db.close());

    test('inserts and retrieves a notation row', () async {
      final companion = NotationsTableCompanion.insert(
        id: 'uuid-1',
        title: 'Yaman Kalyan',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
      );
      await db.into(db.notationsTable).insert(companion);

      final rows = await db.select(db.notationsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 'uuid-1');
      expect(rows.first.title, 'Yaman Kalyan');
    });

    test('default values are applied on insert', () async {
      final companion = NotationsTableCompanion.insert(
        id: 'uuid-2',
        title: 'Test',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
      );
      await db.into(db.notationsTable).insert(companion);

      final row = await (db.select(db.notationsTable)
            ..where((t) => t.id.equals('uuid-2')))
          .getSingle();

      expect(row.artists, '[]');
      expect(row.languages, '[]');
      expect(row.notes, '');
      expect(row.playCount, 0);
      expect(row.deletedAt, isNull);
    });

    test('primary key is unique — duplicate id throws', () async {
      final companion = NotationsTableCompanion.insert(
        id: 'uuid-dup',
        title: 'First',
        createdAt: '2024-01-01T10:00:00Z',
        updatedAt: '2024-01-01T10:00:00Z',
      );
      await db.into(db.notationsTable).insert(companion);

      expect(
        () => db.into(db.notationsTable).insert(companion),
        throwsA(anything),
      );
    });
  });

  group('AppDatabase — notation_pages table', () {
    late AppDatabase db;

    setUp(() async {
      db = _openInMemory();
      await db.into(db.notationsTable).insert(
            NotationsTableCompanion.insert(
              id: 'n1',
              title: 'Parent',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
    });
    tearDown(() => db.close());

    test('inserts and retrieves a page row', () async {
      await db.into(db.notationPagesTable).insert(
            NotationPagesTableCompanion.insert(
              id: 'p1',
              notationId: 'n1',
              pageOrder: 0,
              imagePath: 'notations/n1/page_p1_original.jpg',
              createdAt: '2024-01-01T10:00:00Z',
            ),
          );

      final rows = await db.select(db.notationPagesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.notationId, 'n1');
      expect(rows.first.pageOrder, 0);
    });

    test('UNIQUE (notation_id, page_order) is enforced', () async {
      await db.into(db.notationPagesTable).insert(
            NotationPagesTableCompanion.insert(
              id: 'p1',
              notationId: 'n1',
              pageOrder: 0,
              imagePath: 'path/1',
              createdAt: '2024-01-01T10:00:00Z',
            ),
          );

      expect(
        () => db.into(db.notationPagesTable).insert(
              NotationPagesTableCompanion.insert(
                id: 'p2', // different id, same (notation_id, page_order)
                notationId: 'n1',
                pageOrder: 0,
                imagePath: 'path/2',
                createdAt: '2024-01-01T10:00:00Z',
              ),
            ),
        throwsA(anything),
      );
    });

    test('ON DELETE CASCADE removes pages when notation is deleted', () async {
      await db.into(db.notationPagesTable).insert(
            NotationPagesTableCompanion.insert(
              id: 'p1',
              notationId: 'n1',
              pageOrder: 0,
              imagePath: 'path/1',
              createdAt: '2024-01-01T10:00:00Z',
            ),
          );

      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final pages = await db.select(db.notationPagesTable).get();
      expect(pages, isEmpty);
    });
  });

  group('AppDatabase — tags table', () {
    late AppDatabase db;

    setUp(() => db = _openInMemory());
    tearDown(() => db.close());

    test('inserts and retrieves a tag', () async {
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 't1',
              name: 'Raag',
              colorHex: '#f38ba8',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      final rows = await db.select(db.tagsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Raag');
    });

    test('UNIQUE name constraint is enforced', () async {
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 't1',
              name: 'Raag',
              colorHex: '#f38ba8',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      expect(
        () => db.into(db.tagsTable).insert(
              TagsTableCompanion.insert(
                id: 't2',
                name: 'Raag', // same name
                colorHex: '#a6e3a1',
                createdAt: '2024-01-01T10:00:00Z',
                updatedAt: '2024-01-01T10:00:00Z',
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('AppDatabase — notation_tags junction table', () {
    late AppDatabase db;

    setUp(() async {
      db = _openInMemory();
      await db.into(db.notationsTable).insert(
            NotationsTableCompanion.insert(
              id: 'n1',
              title: 'Yaman',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 't1',
              name: 'Raag',
              colorHex: '#f38ba8',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
    });
    tearDown(() => db.close());

    test('links a notation to a tag', () async {
      await db.into(db.notationTagsTable).insert(
            NotationTagsTableCompanion.insert(
              notationId: 'n1',
              tagId: 't1',
            ),
          );

      final rows = await db.select(db.notationTagsTable).get();
      expect(rows, hasLength(1));
    });

    test('ON DELETE CASCADE removes link when notation deleted', () async {
      await db.into(db.notationTagsTable).insert(
            NotationTagsTableCompanion.insert(
              notationId: 'n1',
              tagId: 't1',
            ),
          );

      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final rows = await db.select(db.notationTagsTable).get();
      expect(rows, isEmpty);
    });

    test('ON DELETE CASCADE removes link when tag deleted', () async {
      await db.into(db.notationTagsTable).insert(
            NotationTagsTableCompanion.insert(
              notationId: 'n1',
              tagId: 't1',
            ),
          );

      await (db.delete(db.tagsTable)..where((t) => t.id.equals('t1'))).go();

      final rows = await db.select(db.notationTagsTable).get();
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase — instrument_classes table', () {
    late AppDatabase db;

    setUp(() => db = _openInMemory());
    tearDown(() => db.close());

    test('inserts and retrieves an instrument class', () async {
      await db.into(db.instrumentClassesTable).insert(
            InstrumentClassesTableCompanion.insert(
              id: 'ic1',
              name: 'String',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      final rows = await db.select(db.instrumentClassesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'String');
    });

    test('UNIQUE name constraint is enforced on instrument_classes', () async {
      await db.into(db.instrumentClassesTable).insert(
            InstrumentClassesTableCompanion.insert(
              id: 'ic1',
              name: 'String',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      expect(
        () => db.into(db.instrumentClassesTable).insert(
              InstrumentClassesTableCompanion.insert(
                id: 'ic2',
                name: 'String',
                createdAt: '2024-01-01T10:00:00Z',
                updatedAt: '2024-01-01T10:00:00Z',
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('AppDatabase — instrument_instances table', () {
    late AppDatabase db;

    setUp(() async {
      db = _openInMemory();
      await db.into(db.instrumentClassesTable).insert(
            InstrumentClassesTableCompanion.insert(
              id: 'ic1',
              name: 'String',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
    });
    tearDown(() => db.close());

    test('inserts and retrieves an instrument instance', () async {
      await db.into(db.instrumentInstancesTable).insert(
            InstrumentInstancesTableCompanion.insert(
              id: 'ii1',
              classId: 'ic1',
              colorHex: '#cba6f7',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      final rows = await db.select(db.instrumentInstancesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.classId, 'ic1');
      expect(rows.first.colorHex, '#cba6f7');
    });

    test('ON DELETE RESTRICT blocks deleting class with instances', () async {
      await db.into(db.instrumentInstancesTable).insert(
            InstrumentInstancesTableCompanion.insert(
              id: 'ii1',
              classId: 'ic1',
              colorHex: '#cba6f7',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      expect(
        () => (db.delete(db.instrumentClassesTable)
              ..where((t) => t.id.equals('ic1')))
            .go(),
        throwsA(anything),
      );
    });

    test('default notes is empty string', () async {
      await db.into(db.instrumentInstancesTable).insert(
            InstrumentInstancesTableCompanion.insert(
              id: 'ii1',
              classId: 'ic1',
              colorHex: '#cba6f7',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      final row = await (db.select(db.instrumentInstancesTable)
            ..where((t) => t.id.equals('ii1')))
          .getSingle();
      expect(row.notes, '');
    });
  });

  group('AppDatabase — notation_instruments junction table', () {
    late AppDatabase db;

    setUp(() async {
      db = _openInMemory();
      await db.into(db.notationsTable).insert(
            NotationsTableCompanion.insert(
              id: 'n1',
              title: 'Yaman',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
      await db.into(db.instrumentClassesTable).insert(
            InstrumentClassesTableCompanion.insert(
              id: 'ic1',
              name: 'String',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
      await db.into(db.instrumentInstancesTable).insert(
            InstrumentInstancesTableCompanion.insert(
              id: 'ii1',
              classId: 'ic1',
              colorHex: '#cba6f7',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
    });
    tearDown(() => db.close());

    test('links a notation to an instrument instance', () async {
      await db.into(db.notationInstrumentsTable).insert(
            NotationInstrumentsTableCompanion.insert(
              notationId: 'n1',
              instanceId: 'ii1',
            ),
          );

      final rows = await db.select(db.notationInstrumentsTable).get();
      expect(rows, hasLength(1));
    });

    test('ON DELETE CASCADE removes link when notation deleted', () async {
      await db.into(db.notationInstrumentsTable).insert(
            NotationInstrumentsTableCompanion.insert(
              notationId: 'n1',
              instanceId: 'ii1',
            ),
          );

      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final rows = await db.select(db.notationInstrumentsTable).get();
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase — custom_field_definitions table', () {
    late AppDatabase db;

    setUp(() => db = _openInMemory());
    tearDown(() => db.close());

    test('inserts valid field types', () async {
      for (final type in ['text', 'number', 'date', 'boolean']) {
        await db.into(db.customFieldDefinitionsTable).insert(
              CustomFieldDefinitionsTableCompanion.insert(
                id: 'cfd-$type',
                keyName: 'field_$type',
                fieldType: type,
                createdAt: '2024-01-01T10:00:00Z',
                updatedAt: '2024-01-01T10:00:00Z',
              ),
            );
      }

      final rows = await db.select(db.customFieldDefinitionsTable).get();
      expect(rows, hasLength(4));
    });

    test('UNIQUE key_name constraint is enforced', () async {
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'cfd1',
              keyName: 'my_field',
              fieldType: 'text',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      expect(
        () => db.into(db.customFieldDefinitionsTable).insert(
              CustomFieldDefinitionsTableCompanion.insert(
                id: 'cfd2',
                keyName: 'my_field',
                fieldType: 'number',
                createdAt: '2024-01-01T10:00:00Z',
                updatedAt: '2024-01-01T10:00:00Z',
              ),
            ),
        throwsA(anything),
      );
    });
  });

  group('AppDatabase — notation_custom_fields table', () {
    late AppDatabase db;

    setUp(() async {
      db = _openInMemory();
      await db.into(db.notationsTable).insert(
            NotationsTableCompanion.insert(
              id: 'n1',
              title: 'Yaman',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'cfd1',
              keyName: 'raga_number',
              fieldType: 'number',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );
    });
    tearDown(() => db.close());

    test('inserts a custom field value', () async {
      await db.into(db.notationCustomFieldsTable).insert(
            NotationCustomFieldsTableCompanion.insert(
              notationId: 'n1',
              definitionId: 'cfd1',
            ),
          );

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows, hasLength(1));
    });

    test('ON DELETE CASCADE removes value when notation deleted', () async {
      await db.into(db.notationCustomFieldsTable).insert(
            NotationCustomFieldsTableCompanion.insert(
              notationId: 'n1',
              definitionId: 'cfd1',
            ),
          );

      await (db.delete(db.notationsTable)..where((t) => t.id.equals('n1')))
          .go();

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows, isEmpty);
    });

    test('ON DELETE CASCADE removes value when definition deleted', () async {
      await db.into(db.notationCustomFieldsTable).insert(
            NotationCustomFieldsTableCompanion.insert(
              notationId: 'n1',
              definitionId: 'cfd1',
            ),
          );

      await (db.delete(db.customFieldDefinitionsTable)
            ..where((t) => t.id.equals('cfd1')))
          .go();

      final rows = await db.select(db.notationCustomFieldsTable).get();
      expect(rows, isEmpty);
    });
  });

  group('AppDatabase — user_preferences table', () {
    late AppDatabase db;

    setUp(() => db = _openInMemory());
    tearDown(() => db.close());

    test('inserts singleton row with id = 1', () async {
      await db.into(db.userPreferencesTable).insert(
            const UserPreferencesTableCompanion(
              userName: Value('Roudranil'),
            ),
          );

      final rows = await db.select(db.userPreferencesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 1);
    });

    test('singleton CHECK rejects id != 1', () async {
      expect(
        () => db.into(db.userPreferencesTable).insert(
              const UserPreferencesTableCompanion(
                id: Value(2),
                userName: Value('Other'),
              ),
            ),
        throwsA(anything),
      );
    });

    test('second insert with id = 1 is rejected (unique PK)', () async {
      await db.into(db.userPreferencesTable).insert(
            const UserPreferencesTableCompanion(
              userName: Value('Roudranil'),
            ),
          );

      expect(
        () => db.into(db.userPreferencesTable).insert(
              const UserPreferencesTableCompanion(
                userName: Value('Another'),
              ),
            ),
        throwsA(anything),
      );
    });

    test('default values applied on insert', () async {
      await db.into(db.userPreferencesTable).insert(
            const UserPreferencesTableCompanion(),
          );

      final row = await (db.select(db.userPreferencesTable)).getSingle();
      expect(row.themeMode, 'system');
      expect(row.colorSchemeMode, 'catppuccin');
      expect(row.defaultSort, 'created_at_desc');
      expect(row.defaultView, 'list');
    });
  });
}
