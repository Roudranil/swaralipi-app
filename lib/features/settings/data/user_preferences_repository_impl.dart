// UserPreferencesRepositoryImpl — concrete implementation of
// PreferencesRepository.
//
// Translates between [UserPreferencesRow] (Drift) and [UserPreferences]
// (domain model). Depends on [UserPreferencesDao] for all DB access.
//
// Implements both [PreferencesRepository] (full contract) and therefore also
// satisfies the narrow [UserPreferencesRepository] used by TagRepositoryImpl.
//
// Construct by injecting a [UserPreferencesDao]:
//   UserPreferencesRepositoryImpl(db.userPreferencesDao)

import 'dart:developer';

import 'package:drift/drift.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/user_preferences_dao.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// The singleton row id enforced by `CHECK (id = 1)`.
const int _kSingletonId = 1;

// ---------------------------------------------------------------------------
// Implementation
// ---------------------------------------------------------------------------

/// Concrete implementation of [PreferencesRepository].
///
/// Reads and writes the singleton [UserPreferences] row via
/// [UserPreferencesDao]. All domain-model ↔ DB-row translation is performed
/// here; [UserPreferencesDao] deals only with raw Drift companions and rows.
///
/// Targeted write methods ([updateThemeMode], [updateColorSchemeMode],
/// [updateSeedColor]) perform a read-modify-write cycle so that only the
/// relevant field changes and all other columns retain their current values.
final class UserPreferencesRepositoryImpl implements PreferencesRepository {
  /// Creates a [UserPreferencesRepositoryImpl] backed by [_dao].
  ///
  /// Parameters:
  /// - [_dao]: The Drift DAO for the `user_preferences_table`.
  const UserPreferencesRepositoryImpl(this._dao);

  final UserPreferencesDao _dao;

  // -------------------------------------------------------------------------
  // PreferencesRepository interface
  // -------------------------------------------------------------------------

  @override
  Future<UserPreferences> getPreferences() async {
    final row = await _dao.getPreferences();
    return _rowToPreferences(row);
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    await _dao.upsertPreferences(
      UserPreferencesTableCompanion(
        id: const Value(_kSingletonId),
        userName: Value(preferences.userName),
        themeMode: Value(preferences.themeMode.dbValue),
        colorSchemeMode: Value(preferences.colorSchemeMode.dbValue),
        seedColor: Value(preferences.seedColor),
        defaultSort: Value(preferences.defaultSort.dbValue),
        defaultView: Value(preferences.defaultView.dbValue),
        tagsSeeded: Value(preferences.tagsSeeded ? 1 : 0),
      ),
    );
    log(
      'UserPreferencesRepositoryImpl: updated preferences',
      name: 'UserPreferencesRepository',
    );
  }

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {
    final existing = await _dao.getPreferences();
    await _dao.upsertPreferences(
      UserPreferencesTableCompanion(
        id: const Value(_kSingletonId),
        userName: Value(existing.userName),
        themeMode: Value(mode.dbValue),
        colorSchemeMode: Value(existing.colorSchemeMode),
        seedColor: Value(existing.seedColor),
        defaultSort: Value(existing.defaultSort),
        defaultView: Value(existing.defaultView),
        tagsSeeded: Value(existing.tagsSeeded),
      ),
    );
    log(
      'UserPreferencesRepositoryImpl: themeMode set to ${mode.dbValue}',
      name: 'UserPreferencesRepository',
    );
  }

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {
    final existing = await _dao.getPreferences();
    await _dao.upsertPreferences(
      UserPreferencesTableCompanion(
        id: const Value(_kSingletonId),
        userName: Value(existing.userName),
        themeMode: Value(existing.themeMode),
        colorSchemeMode: Value(mode.dbValue),
        seedColor: Value(existing.seedColor),
        defaultSort: Value(existing.defaultSort),
        defaultView: Value(existing.defaultView),
        tagsSeeded: Value(existing.tagsSeeded),
      ),
    );
    log(
      'UserPreferencesRepositoryImpl: colorSchemeMode set to ${mode.dbValue}',
      name: 'UserPreferencesRepository',
    );
  }

  @override
  Future<void> updateSeedColor(String? colorHex) async {
    final existing = await _dao.getPreferences();
    await _dao.upsertPreferences(
      UserPreferencesTableCompanion(
        id: const Value(_kSingletonId),
        userName: Value(existing.userName),
        themeMode: Value(existing.themeMode),
        colorSchemeMode: Value(existing.colorSchemeMode),
        seedColor: Value(colorHex),
        defaultSort: Value(existing.defaultSort),
        defaultView: Value(existing.defaultView),
        tagsSeeded: Value(existing.tagsSeeded),
      ),
    );
    log(
      'UserPreferencesRepositoryImpl: seedColor set to $colorHex',
      name: 'UserPreferencesRepository',
    );
  }

  @override
  Future<void> updateTagsSeeded({required bool value}) async {
    final existing = await _dao.getPreferences();
    await _dao.upsertPreferences(
      UserPreferencesTableCompanion(
        id: const Value(_kSingletonId),
        userName: Value(existing.userName),
        themeMode: Value(existing.themeMode),
        colorSchemeMode: Value(existing.colorSchemeMode),
        seedColor: Value(existing.seedColor),
        defaultSort: Value(existing.defaultSort),
        defaultView: Value(existing.defaultView),
        tagsSeeded: Value(value ? 1 : 0),
      ),
    );
    log(
      'UserPreferencesRepositoryImpl: tagsSeeded set to $value',
      name: 'UserPreferencesRepository',
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Converts a [UserPreferencesRow] to a [UserPreferences] domain model.
  UserPreferences _rowToPreferences(UserPreferencesRow row) {
    final themeMode = AppThemeMode.values.firstWhere(
      (m) => m.dbValue == row.themeMode,
      orElse: () => AppThemeMode.system,
    );
    final colorSchemeMode = ColorSchemeMode.values.firstWhere(
      (m) => m.dbValue == row.colorSchemeMode,
      orElse: () => ColorSchemeMode.catppuccin,
    );
    final defaultSort = SortOrder.values.firstWhere(
      (s) => s.dbValue == row.defaultSort,
      orElse: () => SortOrder.createdAtDesc,
    );
    final defaultView = ViewMode.values.firstWhere(
      (v) => v.dbValue == row.defaultView,
      orElse: () => ViewMode.list,
    );

    return UserPreferences(
      userName: row.userName,
      themeMode: themeMode,
      colorSchemeMode: colorSchemeMode,
      seedColor: row.seedColor,
      defaultSort: defaultSort,
      defaultView: defaultView,
      tagsSeeded: row.tagsSeeded == 1,
    );
  }
}
