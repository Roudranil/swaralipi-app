// NotationDraft — input DTO for creating or updating a notation.
//
// Carries the mutable metadata fields plus tag IDs and custom field values
// that the repository writes in a single transaction. It is intentionally
// separate from the persisted [Notation] domain model so the caller never
// needs to construct a full Notation before a save.

// ---------------------------------------------------------------------------
// Imports
// ---------------------------------------------------------------------------

import 'package:swaralipi/shared/models/custom_field_value.dart';

// ---------------------------------------------------------------------------
// NotationDraft
// ---------------------------------------------------------------------------

/// Immutable input DTO passed to [NotationRepository.saveNotation] and
/// [NotationRepository.updateNotation].
///
/// Contains all user-supplied fields for a notation entry together with the
/// IDs of tags to assign and the custom field values to write. The repository
/// is responsible for generating the ID, timestamps, and persisting everything
/// in a single transaction.
final class NotationDraft {
  /// Creates an immutable [NotationDraft].
  ///
  /// Parameters:
  /// - [title]: Human-readable title; must not be empty.
  /// - [artists]: Ordered list of artist names; defaults to empty.
  /// - [dateWritten]: ISO 8601 date (YYYY-MM-DD); nullable.
  /// - [timeSig]: Time signature string, e.g. `'4/4'`; nullable.
  /// - [keySig]: Key signature string, e.g. `'C'`; nullable.
  /// - [languages]: Ordered list of language names; defaults to empty.
  /// - [notes]: Free-form personal notes.
  /// - [tagIds]: UUIDv4 ids of tags to assign to this notation.
  /// - [customFields]: Custom field values to write for this notation.
  const NotationDraft({
    required this.title,
    this.artists = const [],
    this.dateWritten,
    this.timeSig,
    this.keySig,
    this.languages = const [],
    this.notes = '',
    this.tagIds = const [],
    this.customFields = const [],
  });

  /// Human-readable title of the piece.
  final String title;

  /// Ordered list of artist names.
  final List<String> artists;

  /// ISO 8601 date (YYYY-MM-DD) when the notation was written; nullable.
  final String? dateWritten;

  /// Time signature string, e.g. `'4/4'` or `'6/8'`; nullable.
  final String? timeSig;

  /// Key signature string, e.g. `'C'` or `'Bb minor'`; nullable.
  final String? keySig;

  /// Ordered list of language names.
  final List<String> languages;

  /// Free-form personal notes about this notation.
  final String notes;

  /// UUIDv4 ids of tags to assign to this notation.
  final List<String> tagIds;

  /// Custom field values to write for this notation.
  final List<CustomFieldValueInput> customFields;

  /// Returns a copy of this [NotationDraft] with the specified fields replaced.
  ///
  /// Fields not provided retain their current values.
  NotationDraft copyWith({
    String? title,
    List<String>? artists,
    String? dateWritten,
    String? timeSig,
    String? keySig,
    List<String>? languages,
    String? notes,
    List<String>? tagIds,
    List<CustomFieldValueInput>? customFields,
  }) =>
      NotationDraft(
        title: title ?? this.title,
        artists: artists ?? this.artists,
        dateWritten: dateWritten ?? this.dateWritten,
        timeSig: timeSig ?? this.timeSig,
        keySig: keySig ?? this.keySig,
        languages: languages ?? this.languages,
        notes: notes ?? this.notes,
        tagIds: tagIds ?? this.tagIds,
        customFields: customFields ?? this.customFields,
      );

  @override
  String toString() => 'NotationDraft(title: $title)';
}

// ---------------------------------------------------------------------------
// CustomFieldValueInput
// ---------------------------------------------------------------------------

/// Immutable input DTO for a single custom field value within a
/// [NotationDraft].
///
/// Uses the same sparse-column design as [CustomFieldValue]: only the field
/// matching [fieldType] should be populated.
final class CustomFieldValueInput {
  /// Creates an immutable [CustomFieldValueInput].
  ///
  /// Parameters:
  /// - [definitionId]: FK to the [CustomFieldDefinition] row.
  /// - [fieldType]: One of `'text'`, `'number'`, `'date'`, `'boolean'`.
  /// - [textValue]: Value when [fieldType] is `'text'`; nullable.
  /// - [numberValue]: Value when [fieldType] is `'number'`; nullable.
  /// - [dateValue]: ISO 8601 date when [fieldType] is `'date'`; nullable.
  /// - [booleanValue]: Boolean when [fieldType] is `'boolean'`; nullable.
  const CustomFieldValueInput({
    required this.definitionId,
    required this.fieldType,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
  });

  /// FK to the [CustomFieldDefinition] row.
  final String definitionId;

  /// Field type: one of `'text'`, `'number'`, `'date'`, `'boolean'`.
  final String fieldType;

  /// Text value; populated when [fieldType] is `'text'`.
  final String? textValue;

  /// Numeric value; populated when [fieldType] is `'number'`.
  final double? numberValue;

  /// ISO 8601 date; populated when [fieldType] is `'date'`.
  final String? dateValue;

  /// Boolean value; populated when [fieldType] is `'boolean'`.
  final bool? booleanValue;

  @override
  String toString() => 'CustomFieldValueInput(definitionId: $definitionId, '
      'fieldType: $fieldType)';
}
