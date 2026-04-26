// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fts_dao.dart';

// ignore_for_file: type=lint
mixin _$FtsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotationsTableTable get notationsTable => attachedDatabase.notationsTable;
  FtsDaoManager get managers => FtsDaoManager(this);
}

class FtsDaoManager {
  final _$FtsDaoMixin _db;
  FtsDaoManager(this._db);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(
          _db.attachedDatabase, _db.notationsTable);
}
