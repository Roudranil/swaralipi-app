// Abstract NotationRepository interface.
//
// Defines the contract for all notation CRUD, soft-delete, play-count, and
// reactive-list operations. The concrete implementation lives in
// lib/features/capture/data/notation_repository_impl.dart.
//
// All write operations run inside a Drift transaction to ensure atomicity.
// All list reads return Stream<List<T>> so the UI layer can react to changes
// without polling.

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';

// ---------------------------------------------------------------------------
// Repository interface
// ---------------------------------------------------------------------------

/// Contract for all notation data operations.
///
/// Implementations translate between Drift row types and domain models at the
/// repository boundary. All write methods that create or modify a notation
/// return the persisted [Notation] so callers never need a follow-up read.
///
/// Every multi-table write ([saveNotation], [updateNotation]) runs inside a
/// single Drift transaction, guaranteeing atomicity across the notations,
/// notation_pages, notation_tags, and notation_custom_fields tables.
abstract interface class NotationRepository {
  /// Persists a new notation with its pages, tags, and custom field values in
  /// a single transaction and returns the newly created [Notation].
  ///
  /// When [notationId] is provided the repository uses it as the primary key;
  /// otherwise a new UUIDv4 is generated internally. Callers that write page
  /// files to disk before calling this method must supply the same UUID that
  /// was used to construct the file paths so that stored paths remain
  /// consistent.
  ///
  /// The [pages] list is written as `notation_pages` rows in the same
  /// transaction. Tag and custom field associations are also created
  /// atomically.
  ///
  /// Parameters:
  /// - [draft]: All user-supplied metadata, tag ids, and custom field values.
  /// - [pages]: Ordered list of page DTOs with caller-generated UUIDs and
  ///   resolved image paths.
  /// - [notationId]: Optional UUIDv4 to use as the notation primary key.
  ///   Defaults to a freshly generated UUID when omitted.
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  });

  /// Updates an existing notation's metadata, tags, and custom field values
  /// atomically and returns the updated [Notation].
  ///
  /// All existing tag associations for the notation are removed and replaced
  /// by the ids in [draft.tagIds]. All existing custom field values are
  /// upserted (insert-or-replace) from [draft.customFields].
  ///
  /// Throws [NotationNotFoundException] if no notation with [id] exists.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to update.
  /// - [draft]: Updated metadata, tag ids, and custom field values.
  Future<Notation> updateNotation(String id, NotationDraft draft);

  /// Loads a fully-hydrated [NotationDetail] for the notation with [id].
  ///
  /// Hydrates all relations: pages (ordered by page_order), tags (ordered by
  /// name), and custom field values. Returns `null` when no notation with [id]
  /// exists (or the notation is soft-deleted).
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to load.
  Future<NotationDetail?> loadNotation(String id);

  /// Returns a live stream of all active (non-deleted) notations.
  ///
  /// The stream re-emits whenever any notation row changes. The ordering is
  /// controlled by [sortBy]; defaults to [NotationSortBy.dateDesc]
  /// (most-recently created first).
  ///
  /// Parameters:
  /// - [sortBy]: Column and direction to order results by.
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  });

  /// Returns a live stream of the most-recently-played active notations,
  /// ordered by [Notation.lastPlayedAt] descending.
  ///
  /// Only notations that have been played at least once (non-null
  /// [Notation.lastPlayedAt]) are included. The stream re-emits whenever the
  /// underlying table changes.
  ///
  /// Parameters:
  /// - [limit]: Maximum number of notations to return. Defaults to 5.
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5});

  /// Soft-deletes the notation with [id] by setting `deleted_at` to the
  /// current UTC timestamp.
  ///
  /// Soft-deleted notations are excluded from [watchAllActive] but remain in
  /// the database so the Trash screen can list and restore them. If no
  /// notation with [id] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to soft-delete.
  Future<void> softDelete(String id);

  /// Increments [Notation.playCount] by one and sets
  /// [Notation.lastPlayedAt] to the current UTC timestamp.
  ///
  /// If no notation with [id] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation that was played.
  Future<void> updatePlayCount(String id);

  /// Updates the [renderParams] JSON string for a single notation page.
  ///
  /// Used by the edit flow to persist non-destructive render-parameter changes
  /// (filter, crop, rotation) without touching the original image file.
  ///
  /// If no page with [pageId] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [pageId]: The UUIDv4 primary key of the page to update.
  /// - [renderParamsJson]: Serialised [RenderParams] JSON string.
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  );
}

// ---------------------------------------------------------------------------
// Domain exceptions
// ---------------------------------------------------------------------------

/// Thrown by [NotationRepository.updateNotation] when no notation with the
/// given id exists.
final class NotationNotFoundException implements Exception {
  /// Creates a [NotationNotFoundException] for [id].
  ///
  /// Parameters:
  /// - [id]: The notation id that was not found.
  const NotationNotFoundException(this.id);

  /// The notation id that was not found.
  final String id;

  @override
  String toString() => 'NotationNotFoundException: no notation with id "$id"';
}
