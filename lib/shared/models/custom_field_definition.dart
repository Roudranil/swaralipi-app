// CustomFieldDefinition domain model.
//
// Immutable representation of a user-defined custom metadata field schema
// as returned by [CustomFieldRepository]. JSON serialization is generated
// by json_serializable.
//
// Run `dart run build_runner build --delete-conflicting-outputs` to regenerate
// custom_field_definition.g.dart.

import 'package:json_annotation/json_annotation.dart';

part 'custom_field_definition.g.dart';

/// The allowed data types for a custom field.
///
/// Mirrors the `CHECK` constraint on the `custom_field_definitions.field_type`
/// column in the database schema.
enum CustomFieldType {
  /// A free-form text value.
  text,

  /// A numeric value (stored as a double).
  number,

  /// An ISO 8601 date string.
  date,

  /// A true/false boolean value.
  boolean,
}

/// Immutable domain model for a custom metadata field definition.
///
/// Defines the schema for a user-created metadata field. Actual per-notation
/// values are stored in [CustomFieldValue]. The [fieldType] constrains which
/// value column is used when persisting a value.
@JsonSerializable(fieldRename: FieldRename.snake)
class CustomFieldDefinition {
  /// Creates an immutable [CustomFieldDefinition].
  ///
  /// Parameters:
  /// - [id]: UUIDv4 generated at the app layer.
  /// - [keyName]: Unique machine-readable key for this field.
  /// - [fieldType]: Data type of the field.
  /// - [createdAt]: ISO 8601 datetime of creation.
  /// - [updatedAt]: ISO 8601 datetime of last update.
  const CustomFieldDefinition({
    required this.id,
    required this.keyName,
    required this.fieldType,
    required this.createdAt,
    required this.updatedAt,
  });

  /// UUIDv4 generated at the app layer.
  final String id;

  /// Unique machine-readable key, e.g. `'raga_name'`.
  final String keyName;

  /// Data type of this custom field.
  final CustomFieldType fieldType;

  /// ISO 8601 datetime when this definition was created.
  final String createdAt;

  /// ISO 8601 datetime of the last update.
  final String updatedAt;

  /// Returns a copy of this [CustomFieldDefinition] with the specified
  /// fields replaced.
  ///
  /// Fields not provided retain their current values.
  CustomFieldDefinition copyWith({
    String? id,
    String? keyName,
    CustomFieldType? fieldType,
    String? createdAt,
    String? updatedAt,
  }) =>
      CustomFieldDefinition(
        id: id ?? this.id,
        keyName: keyName ?? this.keyName,
        fieldType: fieldType ?? this.fieldType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Deserializes a [CustomFieldDefinition] from a JSON map.
  factory CustomFieldDefinition.fromJson(Map<String, dynamic> json) =>
      _$CustomFieldDefinitionFromJson(json);

  /// Serializes this [CustomFieldDefinition] to a JSON map.
  Map<String, dynamic> toJson() => _$CustomFieldDefinitionToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomFieldDefinition &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          keyName == other.keyName &&
          fieldType == other.fieldType &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(id, keyName, fieldType, createdAt, updatedAt);

  @override
  String toString() => 'CustomFieldDefinition(id: $id, keyName: $keyName, '
      'fieldType: $fieldType)';
}
