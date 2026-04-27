// AppDatabase — Drift database definition for Swaralipi.
//
// Declares all 10 table classes, foreign key relationships, ON DELETE
// behaviours, UNIQUE constraints, and CHECK constraints as specified in
// docs/02-technical/data-model.md §2.1–§2.10.
//
// Generated code lives in app_database.g.dart (run
// `dart run build_runner build --delete-conflicting-outputs` to regenerate).

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:swaralipi/core/database/daos/custom_field_dao.dart';
import 'package:swaralipi/core/database/daos/fts_dao.dart';
import 'package:swaralipi/core/database/daos/instrument_dao.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/core/database/daos/notation_page_dao.dart';
import 'package:swaralipi/core/database/daos/notation_tag_dao.dart';
import 'package:swaralipi/core/database/daos/tag_dao.dart';
import 'package:swaralipi/core/database/daos/user_preferences_dao.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Stores notation metadata. Soft-deleted rows set [deletedAt]; all
/// repository queries default-filter `WHERE deleted_at IS NULL`.
///
/// Three partial indexes optimise the hot read paths described in
/// data-model.md §4:
/// - [idx_notations_active_updated]: library list sorted by update time
/// - [idx_notations_last_played]: recently-played carousel
/// - [idx_notations_deleted]: trash screen sorted by deletion date
@DataClassName('NotationRow')
@TableIndex.sql(
  'CREATE INDEX idx_notations_active_updated ON notations_table'
  ' (deleted_at, updated_at DESC)'
  ' WHERE deleted_at IS NULL',
)
@TableIndex.sql(
  'CREATE INDEX idx_notations_last_played ON notations_table'
  ' (deleted_at, last_played_at DESC)'
  ' WHERE deleted_at IS NULL AND last_played_at IS NOT NULL',
)
@TableIndex.sql(
  'CREATE INDEX idx_notations_deleted ON notations_table'
  ' (deleted_at DESC)'
  ' WHERE deleted_at IS NOT NULL',
)
class NotationsTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Human-readable title for the notation piece.
  TextColumn get title => text()();

  /// JSON array of artist name strings, e.g. `["Ravi Shankar"]`.
  TextColumn get artists => text().withDefault(const Constant('[]'))();

  /// ISO 8601 date (YYYY-MM-DD); nullable.
  TextColumn get dateWritten => text().nullable()();

  /// Time signature string, e.g. `'4/4'`; nullable.
  TextColumn get timeSig => text().nullable()();

  /// Key signature string, e.g. `'C'` or `'Bb minor'`; nullable.
  TextColumn get keySig => text().nullable()();

  /// JSON array of language strings, e.g. `["Hindi"]`.
  TextColumn get languages => text().withDefault(const Constant('[]'))();

  /// Free-form personal notes about the notation.
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Number of times the notation has been played.
  IntColumn get playCount => integer().withDefault(const Constant(0))();

  /// ISO 8601 datetime of last play; nullable.
  TextColumn get lastPlayedAt => text().nullable()();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime of last update.
  TextColumn get updatedAt => text()();

  /// Soft-delete timestamp. NULL means active; non-NULL means deleted.
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores individual page images for a notation.
///
/// Each page is ordered within its notation via [pageOrder] (0-indexed).
/// Pages cascade-delete when their parent notation is hard-deleted.
///
/// [idx_pages_notation_order] optimises joins that fetch all pages for a
/// given notation in display order (data-model.md §4).
@DataClassName('NotationPageRow')
@TableIndex.sql(
  'CREATE INDEX idx_pages_notation_order ON notation_pages_table'
  ' (notation_id, page_order ASC)',
)
class NotationPagesTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Foreign key to the parent [NotationsTable] row.
  TextColumn get notationId =>
      text().references(NotationsTable, #id, onDelete: KeyAction.cascade)();

  /// 0-indexed position of this page within the notation.
  IntColumn get pageOrder => integer()();

  /// Path relative to `getApplicationDocumentsDirectory()`.
  TextColumn get imagePath => text()();

  /// Serialised [RenderParams] JSON; non-destructive render settings.
  TextColumn get renderParams => text().withDefault(const Constant('{}'))();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {notationId, pageOrder},
      ];
}

