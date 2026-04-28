// TrashRepositoryImpl — concrete implementation of TrashRepository.
//
// Translates between [NotationRow] (Drift) and [Notation] (domain model).
// Hard-delete operations remove the DB row and call
// [FileStorageService.deleteNotationDirectory] to clean up image files.
//
// Auto-purge: deletes all rows where deleted_at < now − 30 days. Safe to
// call on every app launch — it is a no-op when no rows have expired.
//
// Construct by injecting [NotationDao] and [FileStorageService]:
//   TrashRepositoryImpl(db.notationDao, fileStorageService)

import 'dart:convert';
import 'dart:developer';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Number of days after which a trashed notation is automatically purged.
const int _kAutoPurgeDays = 30;

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [TrashRepository] backed by a Drift
/// [NotationDao] and a [FileStorageService].
///
/// Handles all soft-delete lifecycle operations: streaming the trash list,
/// restoring notations, permanently deleting individual notations or all
/// trashed notations, and auto-purging entries older than 30 days.
///
/// The [FileStorageService] is called after each DB hard-delete to remove
/// the notation's image directory from disk.
final class TrashRepositoryImpl implements TrashRepository {
  /// Creates a [TrashRepositoryImpl] with the given [_dao] and [_storage].
  ///
  /// Parameters:
  /// - [_dao]: Drift DAO providing all notation DB operations.
  /// - [_storage]: Service managing notation image directories on disk.
  /// - [nowProvider]: Optional override for "now" used in expiry
  ///   calculations. Useful in tests to inject a deterministic timestamp.
  const TrashRepositoryImpl(
    this._dao,
    this._storage, {
    DateTime Function()? nowProvider,
  }) : _nowProvider = nowProvider;

  final NotationDao _dao;
  final FileStorageService _storage;
  final DateTime Function()? _nowProvider;

  // -------------------------------------------------------------------------
  // TrashRepository interface
  // -------------------------------------------------------------------------

  @override
  Stream<List<Notation>> watchTrashedNotations() {
    return _dao.watchDeleted().map(
          (rows) => rows.map(_rowToNotation).toList(),
        );
  }

  @override
  Future<void> restoreNotation(String id) async {
    await _dao.restore(id);
    log(
      'TrashRepositoryImpl: restored notation $id',
      name: 'TrashRepository',
    );
  }

  @override
  Future<void> purgeNotation(String id) async {
    await _dao.deleteNotation(id);
    await _storage.deleteNotationDirectory(id);
    log(
      'TrashRepositoryImpl: purged notation $id',
      name: 'TrashRepository',
    );
  }

  @override
  Future<void> purgeAll() async {
    final trashed = await _dao.getAllTrashed();
    for (final row in trashed) {
      await _dao.deleteNotation(row.id);
      await _storage.deleteNotationDirectory(row.id);
    }
    log(
      'TrashRepositoryImpl: purged all ${trashed.length} trashed notation(s)',
      name: 'TrashRepository',
    );
  }

  @override
  Future<int> autoPurgeExpired() async {
    final now = _nowProvider?.call() ?? DateTime.now().toUtc();
    final cutoff = now.subtract(const Duration(days: _kAutoPurgeDays));
    final cutoffIso = cutoff.toIso8601String();

    final expired = await _dao.getExpiredTrashed(cutoffIso);
    for (final row in expired) {
      await _dao.deleteNotation(row.id);
      await _storage.deleteNotationDirectory(row.id);
    }

    log(
      'TrashRepositoryImpl: auto-purged ${expired.length} expired notation(s) '
      '(cutoff: $cutoffIso)',
      name: 'TrashRepository',
    );
    return expired.length;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  /// Converts a [NotationRow] to a [Notation] domain model.
  Notation _rowToNotation(NotationRow row) {
    final artists = _parseJsonStringList(row.artists);
    final languages = _parseJsonStringList(row.languages);

    return Notation(
      id: row.id,
      title: row.title,
      artists: artists,
      dateWritten: row.dateWritten,
      timeSig: row.timeSig,
      keySig: row.keySig,
      languages: languages,
      notes: row.notes,
      playCount: row.playCount,
      lastPlayedAt: row.lastPlayedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  /// Parses a JSON-encoded string list stored in the DB.
  ///
  /// The DB stores arrays as `'["Hindi","Bengali"]'`. Returns an empty list
  /// if [json] is empty, already `'[]'`, or cannot be decoded.
  List<String> _parseJsonStringList(String json) {
    if (json.isEmpty || json == '[]') return const [];
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return const [];
      return decoded.cast<String>();
    } on FormatException {
      return const [];
    }
  }
}
