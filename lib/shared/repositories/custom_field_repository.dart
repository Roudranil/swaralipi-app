// Abstract CustomFieldRepository interface.
//
// Defines the contract for all custom field definition CRUD operations.
// The concrete implementation lives in
// lib/features/custom_fields/data/custom_field_repository_impl.dart.

import 'package:swaralipi/shared/models/custom_field_definition.dart';

// ---------------------------------------------------------------------------
// Repository interface
// ---------------------------------------------------------------------------

/// Contract for all custom field definition data operations.
///
/// Implementations translate between [CustomFieldDefinitionRow] (Drift) and
/// [CustomFieldDefinition] (domain) at the repository boundary.
///
/// All write methods return the persisted domain model so callers never need
/// to issue a follow-up read.
abstract interface class CustomFieldRepository {
  /// Returns a live stream of all custom field definitions ordered
  /// alphabetically by [CustomFieldDefinition.keyName].
  ///
  /// The stream re-emits whenever the underlying table changes.
  Stream<List<CustomFieldDefinition>> watchAllDefinitions();

  /// Creates a new custom field definition with [keyName] and [fieldType] and
  /// returns the persisted [CustomFieldDefinition].
  ///
  /// Throws if [keyName] already exists (UNIQUE constraint violation).
  ///
  /// Parameters:
  /// - [keyName]: Unique machine-readable key, e.g. `'raga_name'`.
  /// - [fieldType]: One of `'text'`, `'number'`, `'date'`, `'boolean'`.
  Future<CustomFieldDefinition> createDefinition(
    String keyName,
    String fieldType,
  );

  /// Updates the [keyName] and/or [fieldType] of the definition identified by
  /// [id] and returns the updated [CustomFieldDefinition].
  ///
  /// Throws [CustomFieldNotFoundException] if no definition with [id] exists.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the definition to update.
  /// - [keyName]: New machine-readable key; omit to leave unchanged.
  /// - [fieldType]: New field type string; omit to leave unchanged.
  Future<CustomFieldDefinition> updateDefinition(
    String id, {
    String? keyName,
    String? fieldType,
  });

  /// Permanently deletes the definition with [id].
  ///
  /// All associated `notation_custom_fields` rows cascade-delete automatically
  /// via the FK `ON DELETE CASCADE` constraint. If no definition with [id]
  /// exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the definition to delete.
  Future<void> deleteDefinition(String id);
}

// ---------------------------------------------------------------------------
// Domain exceptions
// ---------------------------------------------------------------------------

/// Thrown by [CustomFieldRepository.updateDefinition] when no definition with
/// the given id exists.
final class CustomFieldNotFoundException implements Exception {
  /// Creates a [CustomFieldNotFoundException] for [id].
  ///
  /// Parameters:
  /// - [id]: The id that was not found.
  const CustomFieldNotFoundException(this.id);

  /// The definition id that was not found.
  final String id;

  @override
  String toString() =>
      'CustomFieldNotFoundException: no definition with id "$id"';
}
