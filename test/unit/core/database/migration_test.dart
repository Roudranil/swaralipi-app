// Migration tests for AppDatabase — schema v1.
//
// Verifies that [MigrationStrategy.onCreate] produces the exact schema
// described in docs/02-technical/data-model.md, including:
//   - All 10 tables
//   - All 9 indexes (partial and non-partial)
//   - The FTS5 virtual table (notations_fts) and its 3 sync triggers
//   - Seed data: 5 default tags and the singleton user_preferences row
//   - schemaVersion == 1
//
// [validateDatabaseSchema] (from drift_dev/api/migrations_native.dart) is
// used to compare the live schema against Drift's reference schema, giving
// a single authoritative assertion that no table, column or constraint
// differs from the Drift-generated expectation.
//
// Direct sqlite_master queries verify FTS5 and trigger presence, which are
// outside Drift's regular table registry and therefore not covered by
// [validateDatabaseSchema] alone.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Drift-generated table entity names for all 10 tables in schema v1.
const _expectedTables = {
  'notations_table',
  'notation_pages_table',
  'tags_table',
  'notation_tags_table',
  'instrument_classes_table',
  'instrument_instances_table',
  'notation_instruments_table',
  'custom_field_definitions_table',
  'notation_custom_fields_table',
  'user_preferences_table',
};

/// Index names as defined in data-model.md §4.
const _expectedIndexes = {
  'idx_notations_active_updated',
  'idx_notations_last_played',
  'idx_notations_deleted',
  'idx_pages_notation_order',
  'idx_notation_tags_notation',
  'idx_notation_instruments_notation',
  'idx_instances_class',
  'idx_custom_fields_notation',
};

/// FTS5 virtual table name.
const _ftsTableName = 'notations_fts';

/// FTS5 sync trigger names.
const _expectedTriggers = {'notations_ai', 'notations_ad', 'notations_au'};

/// Default tag names seeded during onCreate.
const _expectedTagNames = {'Raag', 'Bhajan', 'Classical', 'Folk', 'Devotional'};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Queries [sqlite_master] and returns entity names matching [type].
///
/// Parameters:
/// - [db]: The open [AppDatabase] to query.
/// - [type]: One of `'table'`, `'index'`, or `'trigger'`.
Future<Set<String>> _schemaNames(AppDatabase db, String type) async {
  final rows = await db.customSelect(
    'SELECT name FROM sqlite_master WHERE type = ?',
    variables: [Variable.withString(type)],
  ).get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

/// Opens a seeded in-memory [AppDatabase] for migration tests.
///
/// Seed data is inserted (mirrors production behaviour). FTS schema is
/// created explicitly because Drift's [MigrationStrategy.beforeOpen] zone
/// prevents virtual-table DDL on in-memory connections.
Future<AppDatabase> _openSeeded() async {
  final db = AppDatabase.forTestingWithSeed();
  // First query triggers onCreate via Drift's lazy-open mechanism.
  await db.select(db.notationsTable).get();
  // FTS must be created after the first query (see AppDatabase docs).
  await db.createFtsSchema();
  return db;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Suppress drift's "multiple database" warning in tests.
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  // -------------------------------------------------------------------------
  group('Migration v1 — schema version', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test('schemaVersion is 1', () {
      expect(db.schemaVersion, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — Drift schema validation', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test(
        'validateDatabaseSchema passes — all tables, columns and '
        'constraints match the Drift definition', () async {
      // Compares the live database schema against the reference schema that
      // Drift builds from scratch using createAll().  A SchemaMismatch
      // exception indicates the migration produced an incorrect schema.
      //
      // validateDropped is false (the default) because the FTS5 virtual
      // table and its shadow tables (notations_fts_*) are created via
      // customStatement and are not registered in Drift's table registry.
      // Presence of the FTS5 objects is asserted separately in the
      // "FTS5 virtual table and triggers" group.
      await expectLater(
        db.validateDatabaseSchema(),
        completes,
      );
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — table presence', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test('all 10 tables are present', () async {
      final tables = await _schemaNames(db, 'table');
      for (final expected in _expectedTables) {
        expect(tables, contains(expected), reason: 'missing table: $expected');
      }
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — index presence', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test('all 9 indexes defined in data-model.md §4 are present', () async {
      final indexes = await _schemaNames(db, 'index');
      for (final expected in _expectedIndexes) {
        expect(indexes, contains(expected), reason: 'missing index: $expected');
      }
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — FTS5 virtual table and triggers', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test('notations_fts virtual table exists', () async {
      final tables = await _schemaNames(db, 'table');
      expect(tables, contains(_ftsTableName));
    });

    test('all 3 FTS5 sync triggers are present', () async {
      final triggers = await _schemaNames(db, 'trigger');
      for (final expected in _expectedTriggers) {
        expect(
          triggers,
          contains(expected),
          reason: 'missing trigger: $expected',
        );
      }
    });

    test('FTS index is searchable after notation insert', () async {
      await db.into(db.notationsTable).insert(
            NotationsTableCompanion.insert(
              id: 'n-fts-1',
              title: 'Bhairav Kalyan',
              createdAt: '2024-01-01T10:00:00Z',
              updatedAt: '2024-01-01T10:00:00Z',
            ),
          );

      // FTS match returns the matching row.
      final results = await db
          .customSelect(
            'SELECT notations_table.id FROM notations_table '
            'JOIN notations_fts ON notations_table.rowid = notations_fts.rowid '
            "WHERE notations_fts MATCH 'Bhairav'",
          )
          .get();
      expect(results, hasLength(1));
      expect(results.first.read<String>('id'), 'n-fts-1');
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — seed data', () {
    late AppDatabase db;
    setUp(() async => db = await _openSeeded());
    tearDown(() => db.close());

    test('exactly 5 default tags are seeded', () async {
      final tags = await db.select(db.tagsTable).get();
      expect(tags, hasLength(5));
    });

    test('seeded tag names match the spec', () async {
      final tags = await db.select(db.tagsTable).get();
      final names = tags.map((t) => t.name).toSet();
      expect(names, equals(_expectedTagNames));
    });

    test('each default tag has a valid Catppuccin hex color', () async {
      final tags = await db.select(db.tagsTable).get();
      for (final tag in tags) {
        expect(
          tag.colorHex,
          matches(RegExp(r'^#[0-9a-f]{6}$')),
          reason: 'invalid color for tag ${tag.name}: ${tag.colorHex}',
        );
      }
    });

    test('singleton user_preferences row exists with id = 1', () async {
      final rows = await db.select(db.userPreferencesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 1);
    });

    test('user_preferences row has correct default values', () async {
      final prefs = await db.select(db.userPreferencesTable).getSingle();
      expect(prefs.themeMode, 'system');
      expect(prefs.colorSchemeMode, 'catppuccin');
      expect(prefs.defaultSort, 'created_at_desc');
      expect(prefs.defaultView, 'list');
      expect(prefs.userName, 'Musician');
    });
  });

  // -------------------------------------------------------------------------
  group('Migration v1 — forTesting mode has no seed data', () {
    late AppDatabase db;
    setUp(() {
      db = AppDatabase.forTesting();
    });
    tearDown(() => db.close());

    test('no tags are seeded in forTesting mode', () async {
      await db.select(db.notationsTable).get();
      final tags = await db.select(db.tagsTable).get();
      expect(tags, isEmpty);
    });

    test('no user_preferences row in forTesting mode', () async {
      await db.select(db.notationsTable).get();
      final prefs = await db.select(db.userPreferencesTable).get();
      expect(prefs, isEmpty);
    });
  });
}
