// UserPreferencesDao — Drift DAO for the user_preferences table.
//
// Exposes the singleton read (getPreferences) and upsert (upsertPreferences)
// operations required by the PreferencesRepository. All queries use Drift's
// type-safe query DSL; no raw SQL strings are used anywhere in this file.
//
// The `id = 1` singleton constraint is enforced at the DB level via a CHECK
// constraint. This DAO additionally creates the default row on first read so
// callers never receive null.
//
// Register this class in AppDatabase's @DriftDatabase(daos: [...]) annotation
// and call `UserPreferencesDao(db)` to construct an instance.

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';

part 'user_preferences_dao.g.dart';

/// Data-access object for the [UserPreferencesTable].
///
/// Manages the singleton user preferences row. [getPreferences] creates the
/// default row on first access so callers always receive a non-null value.
/// [upsertPreferences] replaces the singleton row, merging only the fields
/// present in the companion.
///
/// Business logic and domain-model translation belong in the repository layer,
/// not here.
@DriftAccessor(tables: [UserPreferencesTable])
class UserPreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$UserPreferencesDaoMixin {
  /// Creates a [UserPreferencesDao] attached to [db].
  UserPreferencesDao(super.db);

  // -------------------------------------------------------------------------
  // Read operations
  // -------------------------------------------------------------------------

  /// Returns the singleton user preferences row.
  ///
  /// If the row does not yet exist (first launch before seed migration), a
  /// default row is inserted and then returned. The returned row always has
  /// `id = 1`.
  Future<UserPreferencesRow> getPreferences() async {
    final existing = await (select(userPreferencesTable)
          ..where((t) => t.id.equals(_kSingletonId)))
        .getSingleOrNull();

    if (existing != null) {
      return existing;
    }

    // First access: insert the default singleton row and return it.
    await into(userPreferencesTable).insert(
      const UserPreferencesTableCompanion(),
    );
    log(
      'UserPreferencesDao: created default preferences row',
      name: 'UserPreferencesDao',
    );
    return (select(userPreferencesTable)
          ..where((t) => t.id.equals(_kSingletonId)))
        .getSingle();
  }

  // -------------------------------------------------------------------------
  // Write operations
  // -------------------------------------------------------------------------

  /// Inserts or updates the singleton user preferences row.
  ///
  /// If the row with `id = 1` does not yet exist it is inserted with the
  /// column defaults merged with [companion]. If it already exists, only the
  /// non-absent columns in [companion] are overwritten; all other columns
  /// retain their current database values.
  ///
  /// Parameters:
  /// - [companion]: A [UserPreferencesTableCompanion] with the fields to
  ///   persist. Omitted fields default to the column default values on insert
  ///   or are left unchanged on update.
  Future<void> upsertPreferences(
    UserPreferencesTableCompanion companion,
  ) async {
    final existing = await (select(userPreferencesTable)
          ..where((t) => t.id.equals(_kSingletonId)))
        .getSingleOrNull();

    if (existing == null) {
      await into(userPreferencesTable).insert(companion);
    } else {
      await (update(userPreferencesTable)
            ..where((t) => t.id.equals(_kSingletonId)))
          .write(companion);
    }
    log(
      'UserPreferencesDao: upserted preferences',
      name: 'UserPreferencesDao',
    );
  }
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// The fixed primary-key value for the singleton user preferences row.
///
/// Enforced at the database level via `CHECK (id = 1)`.
const int _kSingletonId = 1;
