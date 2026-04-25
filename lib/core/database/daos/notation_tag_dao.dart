// NotationTagDao — Drift DAO for the notation_tags join table.
//
// Exposes assign/remove operations and cross-table lookups required by the
// TagRepository. All queries use Drift's type-safe query DSL; no raw SQL
// strings are used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `NotationTagDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'notation_tag_dao.g.dart';

/// Data-access object for the [NotationTagsTable] many-to-many join.
///
/// Provides tag assignment, removal, and cross-table queries that return
/// full [TagRow] or [NotationRow] lists. All queries are expressed via
/// Drift's type-safe DSL. Business logic and domain-model translation
/// belong in the repository layer, not here.
@DriftAccessor(tables: [NotationTagsTable, NotationsTable, TagsTable])
class NotationTagDao extends DatabaseAccessor<AppDatabase>
    with _$NotationTagDaoMixin {
  /// Creates a [NotationTagDao] attached to [db].
  NotationTagDao(super.db);

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Creates a join row linking [notationId] to [tagId].
  ///
  /// Throws if the pair already exists (composite primary-key violation),
  /// if [notationId] does not reference a valid notation row, or if [tagId]
  /// does not reference a valid tag row (FK constraint).
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 id of the notation.
  /// - [tagId]: The UUIDv4 id of the tag.
  Future<void> assignTag({
    required String notationId,
    required String tagId,
  }) async {
    await into(notationTagsTable).insert(
      NotationTagsTableCompanion.insert(
        notationId: notationId,
        tagId: tagId,
      ),
    );
    log(
      'NotationTagDao: assigned tag $tagId to notation $notationId',
      name: 'NotationTagDao',
    );
  }

  /// Removes the join row linking [notationId] to [tagId].
  ///
  /// If the pair does not exist, the call is silently ignored.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 id of the notation.
  /// - [tagId]: The UUIDv4 id of the tag.
  Future<void> removeTag({
    required String notationId,
    required String tagId,
  }) async {
    await (delete(notationTagsTable)
          ..where(
            (t) => t.notationId.equals(notationId) & t.tagId.equals(tagId),
          ))
        .go();
    log(
      'NotationTagDao: removed tag $tagId from notation $notationId',
      name: 'NotationTagDao',
    );
  }

  // -------------------------------------------------------------------------
  // Read operations
  // -------------------------------------------------------------------------

  /// Returns all [TagRow]s assigned to the notation identified by
  /// [notationId].
  ///
  /// Returns an empty list when no tags are assigned or the notation does
  /// not exist.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 id of the notation to query.
  Future<List<TagRow>> getTagsForNotation(String notationId) {
    final query = select(tagsTable).join([
      innerJoin(
        notationTagsTable,
        notationTagsTable.tagId.equalsExp(tagsTable.id),
      ),
    ])
      ..where(notationTagsTable.notationId.equals(notationId))
      ..orderBy([OrderingTerm.asc(tagsTable.name)]);

    return query.map((row) => row.readTable(tagsTable)).get();
  }

  /// Returns all [NotationRow]s that have been assigned the tag identified
  /// by [tagId].
  ///
  /// Returns an empty list when the tag has no assigned notations or the
  /// tag does not exist.
  ///
  /// Parameters:
  /// - [tagId]: The UUIDv4 id of the tag to query.
  Future<List<NotationRow>> getNotationsForTag(String tagId) {
    final query = select(notationsTable).join([
      innerJoin(
        notationTagsTable,
        notationTagsTable.notationId.equalsExp(notationsTable.id),
      ),
    ])
      ..where(notationTagsTable.tagId.equals(tagId))
      ..orderBy([OrderingTerm.desc(notationsTable.updatedAt)]);

    return query.map((row) => row.readTable(notationsTable)).get();
  }
}
