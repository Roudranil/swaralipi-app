// Unit tests for NotationDetailViewModel.
//
// Covers all public state transitions and operations:
//   loadNotation    → loading / success / error / not-found
//   softDelete      → success path, error path, navigation callback
//   undoDelete      → calls TrashRepository.restoreNotation
//
// Uses FakeNotationRepository and FakeTrashRepository without touching
// the database.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/notation_detail/viewmodels/notation_detail_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  NotationDetail? _detail;
  Object? _loadError;
  Object? _softDeleteError;

  final List<String> softDeletedIds = [];

  void setDetail(NotationDetail? d) => _detail = d;
  void setLoadError(Object? e) => _loadError = e;
  void setSoftDeleteError(Object? e) => _softDeleteError = e;

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    if (_loadError != null) throw _loadError!;
    return _detail;
  }

  @override
  Future<void> softDelete(String id) async {
    if (_softDeleteError != null) throw _softDeleteError!;
    softDeletedIds.add(id);
  }

  @override
  Stream<List<Notation>> watchAllActive() => const Stream.empty();

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
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}
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

NotationDetail _makeDetail(String id) => NotationDetail(
      notation: _makeNotation(id),
      pages: const <NotationPage>[],
      tags: const <Tag>[],
      customFieldValues: const <CustomFieldValue>[],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository notationRepo;
  late FakeTrashRepository trashRepo;
  late NotationDetailViewModel vm;

  setUp(() {
    notationRepo = FakeNotationRepository();
    trashRepo = FakeTrashRepository();
    vm = NotationDetailViewModel(notationRepo, trashRepo);
  });

  tearDown(() => vm.dispose());

  group('initial state', () {
    test('starts in idle state', () {
      expect(vm.state, isA<NotationDetailStateIdle>());
    });
  });

  group('loadNotation', () {
    test('transitions to loading then success when notation is found',
        () async {
      final detail = _makeDetail('x');
      notationRepo.setDetail(detail);

      final states = <NotationDetailState>[];
      vm.addListener(() => states.add(vm.state));

      await vm.loadNotation('x');

      expect(states.first, isA<NotationDetailStateLoading>());
      expect(states.last, isA<NotationDetailStateSuccess>());
      final success = states.last as NotationDetailStateSuccess;
      expect(success.detail.notation.id, 'x');
    });

    test('transitions to notFound when notation is null', () async {
      notationRepo.setDetail(null);
      await vm.loadNotation('missing');
      expect(vm.state, isA<NotationDetailStateNotFound>());
    });

    test('transitions to error when repository throws', () async {
      notationRepo.setLoadError(Exception('load error'));
      await vm.loadNotation('x');
      expect(vm.state, isA<NotationDetailStateError>());
      final error = vm.state as NotationDetailStateError;
      expect(error.message, contains('load error'));
    });
  });

  group('softDelete', () {
    setUp(() async {
      notationRepo.setDetail(_makeDetail('n1'));
      await vm.loadNotation('n1');
    });

    test('calls NotationRepository.softDelete with correct id', () async {
      await vm.softDelete('n1');
      expect(notationRepo.softDeletedIds, contains('n1'));
    });

    test('clears operationError on success', () async {
      await vm.softDelete('n1');
      expect(vm.operationError, isNull);
    });

    test('sets operationError on failure', () async {
      notationRepo.setSoftDeleteError(Exception('delete failed'));
      await vm.softDelete('n1');
      expect(vm.operationError, isNotNull);
      expect(vm.operationError, contains('delete failed'));
    });

    test('invokes onDeleted callback on success', () async {
      var callbackInvoked = false;
      await vm.softDelete('n1', onDeleted: () => callbackInvoked = true);
      expect(callbackInvoked, isTrue);
    });

    test('does not invoke onDeleted callback on failure', () async {
      notationRepo.setSoftDeleteError(Exception('err'));
      var callbackInvoked = false;
      await vm.softDelete('n1', onDeleted: () => callbackInvoked = true);
      expect(callbackInvoked, isFalse);
    });
  });

  group('undoDelete', () {
    test('calls TrashRepository.restoreNotation with correct id', () async {
      await vm.undoDelete('n1');
      expect(trashRepo.restoredIds, contains('n1'));
    });

    test('sets operationError when restore fails', () async {
      trashRepo.setRestoreError(Exception('restore failed'));
      await vm.undoDelete('n1');
      expect(vm.operationError, isNotNull);
      expect(vm.operationError, contains('restore failed'));
    });
  });

  group('clearOperationError', () {
    test('clears operationError and notifies', () async {
      notationRepo.setSoftDeleteError(Exception('err'));
      await vm.softDelete('n1');
      expect(vm.operationError, isNotNull);

      var called = false;
      vm.addListener(() => called = true);
      vm.clearOperationError();

      expect(vm.operationError, isNull);
      expect(called, isTrue);
    });
  });
}
