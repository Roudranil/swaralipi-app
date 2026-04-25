// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notation_page_dao.dart';

// ignore_for_file: type=lint
mixin _$NotationPageDaoMixin on DatabaseAccessor<AppDatabase> {
  $NotationsTableTable get notationsTable => attachedDatabase.notationsTable;
  $NotationPagesTableTable get notationPagesTable =>
      attachedDatabase.notationPagesTable;
  NotationPageDaoManager get managers => NotationPageDaoManager(this);
}

class NotationPageDaoManager {
  final _$NotationPageDaoMixin _db;
  NotationPageDaoManager(this._db);
  $$NotationsTableTableTableManager get notationsTable =>
      $$NotationsTableTableTableManager(
          _db.attachedDatabase, _db.notationsTable);
  $$NotationPagesTableTableTableManager get notationPagesTable =>
      $$NotationPagesTableTableTableManager(
          _db.attachedDatabase, _db.notationPagesTable);
}
