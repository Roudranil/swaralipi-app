// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences_dao.dart';

// ignore_for_file: type=lint
mixin _$UserPreferencesDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserPreferencesTableTable get userPreferencesTable =>
      attachedDatabase.userPreferencesTable;
  UserPreferencesDaoManager get managers => UserPreferencesDaoManager(this);
}

class UserPreferencesDaoManager {
  final _$UserPreferencesDaoMixin _db;
  UserPreferencesDaoManager(this._db);
  $$UserPreferencesTableTableTableManager get userPreferencesTable =>
      $$UserPreferencesTableTableTableManager(
          _db.attachedDatabase, _db.userPreferencesTable);
}
