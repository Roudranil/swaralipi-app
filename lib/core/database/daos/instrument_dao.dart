// InstrumentDao — Drift DAO for the instrument_classes and
// instrument_instances tables.
//
// Exposes all CRUD, archive, and query operations required by the
// InstrumentRepository. All queries use Drift's type-safe query DSL;
// no raw SQL strings are used anywhere in this file.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `InstrumentDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'instrument_dao.g.dart';

/// Data-access object for [InstrumentClassesTable] and
/// [InstrumentInstancesTable].
///
/// Provides insert, update, query, and soft-delete (archive) operations for
/// both instrument classes and instances. All queries are expressed via
/// Drift's type-safe DSL. Business logic and domain-model translation belong
/// in the repository layer, not here.
@DriftAccessor(tables: [InstrumentClassesTable, InstrumentInstancesTable])
class InstrumentDao extends DatabaseAccessor<AppDatabase>
    with _$InstrumentDaoMixin {
  /// Creates an [InstrumentDao] attached to [db].
  InstrumentDao(super.db);

  // -------------------------------------------------------------------------
  // Instrument class write operations
  // -------------------------------------------------------------------------

  /// Inserts a new instrument class row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation) or if
  /// [companion.name] already exists (UNIQUE constraint on name).
  ///
  /// Parameters:
  /// - [companion]: A fully populated [InstrumentClassesTableCompanion].
  Future<void> insertClass(InstrumentClassesTableCompanion companion) async {
    await into(instrumentClassesTable).insert(companion);
    log(
      'InstrumentDao: inserted class ${companion.id.value}',
      name: 'InstrumentDao',
    );
  }

  /// Updates an existing instrument class row using the fields provided in
  /// [companion].
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [InstrumentClassesTableCompanion] with
  ///   [companion.id] set to identify the target row.
  Future<bool> updateClass(
    InstrumentClassesTableCompanion companion,
  ) async {
    final rowsAffected = await (update(instrumentClassesTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  // -------------------------------------------------------------------------
  // Instrument class read operations
  // -------------------------------------------------------------------------

  /// Returns all active (non-archived) instrument class rows, ordered
  /// alphabetically by [InstrumentClassesTable.name].
  ///
  /// Active means [InstrumentClassesTable.deletedAt] IS NULL.
  Future<List<InstrumentClassRow>> getActiveClasses() {
    return (select(instrumentClassesTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Returns a live stream of all active instrument class rows, ordered
  /// alphabetically by [InstrumentClassesTable.name].
  ///
  /// Active means [InstrumentClassesTable.deletedAt] IS NULL. The stream
  /// re-emits whenever the underlying table changes.
  Stream<List<InstrumentClassRow>> watchActiveClasses() {
    return (select(instrumentClassesTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Sets [InstrumentClassesTable.deletedAt] to the current UTC timestamp,
  /// effectively archiving the class.
  ///
  /// Archived classes are hidden from the active instrument class list but
  /// remain in the database. The [InstrumentInstancesTable] rows that
  /// reference this class are NOT touched — ON DELETE RESTRICT prevents
  /// hard deletion while instances exist. If no row matches [id], the call
  /// is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the class to archive.
  Future<void> archiveClass(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (update(instrumentClassesTable)..where((t) => t.id.equals(id))).write(
      InstrumentClassesTableCompanion(deletedAt: Value(now)),
    );
    log('InstrumentDao: archived class $id', name: 'InstrumentDao');
  }

  // -------------------------------------------------------------------------
  // Instrument instance write operations
  // -------------------------------------------------------------------------

  /// Inserts a new instrument instance row.
  ///
  /// Throws if [companion.id] already exists (primary-key violation) or if
  /// [companion.classId] does not reference an existing class row (FK
  /// RESTRICT constraint).
  ///
  /// Parameters:
  /// - [companion]: A fully populated [InstrumentInstancesTableCompanion].
  Future<void> insertInstance(
    InstrumentInstancesTableCompanion companion,
  ) async {
    await into(instrumentInstancesTable).insert(companion);
    log(
      'InstrumentDao: inserted instance ${companion.id.value}',
      name: 'InstrumentDao',
    );
  }

  /// Updates an existing instrument instance row using the fields provided
  /// in [companion].
  ///
  /// Only columns present as [Value] (not [Value.absent()]) are written.
  /// Returns `true` if the row was found and updated, `false` otherwise.
  ///
  /// Parameters:
  /// - [companion]: A partial [InstrumentInstancesTableCompanion] with
  ///   [companion.id] set to identify the target row.
  Future<bool> updateInstance(
    InstrumentInstancesTableCompanion companion,
  ) async {
    final rowsAffected = await (update(instrumentInstancesTable)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion);
    return rowsAffected > 0;
  }

  /// Sets [InstrumentInstancesTable.deletedAt] to the current UTC timestamp,
  /// effectively archiving the instance.
  ///
  /// Archived instances remain in the database and continue to appear on
  /// existing notation associations, but are excluded from
  /// [getActiveInstancesForClass]. If no row matches [id], the call is
  /// silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the instance to archive.
  Future<void> archiveInstance(String id) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await (update(instrumentInstancesTable)..where((t) => t.id.equals(id)))
        .write(
      InstrumentInstancesTableCompanion(deletedAt: Value(now)),
    );
    log('InstrumentDao: archived instance $id', name: 'InstrumentDao');
  }

  // -------------------------------------------------------------------------
  // Instrument instance read operations
  // -------------------------------------------------------------------------

  /// Returns all active (non-archived) instance rows for the class
  /// identified by [classId].
  ///
  /// Active means [InstrumentInstancesTable.deletedAt] IS NULL. Returns an
  /// empty list when the class has no active instances or the class does not
  /// exist.
  ///
  /// Parameters:
  /// - [classId]: The UUIDv4 primary key of the instrument class.
  Future<List<InstrumentInstanceRow>> getActiveInstancesForClass(
    String classId,
  ) {
    return (select(instrumentInstancesTable)
          ..where(
            (t) => t.classId.equals(classId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Returns a live stream of all active (non-archived) instance rows for
  /// the class identified by [classId], ordered by creation time.
  ///
  /// Active means [InstrumentInstancesTable.deletedAt] IS NULL. The stream
  /// re-emits whenever the underlying table changes. Returns an empty list
  /// when the class has no active instances or the class does not exist.
  ///
  /// Parameters:
  /// - [classId]: The UUIDv4 primary key of the instrument class.
  Stream<List<InstrumentInstanceRow>> watchActiveInstancesForClass(
    String classId,
  ) {
    return (select(instrumentInstancesTable)
          ..where(
            (t) => t.classId.equals(classId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  /// Returns the instance row for [id], or `null` if it does not exist.
  ///
  /// This query does not filter by [InstrumentInstancesTable.deletedAt] —
  /// archived instances are also returned. Use [getActiveInstancesForClass]
  /// to list only active instances.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the instance to look up.
  Future<InstrumentInstanceRow?> getInstanceById(String id) {
    return (select(instrumentInstancesTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
