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

import 'package:swaralipi/core/database/daos/instrument_dao.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/core/database/daos/notation_page_dao.dart';
import 'package:swaralipi/core/database/daos/notation_tag_dao.dart';
import 'package:swaralipi/core/database/daos/tag_dao.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Stores notation metadata. Soft-deleted rows set [deletedAt]; all
/// repository queries default-filter `WHERE deleted_at IS NULL`.
@DataClassName('NotationRow')
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
@DataClassName('NotationPageRow')
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
@DataClassName('NotationTagRow')
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
@DataClassName('InstrumentInstanceRow')
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
@DataClassName('NotationInstrumentRow')
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
@DataClassName('NotationCustomFieldRow')
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
      ];
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

/// Drift database singleton for Swaralipi.
///
/// Holds all table definitions and exposes a [forTesting] named constructor
/// for in-memory test instances. Seed data (default tags and user prefs row)
/// is inserted during [onCreate] in production; tests start with an empty
/// schema and insert only what each test case requires.
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
  AppDatabase.forTesting()
      : _seedOnCreate = false,
        super(
          NativeDatabase.memory(
            setup: (db) => db.execute('PRAGMA foreign_keys = ON;'),
          ),
        );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          if (_seedOnCreate) {
            await _seedInitialData();
          }
        },
      );

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

    // 5 default tags (Catppuccin Mocha palette)
    const defaultTags = [
      ('tag-default-1', 'Raag', '#f38ba8'),
      ('tag-default-2', 'Bhajan', '#a6e3a1'),
      ('tag-default-3', 'Classical', '#89b4fa'),
      ('tag-default-4', 'Folk', '#fab387'),
      ('tag-default-5', 'Devotional', '#cba6f7'),
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
