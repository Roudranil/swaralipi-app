// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument_dao.dart';

// ignore_for_file: type=lint
mixin _$InstrumentDaoMixin on DatabaseAccessor<AppDatabase> {
  $InstrumentClassesTableTable get instrumentClassesTable =>
      attachedDatabase.instrumentClassesTable;
  $InstrumentInstancesTableTable get instrumentInstancesTable =>
      attachedDatabase.instrumentInstancesTable;
  InstrumentDaoManager get managers => InstrumentDaoManager(this);
}

class InstrumentDaoManager {
  final _$InstrumentDaoMixin _db;
  InstrumentDaoManager(this._db);
  $$InstrumentClassesTableTableTableManager get instrumentClassesTable =>
      $$InstrumentClassesTableTableTableManager(
          _db.attachedDatabase, _db.instrumentClassesTable);
  $$InstrumentInstancesTableTableTableManager get instrumentInstancesTable =>
      $$InstrumentInstancesTableTableTableManager(
          _db.attachedDatabase, _db.instrumentInstancesTable);
}
