// CustomFieldDao — Drift DAO for the custom_field_definitions and
// notation_custom_fields tables.
//
// Exposes all CRUD and value-write operations required by the
// CustomFieldRepository. All queries use Drift's type-safe query DSL; no raw
// SQL strings are used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `CustomFieldDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'custom_field_dao.g.dart';

/// Data-access object for the [CustomFieldDefinitionsTable] and
/// [NotationCustomFieldsTable].
///
/// Manages custom field definitions (insert, update, delete, list) and their
/// per-notation values via [setCustomFieldValue] and [getValuesForNotation].
/// Sparse column writes are enforced here: only the column matching
/// [fieldType] is populated; all others remain NULL.
///
/// Business logic and domain-model translation belong in the repository layer,
/// not here.
@DriftAccessor(
  tables: [CustomFieldDefinitionsTable, NotationCustomFieldsTable],
)
class CustomFieldDao extends DatabaseAccessor<AppDatabase>
    with _$CustomFieldDaoMixin {
  /// Creates a [CustomFieldDao] attached to [db].
  CustomFieldDao(super.db);

  // -------------------------------------------------------------------------
  // Definition write operations
  // -------------------------------------------------------------------------

  /// Inserts a new custom field definition row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation) or if
  /// [companion.keyName] already exists (UNIQUE constraint on key_name).
  ///
  /// Parameters:
  /// - [companion]: A fully populated
  ///   [CustomFieldDefinitionsTableCompanion].
  Future<void> insertDefinition(
    CustomFieldDefinitionsTableCompanion companion,
  ) async {
    await into(customFieldDefinitionsTable).insert(companion);
    log(
      'CustomFieldDao: inserted definition ${companion.id.value}',
      name: 'CustomFieldDao',
    );
  }

  /// Updates an existing custom field definition row.
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [CustomFieldDefinitionsTableCompanion] with
  ///   [companion.id] set to identify the target row.
  Future<bool> updateDefinition(
    CustomFieldDefinitionsTableCompanion companion,
  ) async {
    final rowsAffected = await (update(customFieldDefinitionsTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Permanently deletes the definition row with [id].
  ///
  /// All associated [NotationCustomFieldsTable] rows cascade-delete
  /// automatically via the `ON DELETE CASCADE` foreign key constraint. If no
  /// row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the definition to delete.
  Future<void> deleteDefinition(String id) async {
    await (delete(customFieldDefinitionsTable)..where((t) => t.id.equals(id)))
        .go();
    log('CustomFieldDao: deleted definition $id', name: 'CustomFieldDao');
  }

  // -------------------------------------------------------------------------
  // Definition read operations
  // -------------------------------------------------------------------------

  /// Returns all custom field definition rows, ordered by
  /// [CustomFieldDefinitionsTable.keyName] ascending.
  Future<List<CustomFieldDefinitionRow>> getAllDefinitions() {
    return (select(customFieldDefinitionsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.keyName)]))
        .get();
  }

  /// Emits a live list of all custom field definition rows, ordered by
  /// [CustomFieldDefinitionsTable.keyName] ascending.
  ///
  /// The stream re-emits whenever the underlying table changes.
  Stream<List<CustomFieldDefinitionRow>> watchAllDefinitions() {
    return (select(customFieldDefinitionsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.keyName)]))
        .watch();
  }

  // -------------------------------------------------------------------------
  // Value write operations
  // -------------------------------------------------------------------------

  /// Inserts or replaces the custom field value for the given notation and
  /// definition pair.
  ///
  /// Enforces the sparse column contract: only the value column matching
  /// [fieldType] is populated; all other value columns are set to NULL. This
  /// prevents cross-type pollution as required by data-model.md §2.9.
  ///
  /// Throws [ArgumentError] if [fieldType] is not one of `'text'`, `'number'`,
  /// `'date'`, or `'boolean'`.
  ///
  /// Parameters:
  /// - [notationId]: FK to the parent [NotationsTable] row.
  /// - [definitionId]: FK to the [CustomFieldDefinitionsTable] row.
  /// - [fieldType]: One of `'text'`, `'number'`, `'date'`, `'boolean'`.
  /// - [textValue]: Value to store when [fieldType] is `'text'`.
  /// - [numberValue]: Value to store when [fieldType] is `'number'`.
  /// - [dateValue]: ISO 8601 date string when [fieldType] is `'date'`.
  /// - [booleanValue]: Boolean value when [fieldType] is `'boolean'`.
  Future<void> setCustomFieldValue({
    required String notationId,
    required String definitionId,
    required String fieldType,
    String? textValue,
    double? numberValue,
    String? dateValue,
    bool? booleanValue,
  }) async {
    final companion = _buildValueCompanion(
      notationId: notationId,
      definitionId: definitionId,
      fieldType: fieldType,
      textValue: textValue,
      numberValue: numberValue,
      dateValue: dateValue,
      booleanValue: booleanValue,
    );
    await into(notationCustomFieldsTable).insertOnConflictUpdate(companion);
    log(
      'CustomFieldDao: set value for notation=$notationId '
      'definition=$definitionId type=$fieldType',
      name: 'CustomFieldDao',
    );
  }

  // -------------------------------------------------------------------------
  // Value read operations
  // -------------------------------------------------------------------------

  /// Returns all custom field value rows for [notationId].
  ///
  /// Returns an empty list when no values have been set for the notation.
  ///
  /// Parameters:
  /// - [notationId]: FK to the parent [NotationsTable] row.
  Future<List<NotationCustomFieldRow>> getValuesForNotation(
    String notationId,
  ) {
    return (select(notationCustomFieldsTable)
          ..where((t) => t.notationId.equals(notationId)))
        .get();
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Builds a [NotationCustomFieldsTableCompanion] with sparse column
  /// population based on [fieldType].
  ///
  /// Only the value column matching [fieldType] receives a [Value]; all
  /// others are explicitly set to [Value(null)] to clear stale data on upsert.
  ///
  /// Parameters:
  /// - [notationId]: FK to the parent [NotationsTable] row.
  /// - [definitionId]: FK to the [CustomFieldDefinitionsTable] row.
  /// - [fieldType]: One of `'text'`, `'number'`, `'date'`, `'boolean'`.
  /// - [textValue]: Value used when [fieldType] is `'text'`.
  /// - [numberValue]: Value used when [fieldType] is `'number'`.
  /// - [dateValue]: Value used when [fieldType] is `'date'`.
  /// - [booleanValue]: Value used when [fieldType] is `'boolean'`.
  NotationCustomFieldsTableCompanion _buildValueCompanion({
    required String notationId,
    required String definitionId,
    required String fieldType,
    String? textValue,
    double? numberValue,
    String? dateValue,
    bool? booleanValue,
  }) {
    return switch (fieldType) {
      'text' => NotationCustomFieldsTableCompanion.insert(
          notationId: notationId,
          definitionId: definitionId,
          valueText: Value(textValue),
          valueNumber: const Value(null),
          valueDate: const Value(null),
          valueBoolean: const Value(null),
        ),
      'number' => NotationCustomFieldsTableCompanion.insert(
          notationId: notationId,
          definitionId: definitionId,
          valueText: const Value(null),
          valueNumber: Value(numberValue),
          valueDate: const Value(null),
          valueBoolean: const Value(null),
        ),
      'date' => NotationCustomFieldsTableCompanion.insert(
          notationId: notationId,
          definitionId: definitionId,
          valueText: const Value(null),
          valueNumber: const Value(null),
          valueDate: Value(dateValue),
          valueBoolean: const Value(null),
        ),
      'boolean' => NotationCustomFieldsTableCompanion.insert(
          notationId: notationId,
          definitionId: definitionId,
          valueText: const Value(null),
          valueNumber: const Value(null),
          valueDate: const Value(null),
          valueBoolean:
              Value(booleanValue == null ? null : (booleanValue ? 1 : 0)),
        ),
      _ => throw ArgumentError(
          'Unknown fieldType "$fieldType". '
          "Must be one of 'text', 'number', 'date', 'boolean'.",
        ),
    };
  }
}
