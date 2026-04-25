// NotationDao — Drift DAO for the notations table.
//
// Exposes all CRUD, soft-delete, restore, and play-count operations required
// by the NotationRepository. All queries use Drift's type-safe query DSL;
// no raw SQL strings are used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `NotationDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'notation_dao.g.dart';

/// Data-access object for the [NotationsTable].
///
/// Provides insert, update, hard-delete, soft-delete, restore, query, and
/// play-count operations. All queries are expressed via Drift's type-safe DSL.
/// Business logic and domain-model translation belong in the repository layer,
/// not here.
@DriftAccessor(tables: [NotationsTable])
class NotationDao extends DatabaseAccessor<AppDatabase>
    with _$NotationDaoMixin {
  /// Creates a [NotationDao] attached to [db].
  NotationDao(super.db);

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Inserts a new notation row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation).
  ///
  /// Parameters:
  /// - [companion]: A fully populated [NotationsTableCompanion].
  Future<void> insertNotation(NotationsTableCompanion companion) async {
    await into(notationsTable).insert(companion);
    log(
      'NotationDao: inserted notation ${companion.id.value}',
      name: 'NotationDao',
    );
  }

  /// Updates an existing notation row using the fields provided in [companion].
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [NotationsTableCompanion] with [companion.id]
  ///   set to identify the target row.
  Future<bool> updateNotation(NotationsTableCompanion companion) async {
    final rowsAffected = await (update(notationsTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Permanently deletes the notation row with [id].
  ///
  /// This is a hard delete. Pages cascade automatically via the FK constraint.
  /// If no row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to delete.
  Future<void> deleteNotation(String id) async {
    await (delete(notationsTable)..where((t) => t.id.equals(id))).go();
    log('NotationDao: hard-deleted notation $id', name: 'NotationDao');
  }

  /// Sets [NotationsTable.deletedAt] to the current UTC timestamp.
  ///
  /// The row remains in the database but is excluded from [watchAllActive].
  /// If no row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to soft-delete.
  Future<void> softDelete(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (update(notationsTable)..where((t) => t.id.equals(id))).write(
      NotationsTableCompanion(deletedAt: Value(now)),
    );
    log('NotationDao: soft-deleted notation $id', name: 'NotationDao');
  }

  /// Clears [NotationsTable.deletedAt], making the notation active again.
  ///
  /// If no row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to restore.
  Future<void> restore(String id) async {
    await (update(notationsTable)..where((t) => t.id.equals(id))).write(
      const NotationsTableCompanion(deletedAt: Value(null)),
    );
    log('NotationDao: restored notation $id', name: 'NotationDao');
  }

  /// Increments [NotationsTable.playCount] by one and updates
  /// [NotationsTable.lastPlayedAt] to the current UTC timestamp.
  ///
  /// If no row matches [id], the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation that was played.
  Future<void> updatePlayCount(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    // Use RawValuesInsertable to pass column expressions directly — this is the
    // type-safe Drift API for atomic arithmetic updates without raw SQL strings.
    await (update(notationsTable)..where((t) => t.id.equals(id))).write(
      RawValuesInsertable({
        'play_count': notationsTable.playCount + const Constant(1),
        'last_played_at': Variable.withString(now),
      }),
    );
    log('NotationDao: incremented play count for $id', name: 'NotationDao');
  }

  // -------------------------------------------------------------------------
  // Read operations
  // -------------------------------------------------------------------------

  /// Returns the notation row for [id], or `null` if it does not exist.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key to look up.
  Future<NotationRow?> getNotationById(String id) {
    return (select(notationsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Emits a live list of active notation rows (where [deletedAt] IS NULL).
  ///
  /// The stream re-emits whenever the underlying table changes. Results are
  /// ordered by [NotationsTable.updatedAt] descending (most-recently changed
  /// first), matching the default library sort in data-model.md §8.1.
  Stream<List<NotationRow>> watchAllActive() {
    return (select(notationsTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  /// Emits a live list of soft-deleted notation rows (where [deletedAt]
  /// IS NOT NULL).
  ///
  /// The stream re-emits whenever the underlying table changes. Results are
  /// ordered by [NotationsTable.deletedAt] descending (most-recently deleted
  /// first), matching the Trash screen query in data-model.md §8.4.
  Stream<List<NotationRow>> watchDeleted() {
    return (select(notationsTable)
          ..where((t) => t.deletedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.deletedAt)]))
        .watch();
  }
}
