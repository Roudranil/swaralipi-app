// InstrumentRepositoryImpl — concrete implementation of InstrumentRepository.
//
// Translates between Drift row types and domain models at the repository
// boundary. All write operations return the persisted domain model.
//
// Construct by injecting an [InstrumentDao]:
//   InstrumentRepositoryImpl(db.instrumentDao)

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/instrument_dao.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
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
  // InstrumentRepository — instance operations
  // -------------------------------------------------------------------------

  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
    String classId,
  ) {
    return _dao
        .watchActiveInstancesForClass(classId)
        .map((rows) => rows.map(_instanceRowToDomain).toList());
  }

  @override
  Future<InstrumentInstance> createInstance(
    String classId, {
    required String colorHex,
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  }) async {
    final id = _kUuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();

    await _dao.insertInstance(
      InstrumentInstancesTableCompanion.insert(
        id: id,
        classId: classId,
        colorHex: colorHex,
        brand: Value(brand),
        model: Value(model),
        priceInr: Value(priceInr),
        photoPath: Value(photoPath),
        notes: Value(notes),
        createdAt: now,
        updatedAt: now,
      ),
    );

    log(
      'InstrumentRepositoryImpl: created instance "$id" in class "$classId"',
      name: 'InstrumentRepository',
    );

    return InstrumentInstance(
      id: id,
      classId: classId,
      brand: brand,
      model: model,
      colorHex: colorHex,
      priceInr: priceInr,
      photoPath: photoPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<InstrumentInstance> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final companion = InstrumentInstancesTableCompanion(
      id: Value(id),
      brand: brand != null ? Value(brand) : const Value.absent(),
      model: model != null ? Value(model) : const Value.absent(),
      colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      priceInr: priceInr != null ? Value(priceInr) : const Value.absent(),
      photoPath: photoPath != null ? Value(photoPath) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(now),
    );

    final updated = await _dao.updateInstance(companion);
    if (!updated) {
      throw InstrumentInstanceNotFoundException(id);
    }

    final row = await _dao.getInstanceById(id);
    if (row == null) {
      throw InstrumentInstanceNotFoundException(id);
    }

    log(
      'InstrumentRepositoryImpl: updated instance "$id"',
      name: 'InstrumentRepository',
    );

    return _instanceRowToDomain(row);
  }

  @override
  Future<void> archiveInstance(String id) async {
    await _dao.archiveInstance(id);
    log(
      'InstrumentRepositoryImpl: archived instance "$id"',
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

  /// Converts an [InstrumentInstanceRow] to an [InstrumentInstance].
  InstrumentInstance _instanceRowToDomain(InstrumentInstanceRow row) =>
      InstrumentInstance(
        id: row.id,
        classId: row.classId,
        brand: row.brand,
        model: row.model,
        colorHex: row.colorHex,
        priceInr: row.priceInr,
        photoPath: row.photoPath,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );
}
