// Unit tests for TrashViewModel.
//
// Covers all public state transitions and methods:
//   init            → idle / loading / success / error
//   restoreNotation → success and error paths
//   purgeNotation   → success and error paths
//   purgeAll        → success and error paths
//
// Uses FakeTrashRepository to control stream and error scenarios.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/trash/viewmodels/trash_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fake
// ---------------------------------------------------------------------------

class FakeTrashRepository implements TrashRepository {
  final _controller = StreamController<List<Notation>>.broadcast();
  Object? _watchError;
  Object? _restoreError;
  Object? _purgeError;
  Object? _purgeAllError;
  final List<Notation> _notations = [];

  void emitNotations(List<Notation> notations) {
    _notations
      ..clear()
      ..addAll(notations);
    _controller.add(List.unmodifiable(_notations));
  }

  void emitWatchError(Object error) => _controller.addError(error);

  void setRestoreError(Object? e) => _restoreError = e;
  void setPurgeError(Object? e) => _purgeError = e;
  void setPurgeAllError(Object? e) => _purgeAllError = e;

  @override
  Stream<List<Notation>> watchTrashedNotations() {
    if (_watchError != null) return Stream.error(_watchError!);
    return _controller.stream;
  }

  @override
  Future<void> restoreNotation(String id) async {
    if (_restoreError != null) throw _restoreError!;
    _notations.removeWhere((n) => n.id == id);
    _controller.add(List.unmodifiable(_notations));
  }

  @override
  Future<void> purgeNotation(String id) async {
    if (_purgeError != null) throw _purgeError!;
    _notations.removeWhere((n) => n.id == id);
    _controller.add(List.unmodifiable(_notations));
  }

  @override
  Future<void> purgeAll() async {
    if (_purgeAllError != null) throw _purgeAllError!;
    _notations.clear();
    _controller.add(const []);
  }

  @override
  Future<int> autoPurgeExpired() async => 0;

  void close() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation({
  String id = 'n-1',
  String title = 'Yaman',
  String deletedAt = '2024-06-01T00:00:00.000Z',
}) =>
    Notation(
      id: id,
      title: title,
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
      deletedAt: deletedAt,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeTrashRepository repo;
  late TrashViewModel vm;

  setUp(() {
    repo = FakeTrashRepository();
    vm = TrashViewModel(repo);
  });

  tearDown(() {
    vm.dispose();
    repo.close();
  });

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('state is idle before init is called', () {
      expect(vm.state, isA<TrashStateIdle>());
    });
  });

  // -------------------------------------------------------------------------
  // init
  // -------------------------------------------------------------------------

  group('init', () {
    test('transitions to loading then success when stream emits', () async {
      final states = <TrashState>[];
      vm.addListener(() => states.add(vm.state));

      vm.init();
      expect(states.last, isA<TrashStateLoading>());

      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<TrashStateSuccess>());
      expect((vm.state as TrashStateSuccess).notations.length, 1);
    });

    test('transitions to error on stream error', () async {
      vm.init();
      repo.emitWatchError(Exception('DB failure'));
      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<TrashStateError>());
      expect((vm.state as TrashStateError).message, contains('DB failure'));
    });

    test('re-init cancels previous subscription', () async {
      vm.init();
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      vm.init(); // Second init
      repo.emitNotations([]);
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TrashStateSuccess).notations, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // restoreNotation
  // -------------------------------------------------------------------------

  group('restoreNotation', () {
    setUp(() {
      vm.init();
    });

    test('success — notation removed from stream list', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      await vm.restoreNotation('n-1');
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TrashStateSuccess).notations, isEmpty);
    });

    test('failure — sets operationError', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      repo.setRestoreError(Exception('restore failed'));
      await vm.restoreNotation('n-1');

      expect(vm.operationError, isNotNull);
    });

    test('clearOperationError resets the error', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      repo.setRestoreError(Exception('fail'));
      await vm.restoreNotation('n-1');
      expect(vm.operationError, isNotNull);

      vm.clearOperationError();
      expect(vm.operationError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // purgeNotation
  // -------------------------------------------------------------------------

  group('purgeNotation', () {
    setUp(() {
      vm.init();
    });

    test('success — notation removed from stream list', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      await vm.purgeNotation('n-1');
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TrashStateSuccess).notations, isEmpty);
    });

    test('failure — sets operationError', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      repo.setPurgeError(Exception('purge failed'));
      await vm.purgeNotation('n-1');

      expect(vm.operationError, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // purgeAll
  // -------------------------------------------------------------------------

  group('purgeAll', () {
    setUp(() {
      vm.init();
    });

    test('success — list becomes empty', () async {
      repo.emitNotations([
        _makeNotation(),
        _makeNotation(id: 'n-2', title: 'Bhairavi'),
      ]);
      await Future<void>.delayed(Duration.zero);

      await vm.purgeAll();
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TrashStateSuccess).notations, isEmpty);
    });

    test('failure — sets operationError', () async {
      repo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      repo.setPurgeAllError(Exception('purgeAll failed'));
      await vm.purgeAll();

      expect(vm.operationError, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose', () {
    test('cancels stream subscription on dispose', () async {
      final localRepo = FakeTrashRepository();
      final localVm = TrashViewModel(localRepo);

      localVm.init();
      localRepo.emitNotations([_makeNotation()]);
      await Future<void>.delayed(Duration.zero);

      localVm.dispose();
      expect(() => localRepo.emitNotations([]), returnsNormally);

      localRepo.close();
    });
  });
}