/// Stores user-defined tags for categorising notations.
///
/// Each tag has a unique [name] and a Catppuccin [colorHex].
@DataClassName('TagRow')
class TagsTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Unique display name of the tag.
  TextColumn get name => text().unique()();

  /// Catppuccin hex color string, e.g. `'#f38ba8'`.
  TextColumn get colorHex => text()();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime of last update.
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many join between [NotationsTable] and [TagsTable].
///
/// Both sides cascade-delete: removing a notation or a tag silently removes
/// the corresponding join rows.
///
/// [idx_notation_tags_notation] optimises queries that look up all tags for
/// a given notation (data-model.md §4).
@DataClassName('NotationTagRow')
@TableIndex.sql(
  'CREATE INDEX idx_notation_tags_notation ON notation_tags_table'
  ' (notation_id)',
)
class NotationTagsTable extends Table {
  /// Foreign key to [NotationsTable].
  TextColumn get notationId =>
      text().references(NotationsTable, #id, onDelete: KeyAction.cascade)();

  /// Foreign key to [TagsTable].
  TextColumn get tagId =>
      text().references(TagsTable, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {notationId, tagId};
}

/// Stores instrument class definitions (e.g. String, Wind, Percussion).
///
/// Deleting a class is blocked while any [InstrumentInstancesTable] rows
/// reference it (ON DELETE RESTRICT).
@DataClassName('InstrumentClassRow')
class InstrumentClassesTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Unique human-readable class name.
  TextColumn get name => text().unique()();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime of last update.
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stores individual instrument instances owned by the user.
///
/// Soft-deleted (archived) instances retain their rows so existing notation
/// associations remain visible. Deletion of the parent class is blocked
/// (RESTRICT) while instances exist.
///
/// [idx_instances_class] optimises queries that list instances by class
/// (e.g. the instrument picker filtered by type) (data-model.md §4).
@DataClassName('InstrumentInstanceRow')
@TableIndex.sql(
  'CREATE INDEX idx_instances_class ON instrument_instances_table'
  ' (class_id, deleted_at)',
)
class InstrumentInstancesTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Foreign key to [InstrumentClassesTable]. Deletion blocked (RESTRICT).
  TextColumn get classId => text().references(
        InstrumentClassesTable,
        #id,
        onDelete: KeyAction.restrict,
      )();

  /// Optional brand name; nullable.
  TextColumn get brand => text().nullable()();

  /// Optional model name; nullable.
  TextColumn get model => text().nullable()();

  /// Catppuccin hex color string for UI display.
  TextColumn get colorHex => text()();

  /// Purchase price in INR (integer paise); nullable.
  IntColumn get priceInr => integer().nullable()();

  /// Relative path to a photo of the instrument; nullable.
  TextColumn get photoPath => text().nullable()();

  /// Free-form notes about this instance.
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime of last update.
  TextColumn get updatedAt => text()();

  /// Soft-delete / archive timestamp. NULL means active.
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Many-to-many join between [NotationsTable] and [InstrumentInstancesTable].
///
/// Notation side cascades on hard-delete; instrument side restricts (archived
/// instances are never hard-deleted, so RESTRICT is rarely triggered).
///
/// [idx_notation_instruments_notation] optimises joins fetching all
/// instrument associations for a notation (data-model.md §4).
@DataClassName('NotationInstrumentRow')
@TableIndex.sql(
  'CREATE INDEX idx_notation_instruments_notation'
  ' ON notation_instruments_table (notation_id)',
)
class NotationInstrumentsTable extends Table {
  /// Foreign key to [NotationsTable]. Cascade on notation delete.
  TextColumn get notationId =>
      text().references(NotationsTable, #id, onDelete: KeyAction.cascade)();

  /// Foreign key to [InstrumentInstancesTable]. Restricted.
  TextColumn get instanceId => text().references(
        InstrumentInstancesTable,
        #id,
        onDelete: KeyAction.restrict,
      )();

  @override
  Set<Column> get primaryKey => {notationId, instanceId};
}

/// Defines the schema for user-defined custom metadata fields.
///
/// [fieldType] is constrained to `'text' | 'number' | 'date' | 'boolean'`.
/// The CHECK constraint is enforced at the app layer; SQLite CHECK enforcement
/// depends on the runtime configuration.
@DataClassName('CustomFieldDefinitionRow')
class CustomFieldDefinitionsTable extends Table {
  /// UUIDv4 generated at the app layer.
  TextColumn get id => text()();

  /// Unique machine-readable key for this field.
  TextColumn get keyName => text().unique()();

  /// Type of the field: one of `text`, `number`, `date`, `boolean`.
  TextColumn get fieldType => text()();

  /// ISO 8601 datetime when the row was created.
  TextColumn get createdAt => text()();

  /// ISO 8601 datetime of last update.
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        "CHECK (field_type IN ('text', 'number', 'date', 'boolean'))",
      ];
}

/// Stores per-notation values for custom fields.
///
/// Sparse column design: only the column matching [fieldType] in the linked
/// [CustomFieldDefinitionsTable] row is populated; all others are NULL.
/// Both foreign keys cascade on delete.
///
/// [idx_custom_fields_notation] optimises queries that fetch all custom
/// field values for a given notation (data-model.md §4).
@DataClassName('NotationCustomFieldRow')
@TableIndex.sql(
  'CREATE INDEX idx_custom_fields_notation ON notation_custom_fields_table'
  ' (notation_id)',
)
class NotationCustomFieldsTable extends Table {
  /// Foreign key to [NotationsTable]. Cascade on notation delete.
  TextColumn get notationId =>
      text().references(NotationsTable, #id, onDelete: KeyAction.cascade)();

  /// Foreign key to [CustomFieldDefinitionsTable]. Cascade on definition
  /// delete.
  TextColumn get definitionId => text().references(
        CustomFieldDefinitionsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// Value column for `field_type = 'text'`; nullable.
  TextColumn get valueText => text().nullable()();

  /// Value column for `field_type = 'number'`; nullable.
  RealColumn get valueNumber => real().nullable()();

  /// ISO 8601 date value for `field_type = 'date'`; nullable.
  TextColumn get valueDate => text().nullable()();

  /// 0 or 1 boolean value for `field_type = 'boolean'`; nullable.
  IntColumn get valueBoolean => integer().nullable()();

  @override
  Set<Column> get primaryKey => {notationId, definitionId};
}

/// Singleton user preference row.
///
/// The `CHECK (id = 1)` constraint is declared in [customConstraints] and
/// enforced at DB level. [UserPreferencesTable] is inserted with defaults
/// during migration v1 initialisation.
@DataClassName('UserPreferencesRow')
class UserPreferencesTable extends Table {
  /// Always 1 — singleton enforced by CHECK constraint and PRIMARY KEY.
  ///
  /// [withDefault] of `1` means the column is optional in companions; callers
  /// that omit [id] automatically get the correct singleton value.
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// Display name shown in the app.
  TextColumn get userName => text().withDefault(const Constant('Musician'))();

  /// Theme mode: `'light'`, `'dark'`, or `'system'`.
  TextColumn get themeMode => text().withDefault(const Constant('system'))();

  /// Color scheme source: `'catppuccin'` or `'monet'`.
  TextColumn get colorSchemeMode =>
      text().withDefault(const Constant('catppuccin'))();

  /// Catppuccin hex used when [colorSchemeMode] is `'catppuccin'`; nullable.
  TextColumn get seedColor => text().nullable()();

  /// Default sort order for the notation library.
  TextColumn get defaultSort =>
      text().withDefault(const Constant('created_at_desc'))();

  /// Default library view: `'list'` (grid deferred to v2).
  TextColumn get defaultView => text().withDefault(const Constant('list'))();

  /// Whether the 5 default tags have been seeded on this install.
  ///
  /// `0` = not seeded, `1` = seeded. Stored as INTEGER for SQLite
  /// compatibility; treated as [bool] at the app layer.
  IntColumn get tagsSeeded => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
        'CHECK (id = 1)',
        "CHECK (theme_mode IN ('light', 'dark', 'system'))",
        "CHECK (color_scheme_mode IN ('catppuccin', 'monet'))",
        'CHECK (default_sort IN ('
            "'created_at_desc', 'created_at_asc', "
            "'date_written_desc', 'date_written_asc', "
            "'title_asc', 'title_desc', "
            "'play_count_desc', 'last_played_at_desc'"
            '))',
        "CHECK (default_view IN ('list'))",
        'CHECK (tags_seeded IN (0, 1))',
      ];
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

/// Drift database singleton for Swaralipi.
///
/// Holds all 10 table definitions, 8 index declarations, and the FTS5 virtual
/// table + 3 sync triggers created by [createFtsSchema].
///
/// ## Schema versioning policy
///
/// Every schema change MUST:
/// 1. Increment [schemaVersion] by 1.
/// 2. Add a migration function in the [MigrationStrategy.onUpgrade] switch
///    block that transforms the database from `from` to `to`.
/// 3. Have a corresponding migration test in
///    `test/unit/core/database/migration_test.dart` that calls
///    [validateDatabaseSchema] after running the migration.
///
/// No destructive migrations (`DROP TABLE`, `DROP COLUMN`) without a
/// data-safe alternative. See data-model.md §7 for the full policy.
///
/// | schemaVersion | Change |
/// |---|---|
/// | 1 | Initial schema: all tables, FTS5, triggers, indexes, seed data |
/// | 2 | Add `tags_seeded` column to `user_preferences_table` |
@DriftDatabase(
  tables: [
    NotationsTable,
    NotationPagesTable,
    TagsTable,
    NotationTagsTable,
    InstrumentClassesTable,
    InstrumentInstancesTable,
    NotationInstrumentsTable,
    CustomFieldDefinitionsTable,
    NotationCustomFieldsTable,
    UserPreferencesTable,
  ],
  daos: [
    NotationDao,
    NotationPageDao,
    TagDao,
    NotationTagDao,
    InstrumentDao,
    CustomFieldDao,
    UserPreferencesDao,
    FtsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Whether to insert seed data when the schema is first created.
  final bool _seedOnCreate;

  /// Creates the production [AppDatabase] backed by a file on disk.
  AppDatabase()
      : _seedOnCreate = true,
        super(_openConnection());

  /// Creates an [AppDatabase] backed by an in-memory SQLite instance.
  ///
  /// Used exclusively in unit tests. Foreign keys are enabled via the
  /// [DatabaseSetup] callback. Seed data is skipped so each test starts with
  /// an empty, predictable schema.
  ///
  /// After constructing a test database, callers that require FTS5 search
  /// must call [createFtsSchema] once after the first query to set up the
  /// virtual table and triggers on the fully-open connection.
  AppDatabase.forTesting()
      : _seedOnCreate = false,
        super(
          NativeDatabase.memory(
            setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
          ),
        );

  /// Creates an [AppDatabase] backed by an in-memory SQLite instance with
  /// seed data inserted on [onCreate].
  ///
  /// Used exclusively in migration tests that need to verify the seed data
  /// produced by [MigrationStrategy.onCreate]. Regular DAO unit tests should
  /// use [AppDatabase.forTesting] instead, which starts with an empty schema.
  ///
  /// After constructing, callers that require FTS5 search must call
  /// [createFtsSchema] once after the first query.
  AppDatabase.forTestingWithSeed()
      : _seedOnCreate = true,
        super(
          NativeDatabase.memory(
            setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
          ),
        );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Creates all tables and indexes declared in the @DriftDatabase
          // annotation. For schema v2 this is the only migration path for new
          // installs.
          await m.createAll();
          if (_seedOnCreate) {
            await _seedInitialData();
          }
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: add tags_seeded column to user_preferences_table.
          if (from < 2) {
            await m.addColumn(
              userPreferencesTable,
              userPreferencesTable.tagsSeeded,
            );
          }
        },
        beforeOpen: (details) async {
          // FTS schema is created here for the production (file-based) database.
          // Test databases created with [AppDatabase.forTesting] must call
          // [createFtsSchema] explicitly from test setUp after opening, because
          // Drift's BeforeOpenRunner zone prevents DDL for virtual tables from
          // executing on NativeDatabase.memory connections.
          if (details.wasCreated && _seedOnCreate) {
            await createFtsSchema();
          }
        },
      );

  /// Creates the FTS5 virtual table and sync triggers on the open connection.
  ///
  /// Called automatically from [MigrationStrategy.onCreate] in production.
  /// Tests that use [AppDatabase.forTesting] and require FTS search must call
  /// this method once after opening the database (after the first query that
  /// triggers schema creation), because Drift's [BeforeOpenRunner] zone
  /// prevents DDL statements for virtual tables from running inside
  /// [MigrationStrategy.onCreate] on in-memory [NativeDatabase.memory]
  /// connections.
  ///
  /// The method is idempotent — it uses `IF NOT EXISTS` guards on all
  /// statements and is safe to call multiple times.
  Future<void> createFtsSchema() async {
    // Drift generates the SQLite table name as 'notations_table' (not
    // 'notations') for the NotationsTable class. All FTS5 DDL uses this name.
    await customStatement(
      'CREATE VIRTUAL TABLE IF NOT EXISTS notations_fts'
      ' USING fts5('
      'title, artists, notes,'
      " content='notations_table',"
      " content_rowid='rowid',"
      " tokenize='unicode61'"
      ')',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notations_ai'
      ' AFTER INSERT ON notations_table BEGIN'
      ' INSERT INTO notations_fts(rowid, title, artists, notes)'
      ' VALUES (new.rowid, new.title, new.artists, new.notes);'
      ' END',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notations_ad'
      ' AFTER DELETE ON notations_table BEGIN'
      ' INSERT INTO notations_fts(notations_fts, rowid, title, artists,'
      ' notes)'
      " VALUES ('delete', old.rowid, old.title, old.artists, old.notes);"
      ' END',
    );
    await customStatement(
      'CREATE TRIGGER IF NOT EXISTS notations_au'
      ' AFTER UPDATE ON notations_table BEGIN'
      ' INSERT INTO notations_fts(notations_fts, rowid, title, artists,'
      ' notes)'
      " VALUES ('delete', old.rowid, old.title, old.artists, old.notes);"
      ' INSERT INTO notations_fts(rowid, title, artists, notes)'
      ' VALUES (new.rowid, new.title, new.artists, new.notes);'
      ' END',
    );
  }

  /// Creates the FTS5 virtual table and the three sync triggers.
  ///
  /// The virtual table `notations_fts` indexes the [NotationsTable] columns
  /// `title`, `artists`, and `notes` using the `unicode61` tokenizer, which
  /// handles Hindi and Bengali text correctly (data-model.md §2.11).
  ///
  /// Three triggers keep the FTS index in sync with the `notations` table:
  /// - `notations_ai` — AFTER INSERT: adds the new row to FTS.
  /// - `notations_ad` — AFTER DELETE: removes the deleted row from FTS.
  /// - `notations_au` — AFTER UPDATE: removes the old row and adds the new
  ///   one, effectively replacing the FTS entry.
  ///
  /// Soft-deleted rows are NOT filtered out here; they remain in the FTS
  /// index. The `FtsDao.search` query applies `WHERE deleted_at IS NULL`
  /// via a JOIN to exclude them at query time (data-model.md §2.11).

  /// Seeds required initial data after the schema is created for the first
  /// time.
  ///
  /// Inserts the singleton [UserPreferencesTable] row and the 5 default tags
  /// as specified in data-model.md §2.3 and §2.10.
  Future<void> _seedInitialData() async {
    // Singleton user preferences row — id defaults to 1 via column default.
    await into(userPreferencesTable).insert(
      const UserPreferencesTableCompanion(),
    );

    // 5 default tags (Catppuccin Mocha palette) — names from issue #75.
    const defaultTags = [
      ('tag-default-1', 'Ragas', '#f38ba8'),
      ('tag-default-2', 'Bhajans', '#a6e3a1'),
      ('tag-default-3', 'Bandishes', '#89b4fa'),
      ('tag-default-4', 'Thumri', '#fab387'),
      ('tag-default-5', 'Exercises', '#cba6f7'),
    ];

    for (final (id, name, color) in defaultTags) {
      final now = DateTime.now().toUtc().toIso8601String();
      await into(tagsTable).insert(
        TagsTableCompanion.insert(
          id: id,
          name: name,
          colorHex: color,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

/// Opens the on-disk SQLite connection for production use.
QueryExecutor _openConnection() {
  return driftDatabase(name: 'swaralipi_db');
}
