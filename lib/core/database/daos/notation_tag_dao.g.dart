// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notation_tag_dao.dart';

// ignore_for_file: type=lint
mixin _$NotationTagDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotationsTableTable get notationsTable => attachedDatabase.notationsTable;
  $TagsTableTable get tagsTable => attachedDatabase.tagsTable;
  $NotationTagsTableTable get notationTagsTable =>
      attachedDatabase.notationTagsTable;
  NotationTagDaoManager get managers => NotationTagDaoManager(this);
}

class NotationTagDaoManager {
  final _$NotationTagDaoMixin _db;
  NotationTagDaoManager(this._db);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(
          _db.attachedDatabase, _db.notationsTable);
  $$TagsTableTableTableManager get tagsTable =>
      $$TagsTableTableTableManager(_db.attachedDatabase, _db.tagsTable);
  $$NotationTagsTableTableTableManager get notationTagsTable =>
      $$NotationTagsTableTableTableManager(
          _db.attachedDatabase, _db.notationTagsTable);
}
