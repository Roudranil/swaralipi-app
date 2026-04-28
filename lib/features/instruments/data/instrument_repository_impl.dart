// InstrumentRepositoryImpl — concrete implementation of InstrumentRepository.
//
// Translates between [InstrumentClassRow] (Drift) and [InstrumentClass]
// (domain model). All write operations return the persisted domain model.
//
// Construct by injecting an [InstrumentDao]:
//   InstrumentRepositoryImpl(db.instrumentDao)

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/instrument_dao.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Shared [Uuid] generator instance used by [InstrumentRepositoryImpl].
const _kUuid = Uuid();

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [InstrumentRepository] backed by a Drift
/// [InstrumentDao].
///
/// Translates [InstrumentClassRow] database rows to [InstrumentClass] domain
/// models at the repository boundary. Business logic (UUID generation,
/// timestamp stamping) lives here; the [InstrumentDao] is responsible only
/// for typed SQL.
final class InstrumentRepositoryImpl implements InstrumentRepository {
  /// Creates an [InstrumentRepositoryImpl] with the given [_dao].
  ///
  /// Parameters:
  /// - [_dao]: The Drift DAO for instrument tables.
  const InstrumentRepositoryImpl(this._dao);

  final InstrumentDao _dao;

  // -------------------------------------------------------------------------
  // InstrumentRepository interface
  // -------------------------------------------------------------------------

  @override
  Stream<List<InstrumentClass>> watchActiveClasses() {
    return _dao.watchActiveClasses().map(
          (rows) => rows.map(_rowToDomain).toList(),
        );
  }

  @override
  Future<InstrumentClass> createClass(String name) async {
    final id = _kUuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _dao.insertClass(
      InstrumentClassesTableCompanion.insert(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );

    log(
      'InstrumentRepositoryImpl: created class "$name" ($id)',
      name: 'InstrumentRepository',
    );

    return InstrumentClass(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<InstrumentClass> updateClass(String id, String name) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final companion = InstrumentClassesTableCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(now),
    );

    final updated = await _dao.updateClass(companion);
    if (!updated) {
      throw InstrumentClassNotFoundException(id);
    }

    final rows = await _dao.getActiveClasses();
    final row = rows.where((r) => r.id == id).firstOrNull;
    if (row != null) return _rowToDomain(row);

    // Row was updated but is now archived (edge case: archived before we read).
    // Return a synthetic model with the new name from what we know.
    return InstrumentClass(
      id: id,
      name: name,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> archiveClass(String id) async {
    await _dao.archiveClass(id);
    log(
      'InstrumentRepositoryImpl: archived class $id',
      name: 'InstrumentRepository',
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Converts an [InstrumentClassRow] to an [InstrumentClass].
  InstrumentClass _rowToDomain(InstrumentClassRow row) => InstrumentClass(
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
