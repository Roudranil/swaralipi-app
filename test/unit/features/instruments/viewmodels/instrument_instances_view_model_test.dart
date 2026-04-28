// Unit tests for InstrumentInstancesViewModel.
//
// Covers state transitions (idle → loading → success / error) and CRUD
// operations (createInstance, updateInstance, archiveInstance) via a
// FakeInstrumentRepository.
//
// Naming: <method> — <scenario> → <expected outcome>

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/storage/instrument_photo_service.dart';
import 'package:swaralipi/features/instruments/viewmodels/instrument_instances_view_model.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeInstrumentRepository implements InstrumentRepository {
  final StreamController<List<InstrumentInstance>> _instanceController =
      StreamController<List<InstrumentInstance>>.broadcast();
  List<InstrumentInstance> _instances = [];
  int _counter = 0;

  bool throwOnCreateInstance = false;
  bool throwOnUpdateInstance = false;
  bool throwOnArchiveInstance = false;

  void emitInstances(List<InstrumentInstance> instances) {
    _instances = instances;
    _instanceController.add(instances);
  }

  void emitError(Object error) => _instanceController.addError(error);

  // Satisfy interface — not needed by InstancesViewModel tests.
  @override
  Stream<List<InstrumentClass>> watchActiveClasses() => const Stream.empty();

  @override
  Future<InstrumentClass> createClass(String name) async => InstrumentClass(
        id: 'cls-1',
        name: name,
        createdAt: '2024-01-01T00:00:00Z',
        updatedAt: '2024-01-01T00:00:00Z',
      );

  @override
  Future<InstrumentClass> updateClass(String id, String name) async =>
      createClass(name);

  @override
  Future<void> archiveClass(String id) async {}

  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
    String classId,
  ) =>
      _instanceController.stream;

  @override
  Future<InstrumentInstance> createInstance(
    String classId, {
    String colorHex = '#cba6f7',
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  }) async {
    if (throwOnCreateInstance) throw Exception('create error');
    _counter++;
    final inst = InstrumentInstance(
      id: 'inst-$_counter',
      classId: classId,
      colorHex: colorHex,
      brand: brand,
      model: model,
      priceInr: priceInr,
      photoPath: photoPath,
      notes: notes,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );
    _instances = [..._instances, inst];
    _instanceController.add(_instances);
    return inst;
  }

  @override
  Future<InstrumentInstance> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  }) async {
    if (throwOnUpdateInstance) throw Exception('update error');
    final idx = _instances.indexWhere((i) => i.id == id);
    if (idx == -1) throw InstrumentInstanceNotFoundException(id);
    final updated = _instances[idx].copyWith(
      brand: brand,
      model: model,
      colorHex: colorHex,
      priceInr: priceInr,
      photoPath: photoPath,
      notes: notes,
    );
    _instances = [
      for (var i = 0; i < _instances.length; i++)
        if (i == idx) updated else _instances[i],
    ];
    _instanceController.add(_instances);
    return updated;
  }

  @override
  Future<void> archiveInstance(String id) async {
    if (throwOnArchiveInstance) throw Exception('archive error');
    _instances = _instances.where((i) => i.id != id).toList();
    _instanceController.add(_instances);
  }

  void dispose() => _instanceController.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kClassId = 'class-1';
const _kColorHex = '#cba6f7';

