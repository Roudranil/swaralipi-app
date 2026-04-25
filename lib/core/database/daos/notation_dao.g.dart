// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notation_dao.dart';

// ignore_for_file: type=lint
mixin _$NotationDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotationsTableTable get notationsTable => attachedDatabase.notationsTable;
  NotationDaoManager get managers => NotationDaoManager(this);
}

class NotationDaoManager {
  final _$NotationDaoMixin _db;
  NotationDaoManager(this._db);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(
          _db.attachedDatabase, _db.notationsTable);
}
