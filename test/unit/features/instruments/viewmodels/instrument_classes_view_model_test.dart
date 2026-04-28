// Unit tests for InstrumentClassesViewModel.
//
// Tests all state transitions (idle → loading → success / error) and CRUD
// operations using a FakeInstrumentRepository.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/instruments/viewmodels/instrument_classes_view_model.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class _FakeInstrumentRepository implements InstrumentRepository {
  final StreamController<List<InstrumentClass>> _controller =
      StreamController<List<InstrumentClass>>.broadcast();
  List<InstrumentClass> _classes = [];

  bool throwOnCreate = false;
  bool throwOnUpdate = false;
  bool throwOnArchive = false;

  void emitClasses(List<InstrumentClass> classes) {
    _classes = classes;
    _controller.add(classes);
  }

  void emitError(Object error) {
    _controller.addError(error);
  }

  @override
  Stream<List<InstrumentClass>> watchActiveClasses() => _controller.stream;

  @override
  Future<InstrumentClass> createClass(String name) async {
    if (throwOnCreate) throw Exception('create error');
    final cls = InstrumentClass(
      id: 'id-$name',
      name: name,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );
    _classes = [..._classes, cls];
    _controller.add(_classes);
    return cls;
  }

  @override
  Future<InstrumentClass> updateClass(String id, String name) async {
    if (throwOnUpdate) throw Exception('update error');
    final idx = _classes.indexWhere((c) => c.id == id);
    if (idx == -1) throw InstrumentClassNotFoundException(id);
    final updated = _classes[idx].copyWith(name: name);
    _classes = [
      for (var i = 0; i < _classes.length; i++)
        if (i == idx) updated else _classes[i],
    ];
    _controller.add(_classes);
    return updated;
  }

  @override
  Future<void> archiveClass(String id) async {
    if (throwOnArchive) throw Exception('archive error');
    _classes = _classes.where((c) => c.id != id).toList();
    _controller.add(_classes);
  }

  // Instance methods — not exercised in these tests.
  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
    String classId,
  ) =>
      const Stream.empty();

  @override
  Future<InstrumentInstance> createInstance(
    String classId, {
    required String colorHex,
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  }) async =>
      throw UnimplementedError();

  @override
  Future<InstrumentInstance> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> archiveInstance(String id) async => throw UnimplementedError();

  void dispose() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

InstrumentClass _makeClass(String id, String name) => InstrumentClass(
      id: id,
      name: name,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('InstrumentClassesViewModel.init', () {
    late _FakeInstrumentRepository repo;
    late InstrumentClassesViewModel vm;

    setUp(() {
      repo = _FakeInstrumentRepository();
      vm = InstrumentClassesViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
      repo.dispose();
    });

    test('starts in idle state', () {
      expect(vm.state, isA<InstrumentClassesStateIdle>());
    });

    test('transitions to loading then success on stream emission', () async {
      vm.init();
      expect(vm.state, isA<InstrumentClassesStateLoading>());

      repo.emitClasses([_makeClass('1', 'Sitar')]);
      await Future<void>.microtask(() {});

      expect(vm.state, isA<InstrumentClassesStateSuccess>());
      final success = vm.state as InstrumentClassesStateSuccess;
      expect(success.classes, hasLength(1));
      expect(success.classes.first.name, 'Sitar');
    });

    test('transitions to error when stream emits an error', () async {
      vm.init();
      repo.emitError(Exception('db failure'));
      await Future<void>.microtask(() {});

      expect(vm.state, isA<InstrumentClassesStateError>());
    });

    test('success state carries updated list on re-emission', () async {
      vm.init();
      repo.emitClasses([_makeClass('1', 'Sitar')]);
      await Future<void>.microtask(() {});

      repo.emitClasses([
        _makeClass('1', 'Sitar'),
        _makeClass('2', 'Tabla'),
      ]);
      await Future<void>.microtask(() {});

      final success = vm.state as InstrumentClassesStateSuccess;
      expect(success.classes, hasLength(2));
    });
  });

  group('InstrumentClassesViewModel.createClass', () {
    late _FakeInstrumentRepository repo;
    late InstrumentClassesViewModel vm;

    setUp(() {
      repo = _FakeInstrumentRepository();
      vm = InstrumentClassesViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
      repo.dispose();
    });

    test('returns InstrumentClass on success', () async {
      final cls = await vm.createClass('Sitar');
      expect(cls, isNotNull);
      expect(cls!.name, 'Sitar');
    });

    test('returns null and sets createError on failure', () async {
      repo.throwOnCreate = true;
      final cls = await vm.createClass('Sitar');
      expect(cls, isNull);
      expect(vm.createError, isNotNull);
    });

    test('clearCreateError clears the error', () async {
      repo.throwOnCreate = true;
      await vm.createClass('Sitar');
      vm.clearCreateError();
      expect(vm.createError, isNull);
    });
  });

  group('InstrumentClassesViewModel.updateClass', () {
    late _FakeInstrumentRepository repo;
    late InstrumentClassesViewModel vm;

    setUp(() {
      repo = _FakeInstrumentRepository();
      vm = InstrumentClassesViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
      repo.dispose();
    });

    test('returns updated class on success', () async {
      // seed a class first
      await repo.createClass('Original');
      final updated = await vm.updateClass('id-Original', 'Renamed');
      expect(updated, isNotNull);
      expect(updated!.name, 'Renamed');
    });

    test('returns null and sets updateError on failure', () async {
      repo.throwOnUpdate = true;
      final updated = await vm.updateClass('id-X', 'Name');
      expect(updated, isNull);
      expect(vm.updateError, isNotNull);
    });

    test('clearUpdateError clears the error', () async {
      repo.throwOnUpdate = true;
      await vm.updateClass('id-X', 'Name');
      vm.clearUpdateError();
      expect(vm.updateError, isNull);
    });
  });

  group('InstrumentClassesViewModel.archiveClass', () {
    late _FakeInstrumentRepository repo;
    late InstrumentClassesViewModel vm;

    setUp(() {
      repo = _FakeInstrumentRepository();
      vm = InstrumentClassesViewModel(repo);
    });

    tearDown(() {
      vm.dispose();
      repo.dispose();
    });

    test('completes without setting archiveError on success', () async {
      await repo.createClass('Sitar');
      await vm.archiveClass('id-Sitar');
      expect(vm.archiveError, isNull);
    });

    test('sets archiveError on failure', () async {
      repo.throwOnArchive = true;
      await vm.archiveClass('id-X');
      expect(vm.archiveError, isNotNull);
    });

    test('clearArchiveError clears the error', () async {
      repo.throwOnArchive = true;
      await vm.archiveClass('id-X');
      vm.clearArchiveError();
      expect(vm.archiveError, isNull);
    });
  });
}
