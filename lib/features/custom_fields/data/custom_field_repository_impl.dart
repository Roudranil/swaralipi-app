// CustomFieldRepositoryImpl — concrete implementation of CustomFieldRepository.
//
// Translates between [CustomFieldDefinitionRow] (Drift) and
// [CustomFieldDefinition] (domain model). All write operations return the
// persisted domain model. Type coercion between string and [CustomFieldType]
// enum is enforced here.
//
// Construct by injecting a [CustomFieldDao]:
//   CustomFieldRepositoryImpl(db.customFieldDao)

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/custom_field_dao.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Shared [Uuid] generator instance used by [CustomFieldRepositoryImpl].
const _kUuid = Uuid();

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [CustomFieldRepository] backed by a Drift
/// [CustomFieldDao].
///
/// Translates [CustomFieldDefinitionRow] database rows to
/// [CustomFieldDefinition] domain models at the repository boundary. All
/// business logic (UUID generation, timestamp stamping, type mapping) lives
/// here; the [CustomFieldDao] is responsible only for typed SQL.
final class CustomFieldRepositoryImpl implements CustomFieldRepository {
  /// Creates a [CustomFieldRepositoryImpl] with the given [_dao].
  ///
  /// Parameters:
  /// - [_dao]: The Drift DAO for the `custom_field_definitions_table`.
  const CustomFieldRepositoryImpl(this._dao);

  final CustomFieldDao _dao;

  // -------------------------------------------------------------------------
  // CustomFieldRepository interface
  // -------------------------------------------------------------------------

  @override
  Stream<List<CustomFieldDefinition>> watchAllDefinitions() {
    return _dao.watchAllDefinitions().map(
          (rows) => rows.map(_rowToDomain).toList(),
        );
  }

  @override
  Future<CustomFieldDefinition> createDefinition(
    String keyName,
    String fieldType,
  ) async {
    final id = _kUuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _dao.insertDefinition(
      CustomFieldDefinitionsTableCompanion.insert(
        id: id,
        keyName: keyName,
        fieldType: fieldType,
        createdAt: now,
        updatedAt: now,
      ),
    );

    log(
      'CustomFieldRepositoryImpl: created definition '
      '"$keyName" ($id) type=$fieldType',
      name: 'CustomFieldRepository',
    );

    return CustomFieldDefinition(
      id: id,
      keyName: keyName,
      fieldType: _typeFromString(fieldType),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<CustomFieldDefinition> updateDefinition(
    String id, {
    String? keyName,
    String? fieldType,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final companion = CustomFieldDefinitionsTableCompanion(
      id: Value(id),
      keyName: keyName != null ? Value(keyName) : const Value.absent(),
      fieldType: fieldType != null ? Value(fieldType) : const Value.absent(),
      updatedAt: Value(now),
    );

    final updated = await _dao.updateDefinition(companion);
    if (!updated) {
      throw CustomFieldNotFoundException(id);
    }

    final rows = await _dao.getAllDefinitions();
    final row = rows.where((r) => r.id == id).firstOrNull;
    // row cannot be null here: updateDefinition returned true → row exists.
    return _rowToDomain(row!);
  }

  @override
  Future<void> deleteDefinition(String id) async {
    await _dao.deleteDefinition(id);
    log(
      'CustomFieldRepositoryImpl: deleted definition $id',
      name: 'CustomFieldRepository',
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Converts a [CustomFieldDefinitionRow] to a [CustomFieldDefinition].
  CustomFieldDefinition _rowToDomain(CustomFieldDefinitionRow row) =>
      CustomFieldDefinition(
        id: row.id,
        keyName: row.keyName,
        fieldType: _typeFromString(row.fieldType),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Maps a DB string to the corresponding [CustomFieldType] enum variant.
  CustomFieldType _typeFromString(String raw) => switch (raw) {
        'text' => CustomFieldType.text,
        'number' => CustomFieldType.number,
        'date' => CustomFieldType.date,
        'boolean' => CustomFieldType.boolean,
        _ => throw ArgumentError(
            'Unknown fieldType "$raw". '
            "Must be one of 'text', 'number', 'date', 'boolean'.",
          ),
      };
}
