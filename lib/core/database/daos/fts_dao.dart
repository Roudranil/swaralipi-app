// FtsDao — Drift DAO for FTS5 full-text search on the notations table.
//
// The FTS5 virtual table `notations_fts` is created in AppDatabase.onCreate
// alongside three SQLite triggers (AFTER INSERT, AFTER UPDATE, AFTER DELETE)
// that keep the index in sync with the `notations` table.
//
// This DAO issues BM25-ranked FTS5 queries with prefix matching and filters
// out soft-deleted notations via a JOIN on `deleted_at IS NULL`.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'fts_dao.g.dart';

/// Search result row returned by [FtsDao.search].
///
/// Contains a subset of [NotationRow] fields needed by the repository layer.
/// The full [NotationRow] is included so callers can access any column.
typedef FtsSearchResult = NotationRow;

/// Data-access object for FTS5 full-text search over the notations table.
///
/// Queries the `notations_fts` virtual table (created during [AppDatabase]
/// schema initialisation) and joins back to the `notations` table to filter
/// soft-deleted rows. Returns BM25-ranked results with prefix matching.
///
/// Business logic and domain-model translation belong in the repository layer,
/// not here.
@DriftAccessor(tables: [NotationsTable])
class FtsDao extends DatabaseAccessor<AppDatabase> with _$FtsDaoMixin {
  /// Creates a [FtsDao] attached to [db].
  FtsDao(super.db);

  /// Searches notations using an FTS5 BM25-ranked query.
  ///
  /// Appends `*` to [query] for prefix matching (e.g. `"Yam"` matches
  /// `"Yaman"`). Filters out soft-deleted notations (`deleted_at IS NULL`).
  /// Returns an empty list when [query] is blank or matches nothing.
  ///
  /// Results are ordered by BM25 relevance score (best match first).
  ///
  /// Parameters:
  /// - [query]: The user-supplied search string. Prefix matching is applied
  ///   automatically. Must not contain FTS5 special characters from user input
  ///   — callers should sanitize before passing here.
  /// - [limit]: Maximum number of rows to return. Must be > 0.
  /// - [offset]: Number of leading rows to skip for pagination. Must be >= 0.
  Future<List<FtsSearchResult>> search(
    String query, {
    required int limit,
    required int offset,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    // Parameterised FTS5 query with prefix match and BM25 ranking.
    // The JOIN to `notations` filters soft-deleted rows without touching
    // the FTS index directly — soft-deleted rows remain in the FTS table
    // but are excluded here, as specified in data-model.md §2.11.
    // Drift generates the SQLite table name as 'notations_table'.
    final rows = await customSelect(
      '''
      SELECT n.*
      FROM notations_table AS n
      JOIN notations_fts AS fts ON fts.rowid = n.rowid
      WHERE notations_fts MATCH ?
        AND n.deleted_at IS NULL
      ORDER BY rank
      LIMIT ? OFFSET ?
      ''',
      variables: [
        Variable.withString('$trimmed*'),
        Variable.withInt(limit),
        Variable.withInt(offset),
      ],
      readsFrom: {notationsTable},
    ).get();

    final results = rows.map((row) => notationsTable.map(row.data)).toList();
    log(
      'FtsDao: search("$trimmed") returned ${results.length} result(s)',
      name: 'FtsDao',
    );
    return results;
  }
}
