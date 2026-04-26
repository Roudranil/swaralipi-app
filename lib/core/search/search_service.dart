// SearchService — FTS5 BM25 full-text search over the notations table.
//
// Implements two-phase search as specified in sds.md §6.4:
//   1. FTS phase  — SQLite FTS5 query via FtsDao (BM25 ranked, prefix-matched).
//   2. Empty path — direct SQL query ordered by updated_at DESC when the
//                   caller supplies a blank query.
//
// Returns only notation IDs (List<String>). Callers are responsible for
// hydrating full notation objects from NotationRepository.
//
// Performance target: < 200 ms on 1 000 notations (sds.md §9.1).

import 'dart:developer';

import 'package:drift/drift.dart';
import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/fts_dao.dart';

/// Default maximum results returned per page.
const int _kDefaultLimit = 20;

/// Default number of leading results to skip.
const int _kDefaultOffset = 0;

/// Service that runs FTS5 BM25 ranked queries and returns notation IDs.
///
/// For non-empty queries the service delegates to [FtsDao], which issues a
/// parameterised FTS5 `MATCH '<query>*'` query with prefix matching and
/// excludes soft-deleted notations via a JOIN.
///
/// For empty / whitespace-only queries the service falls back to a direct
/// table scan that returns all active notation IDs ordered by `updated_at`
/// descending — matching the default library sort (data-model.md §8.1).
///
/// Inject [AppDatabase] and [FtsDao] via the constructor; this keeps the
/// service testable with [AppDatabase.forTesting] without any additional
/// mocking infrastructure.
class SearchService {
  /// Creates a [SearchService].
  ///
  /// Parameters:
  /// - [db]: The application database instance. Used for the empty-query
  ///   fallback and for [reindexAll].
  /// - [ftsDao]: The FTS5 DAO used for ranked full-text queries.
  const SearchService({
    required AppDatabase db,
    required FtsDao ftsDao,
  })  : _db = db,
        _ftsDao = ftsDao;

  final AppDatabase _db;
  final FtsDao _ftsDao;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Searches notations by full-text query and returns a list of notation IDs.
  ///
  /// When [query] is empty or contains only whitespace, returns all active
  /// notation IDs ordered by `updated_at` descending (most-recently updated
  /// first). When [query] is non-empty, delegates to [FtsDao] for a BM25-
  /// ranked FTS5 query with prefix matching (e.g. `"Bhai"` matches
  /// `"Bhairavi"`).
  ///
  /// Soft-deleted notations are always excluded.
  ///
  /// Returns a [List<String>] of notation UUIDs. The list is empty when no
  /// notations match.
  ///
  /// Parameters:
  /// - [query]: The user-supplied search string. Prefix matching is applied
  ///   automatically for non-empty values. Whitespace-only strings are treated
  ///   as empty.
  /// - [limit]: Maximum number of IDs to return. Must be > 0.
  ///   Defaults to [_kDefaultLimit] (20).
  /// - [offset]: Number of leading results to skip for pagination.
  ///   Must be >= 0. Defaults to 0.
  Future<List<String>> search(
    String query, {
    int limit = _kDefaultLimit,
    int offset = _kDefaultOffset,
  }) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      return _allActiveIds(limit: limit, offset: offset);
    }

    return _ftsSearch(trimmed, limit: limit, offset: offset);
  }

  /// Rebuilds the FTS5 index from scratch.
  ///
  /// Drops the existing `notations_fts` virtual table and its sync triggers,
  /// then recreates them via [AppDatabase.createFtsSchema]. Existing rows in
  /// `notations_table` are re-indexed automatically by the `content=` option
  /// on the FTS5 table.
  ///
  /// Call this on startup if the FTS index may be out of sync (e.g. after a
  /// crash during a write). The operation is safe to call at any time — the
  /// IF NOT EXISTS / DROP approach ensures no duplicate objects are created.
  Future<void> reindexAll() async {
    log('SearchService: reindexAll — dropping FTS schema',
        name: 'SearchService');

    await _db.customStatement('DROP TABLE IF EXISTS notations_fts');
    await _db.customStatement('DROP TRIGGER IF EXISTS notations_ai');
    await _db.customStatement('DROP TRIGGER IF EXISTS notations_ad');
    await _db.customStatement('DROP TRIGGER IF EXISTS notations_au');

    await _db.createFtsSchema();

    // Repopulate the FTS index from the content table. When the virtual table
    // uses `content='notations_table'`, SQLite stores no row data inside the
    // FTS index itself — only the BM25 ranking structures. After a fresh
    // CREATE VIRTUAL TABLE the index is empty; issuing the special 'rebuild'
    // command scans the content table and rebuilds the full FTS index.
    await _db.customStatement(
      "INSERT INTO notations_fts(notations_fts) VALUES('rebuild')",
    );

    log('SearchService: reindexAll — FTS schema rebuilt',
        name: 'SearchService');
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Returns all active notation IDs ordered by [updatedAt] descending.
  ///
  /// Used as the fallback path when [search] is called with an empty query.
  Future<List<String>> _allActiveIds({
    required int limit,
    required int offset,
  }) async {
    final rows = await (_db.select(_db.notationsTable)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit, offset: offset))
        .get();

    log(
      'SearchService: empty query returned ${rows.length} ID(s)',
      name: 'SearchService',
    );

    return List.unmodifiable(rows.map((r) => r.id));
  }

  /// Delegates to [FtsDao] and extracts notation IDs from the result rows.
  Future<List<String>> _ftsSearch(
    String trimmedQuery, {
    required int limit,
    required int offset,
  }) async {
    final rows = await _ftsDao.search(
      trimmedQuery,
      limit: limit,
      offset: offset,
    );

    log(
      'SearchService: FTS query "$trimmedQuery" returned ${rows.length} ID(s)',
      name: 'SearchService',
    );

    return List.unmodifiable(rows.map((r) => r.id));
  }
}