InstrumentInstance _inst(String id) => InstrumentInstance(
      id: id,
      classId: _kClassId,
      colorHex: _kColorHex,
      notes: '',
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeInstrumentRepository repo;
  late InstrumentInstancesViewModel vm;

  setUp(() {
    repo = _FakeInstrumentRepository();
    vm = InstrumentInstancesViewModel(repo, classId: _kClassId);
  });

  tearDown(() {
    vm.dispose();
    repo.dispose();
  });

  // -------------------------------------------------------------------------
  // init / state transitions
  // -------------------------------------------------------------------------

  group('init — state transitions', () {
    test('starts in idle state', () {
      expect(vm.state, isA<InstrumentInstancesStateIdle>());
    });

    test('transitions to loading then success on init', () async {
      vm.init();
      expect(vm.state, isA<InstrumentInstancesStateLoading>());

      repo.emitInstances([_inst('i1'), _inst('i2')]);
      await Future.microtask(() {});

      final state = vm.state;
      expect(state, isA<InstrumentInstancesStateSuccess>());
      expect(
        (state as InstrumentInstancesStateSuccess).instances,
        hasLength(2),
      );
    });

    test('transitions to error when stream emits error', () async {
      vm.init();
      repo.emitError(Exception('db error'));
      await Future.microtask(() {});

      expect(vm.state, isA<InstrumentInstancesStateError>());
    });

    test('cancels old subscription on second init call', () async {
      vm.init();
      repo.emitInstances([_inst('i1')]);
      await Future.microtask(() {});

      vm.init();
      expect(vm.state, isA<InstrumentInstancesStateLoading>());
    });
  });

  // -------------------------------------------------------------------------
  // createInstance
  // -------------------------------------------------------------------------

  group('createInstance', () {
    setUp(() => vm.init());

    test('succeeds and returns instance', () async {
      final inst = await vm.createInstance(colorHex: _kColorHex, brand: 'X');
      expect(inst, isNotNull);
      expect(inst!.brand, 'X');
      expect(vm.createError, isNull);
    });

    test('populates createError on failure', () async {
      repo.throwOnCreateInstance = true;
      final inst = await vm.createInstance(colorHex: _kColorHex);
      expect(inst, isNull);
      expect(vm.createError, isNotNull);
    });

    test('clearCreateError resets error', () async {
      repo.throwOnCreateInstance = true;
      await vm.createInstance(colorHex: _kColorHex);
      vm.clearCreateError();
      expect(vm.createError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // updateInstance
  // -------------------------------------------------------------------------

  group('updateInstance', () {
    late InstrumentInstance existing;

    setUp(() async {
      vm.init();
      existing = await vm
          .createInstance(colorHex: _kColorHex, brand: 'Old')
          .then((v) => v!);
    });

    test('succeeds and returns updated instance', () async {
      final updated = await vm.updateInstance(existing.id, brand: 'New');
      expect(updated, isNotNull);
      expect(updated!.brand, 'New');
      expect(vm.updateError, isNull);
    });

    test('populates updateError on failure', () async {
      repo.throwOnUpdateInstance = true;
      final updated = await vm.updateInstance(existing.id, brand: 'X');
      expect(updated, isNull);
      expect(vm.updateError, isNotNull);
    });

    test('clearUpdateError resets error', () async {
      repo.throwOnUpdateInstance = true;
      await vm.updateInstance(existing.id, brand: 'X');
      vm.clearUpdateError();
      expect(vm.updateError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // archiveInstance
  // -------------------------------------------------------------------------

  group('archiveInstance', () {
    late InstrumentInstance existing;

    setUp(() async {
      vm.init();
      existing = await vm.createInstance(colorHex: _kColorHex).then((v) => v!);
    });

    test('succeeds without error', () async {
      await vm.archiveInstance(existing.id);
      expect(vm.archiveError, isNull);
    });

    test('populates archiveError on failure', () async {
      repo.throwOnArchiveInstance = true;
      await vm.archiveInstance(existing.id);
      expect(vm.archiveError, isNotNull);
    });

    test('clearArchiveError resets error', () async {
      repo.throwOnArchiveInstance = true;
      await vm.archiveInstance(existing.id);
      vm.clearArchiveError();
      expect(vm.archiveError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // savePhoto / deleteOldPhoto via FileStorageService
  // -------------------------------------------------------------------------

  group('savePhoto', () {
    test('saveInstrumentPhoto saves file and returns relative path', () async {
      final dir = await Directory.systemTemp.createTemp('inst_test_');
      try {
        final svc = InstrumentPhotoService(dirProvider: () async => dir);
        final file = File('${dir.path}/test.jpg');
        await file.writeAsBytes([1, 2, 3]);

        final rel = await svc.savePhoto(file.path, 'inst-123');
        expect(rel, contains('instruments/inst-123/photo.jpg'));
        expect(File('${dir.path}/$rel').existsSync(), isTrue);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('deletePhoto removes existing file', () async {
      final dir = await Directory.systemTemp.createTemp('inst_test2_');
      try {
        final svc = InstrumentPhotoService(dirProvider: () async => dir);
        final file = File('${dir.path}/test.jpg');
        await file.writeAsBytes([1, 2, 3]);
        final rel = await svc.savePhoto(file.path, 'inst-456');

        await svc.deletePhoto(rel);
        expect(File('${dir.path}/$rel').existsSync(), isFalse);
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test('deletePhoto is no-op when file absent', () async {
      final dir = await Directory.systemTemp.createTemp('inst_test3_');
      try {
        final svc = InstrumentPhotoService(dirProvider: () async => dir);
        // Should not throw.
        await expectLater(
          () => svc.deletePhoto('instruments/no-such/photo.jpg'),
          returnsNormally,
        );
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });
}
