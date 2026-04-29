// NotationDetail — fully-hydrated domain model returned by
// NotationRepository.loadNotation.
//
// Aggregates the core [Notation] with its related pages, tags, and custom
// field values so the presentation layer never needs to issue multiple
// repository calls to display a single notation.

import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/tag.dart';

// ---------------------------------------------------------------------------
// NotationDetail
// ---------------------------------------------------------------------------

/// Immutable aggregate returned by [NotationRepository.loadNotation].
///
/// Contains the core [Notation] plus all related entities hydrated in a single
/// repository call: [pages] in display order, [tags] sorted alphabetically,
/// and [customFieldValues] for every custom field assigned to this notation.
///
/// The UI layer uses this type to render the notation detail screen without
/// issuing additional repository calls.
final class NotationDetail {
  /// Creates an immutable [NotationDetail].
  ///
  /// Parameters:
  /// - [notation]: The core notation domain model.
  /// - [pages]: Pages ordered by [NotationPage.pageOrder] ascending.
  /// - [tags]: Tags assigned to this notation, ordered by name.
  /// - [customFieldValues]: Custom field values for this notation.
  const NotationDetail({
    required this.notation,
    required this.pages,
    required this.tags,
    required this.customFieldValues,
  });

  /// The core notation domain model.
  final Notation notation;

  /// Pages belonging to this notation, ordered by
  /// [NotationPage.pageOrder] ascending (page 0 first).
  final List<NotationPage> pages;

  /// Tags assigned to this notation, ordered alphabetically by name.
  final List<Tag> tags;

  /// Custom field values set for this notation.
  ///
  /// Each entry corresponds to one [CustomFieldDefinition]. The list may be
  /// empty when no custom fields have been assigned.
  final List<CustomFieldValue> customFieldValues;

  /// Returns a copy of this [NotationDetail] with the specified fields
  /// replaced.
  ///
  /// Fields not provided retain their current values.
  NotationDetail copyWith({
    Notation? notation,
    List<NotationPage>? pages,
    List<Tag>? tags,
    List<CustomFieldValue>? customFieldValues,
  }) =>
      NotationDetail(
        notation: notation ?? this.notation,
        pages: pages ?? this.pages,
        tags: tags ?? this.tags,
        customFieldValues: customFieldValues ?? this.customFieldValues,
      );

  @override
  String toString() => 'NotationDetail(notationId: ${notation.id}, '
      'pages: ${pages.length}, tags: ${tags.length})';
}
