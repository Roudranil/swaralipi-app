// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_field_dao.dart';

// ignore_for_file: type=lint
mixin _$CustomFieldDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomFieldDefinitionsTableTable get customFieldDefinitionsTable =>
      attachedDatabase.customFieldDefinitionsTable;
  $NotationsTableTable get notationsTable => attachedDatabase.notationsTable;
  $NotationCustomFieldsTableTable get notationCustomFieldsTable =>
      attachedDatabase.notationCustomFieldsTable;
  CustomFieldDaoManager get managers => CustomFieldDaoManager(this);
}

class CustomFieldDaoManager {
  final _$CustomFieldDaoMixin _db;
  CustomFieldDaoManager(this._db);
  $$CustomFieldDefinitionsTableTableTableManager
      get customFieldDefinitionsTable =>
          $$CustomFieldDefinitionsTableTableTableManager(
              _db.attachedDatabase, _db.customFieldDefinitionsTable);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(
          _db.attachedDatabase, _db.notationsTable);
  $$NotationCustomFieldsTableTableTableManager get notationCustomFieldsTable =>
      $$NotationCustomFieldsTableTableTableManager(
          _db.attachedDatabase, _db.notationCustomFieldsTable);
}
