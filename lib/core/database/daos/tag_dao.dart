// TagDao — Drift DAO for the tags table.
//
// Exposes all CRUD and query operations required by the TagRepository.
// All queries use Drift's type-safe query DSL; no raw SQL strings are
// used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `TagDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'tag_dao.g.dart';

/// Data-access object for the [TagsTable].
///
/// Provides insert, update, hard-delete, single-row query, and streaming
/// list operations. All queries are expressed via Drift's type-safe DSL.
/// Business logic and domain-model translation belong in the repository
/// layer, not here.
@DriftAccessor(tables: [TagsTable])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  /// Creates a [TagDao] attached to [db].
  TagDao(super.db);

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Inserts a new tag row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation) or if
  /// [companion.name] already exists (UNIQUE constraint on name).
  ///
  /// Parameters:
  /// - [companion]: A fully populated [TagsTableCompanion].
  Future<void> insertTag(TagsTableCompanion companion) async {
    await into(tagsTable).insert(companion);
    log(
      'TagDao: inserted tag ${companion.id.value}',
      name: 'TagDao',
    );
  }

  /// Updates an existing tag row using the fields provided in [companion].
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [TagsTableCompanion] with [companion.id] set
  ///   to identify the target row.
  Future<bool> updateTag(TagsTableCompanion companion) async {
    final rowsAffected = await (update(tagsTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Permanently deletes the tag row with [id].
  ///
  /// This is a hard delete. Associated [NotationTagsTable] join rows
  /// cascade automatically via the FK constraint. If no row matches [id],
  /// the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the tag to delete.
  Future<void> deleteTag(String id) async {
    await (delete(tagsTable)..where((t) => t.id.equals(id))).go();
    log('TagDao: deleted tag $id', name: 'TagDao');
  }

  // -------------------------------------------------------------------------
  // Read operations
  // -------------------------------------------------------------------------

  /// Returns all tag rows, ordered alphabetically by [TagsTable.name].
  Future<List<TagRow>> getAllTags() {
    return (select(tagsTable)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Emits a live list of all tag rows, ordered alphabetically by
  /// [TagsTable.name].
  ///
  /// The stream re-emits whenever the underlying table changes.
  Stream<List<TagRow>> watchAllTags() {
    return (select(tagsTable)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Returns the tag row for [id], or `null` if it does not exist.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key to look up.
  Future<TagRow?> getTagById(String id) {
    return (select(tagsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  }
}
