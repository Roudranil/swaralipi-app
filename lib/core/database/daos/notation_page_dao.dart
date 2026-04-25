// NotationPageDao — Drift DAO for the notation_pages table.
//
// Exposes CRUD and bulk-delete operations required by the
// NotationPageRepository. All queries use Drift's type-safe query DSL;
// no raw SQL strings are used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `NotationPageDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'notation_page_dao.g.dart';

/// Data-access object for the [NotationPagesTable].
///
/// Provides insert, update, delete, and query operations for notation pages.
/// All queries are expressed via Drift's type-safe DSL. Business logic and
/// domain-model translation belong in the repository layer, not here.
@DriftAccessor(tables: [NotationPagesTable])
class NotationPageDao extends DatabaseAccessor<AppDatabase>
    with _$NotationPageDaoMixin {
  /// Creates a [NotationPageDao] attached to [db].
  NotationPageDao(super.db);

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Inserts a new notation page row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation) or if the
  /// `(notation_id, page_order)` combination is not unique.
  ///
  /// Parameters:
  /// - [companion]: A fully populated [NotationPagesTableCompanion].
  Future<void> insertPage(NotationPagesTableCompanion companion) async {
    await into(notationPagesTable).insert(companion);
    log(
      'NotationPageDao: inserted page ${companion.id.value}',
      name: 'NotationPageDao',
    );
  }

  /// Updates an existing notation page row using the fields in [companion].
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [NotationPagesTableCompanion] with [companion.id]
  ///   set to identify the target row.
  Future<bool> updatePage(NotationPagesTableCompanion companion) async {
    final rowsAffected = await (update(notationPagesTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Permanently deletes the page row with [id].
  ///
  /// If no row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the page to delete.
  Future<void> deletePage(String id) async {
    await (delete(notationPagesTable)..where((t) => t.id.equals(id))).go();
    log('NotationPageDao: deleted page $id', name: 'NotationPageDao');
  }

  /// Deletes all page rows whose [NotationPagesTable.notationId] equals
  /// [notationId].
  ///
  /// Used before a notation hard-delete to clean up associated image files
  /// before the cascade removes the rows. If the notation has no pages, the
  /// call is silently ignored.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 of the parent notation.
  Future<void> deleteAllPagesForNotation(String notationId) async {
    await (delete(notationPagesTable)
          ..where((t) => t.notationId.equals(notationId)))
        .go();
    log(
      'NotationPageDao: deleted all pages for notation $notationId',
      name: 'NotationPageDao',
    );
  }

  // -------------------------------------------------------------------------
  // Read operations
  // -------------------------------------------------------------------------

  /// Returns all pages for [notationId] ordered by [NotationPagesTable.pageOrder]
  /// ascending (page 0 first).
  ///
  /// Returns an empty list if the notation has no pages or does not exist.
  /// Matches the player query in data-model.md §8.6.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 of the parent notation.
  Future<List<NotationPageRow>> getPagesByNotationId(String notationId) {
    return (select(notationPagesTable)
          ..where((t) => t.notationId.equals(notationId))
          ..orderBy([(t) => OrderingTerm.asc(t.pageOrder)]))
        .get();
  }
}
