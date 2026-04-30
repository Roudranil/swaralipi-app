// Unit tests for LibraryViewModel.
//
// Covers all public state transitions and soft-delete lifecycle:
//   init            → idle / loading / success / error
//   softDelete      → success path and error path
//   undoDelete      → calls TrashRepository.restoreNotation
//
// Uses FakeNotationRepository and FakeTrashRepository to control stream and
// error scenarios without touching the database.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  final _controller = StreamController<List<Notation>>.broadcast();
  Object? _softDeleteError;

  final List<String> softDeletedIds = [];

  void emitNotations(List<Notation> notations) => _controller.add(notations);

  void emitWatchError(Object error) => _controller.addError(error);

  void setSoftDeleteError(Object? e) => _softDeleteError = e;

  @override
  Stream<List<Notation>> watchAllActive() => _controller.stream;

  @override
  Future<void> softDelete(String id) async {
    if (_softDeleteError != null) throw _softDeleteError!;
    softDeletedIds.add(id);
  }

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) async =>
      throw UnimplementedError();

  @override
  Future<NotationDetail?> loadNotation(String id) async =>
      throw UnimplementedError();

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}

  void close() => _controller.close();
}

class FakeTrashRepository implements TrashRepository {
  final List<String> restoredIds = [];
  Object? _restoreError;

  void setRestoreError(Object? e) => _restoreError = e;

  @override
  Future<void> restoreNotation(String id) async {
    if (_restoreError != null) throw _restoreError!;
    restoredIds.add(id);
  }

  @override
  Stream<List<Notation>> watchTrashedNotations() => const Stream.empty();

  @override
  Future<void> purgeNotation(String id) async {}

  @override
  Future<void> purgeAll() async {}

  @override
  Future<int> autoPurgeExpired() async => 0;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation(String id) => Notation(
      id: id,
      title: 'Test $id',
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository notationRepo;
  late FakeTrashRepository trashRepo;
  late LibraryViewModel vm;

  setUp(() {
    notationRepo = FakeNotationRepository();
    trashRepo = FakeTrashRepository();
    vm = LibraryViewModel(notationRepo, trashRepo);
  });

  tearDown(() {
    vm.dispose();
    notationRepo.close();
  });

  group('initial state', () {
    test('starts in idle state', () {
      expect(vm.state, isA<LibraryStateIdle>());
    });
  });

  group('init', () {
    test('transitions to loading immediately', () {
      vm.init();
      expect(vm.state, isA<LibraryStateLoading>());
    });

    test('transitions to success when stream emits notations', () async {
      final notations = [_makeNotation('1'), _makeNotation('2')];
      vm.init();

      notationRepo.emitNotations(notations);
      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<LibraryStateSuccess>());
      final success = vm.state as LibraryStateSuccess;
      expect(success.notations, hasLength(2));
      expect(success.notations.first.id, '1');
    });

    test('transitions to success with empty list', () async {
      vm.init();
      notationRepo.emitNotations([]);
      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<LibraryStateSuccess>());
      expect((vm.state as LibraryStateSuccess).notations, isEmpty);
    });

    test('transitions to error when stream emits error', () async {
      vm.init();
      notationRepo.emitWatchError(Exception('db failure'));
      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<LibraryStateError>());
      final error = vm.state as LibraryStateError;
      expect(error.message, contains('db failure'));
    });

    test('notifies listeners on each emission', () async {
      var callCount = 0;
      vm.addListener(() => callCount++);

      vm.init();
      expect(callCount, 1); // loading

      notationRepo.emitNotations([_makeNotation('1')]);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 2); // success

      notationRepo.emitNotations([_makeNotation('2')]);
      await Future<void>.delayed(Duration.zero);
      expect(callCount, 3); // updated success
    });

    test('re-calling init cancels previous subscription', () async {
      vm.init();
      notationRepo.emitNotations([_makeNotation('1')]);
      await Future<void>.delayed(Duration.zero);

      vm.init(); // re-init should reset to loading
      expect(vm.state, isA<LibraryStateLoading>());
    });
  });

  group('softDelete', () {
    setUp(() async {
      vm.init();
      notationRepo.emitNotations([_makeNotation('a'), _makeNotation('b')]);
      await Future<void>.delayed(Duration.zero);
    });

    test('calls NotationRepository.softDelete with correct id', () async {
      await vm.softDelete('a');
      expect(notationRepo.softDeletedIds, contains('a'));
    });

    test('clears operationError on success', () async {
      await vm.softDelete('a');
      expect(vm.operationError, isNull);
    });

    test('sets operationError on failure', () async {
      notationRepo.setSoftDeleteError(Exception('delete error'));
      await vm.softDelete('a');
      expect(vm.operationError, isNotNull);
      expect(vm.operationError, contains('delete error'));
    });

    test('notifies listeners on error', () async {
      var callCount = 0;
      vm.addListener(() => callCount++);
      notationRepo.setSoftDeleteError(Exception('err'));
      await vm.softDelete('a');
      expect(callCount, greaterThan(0));
    });
  });

  group('undoDelete', () {
    test('calls TrashRepository.restoreNotation with correct id', () async {
      await vm.undoDelete('a');
      expect(trashRepo.restoredIds, contains('a'));
    });

    test('sets operationError when restore fails', () async {
      trashRepo.setRestoreError(Exception('restore failed'));
      await vm.undoDelete('a');
      expect(vm.operationError, isNotNull);
      expect(vm.operationError, contains('restore failed'));
    });
  });

  group('clearOperationError', () {
    test('clears operationError and notifies listeners', () async {
      notationRepo.setSoftDeleteError(Exception('err'));
      await vm.softDelete('a');
      expect(vm.operationError, isNotNull);

      var callCount = 0;
      vm.addListener(() => callCount++);
      vm.clearOperationError();

      expect(vm.operationError, isNull);
      expect(callCount, 1);
    });
  });
}
