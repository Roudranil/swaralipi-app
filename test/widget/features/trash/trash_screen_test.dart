// Widget tests for TrashScreen.
//
// Verifies the screen renders correctly for each TrashState variant and that
// user interactions (swipe-to-restore, purge button, Empty Trash action) call
// the correct ViewModel methods via FakeTrashViewModel.
//
// All tests use Provider-injected FakeTrashViewModel to avoid real DB access.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/trash/screens/trash_screen.dart';
import 'package:swaralipi/features/trash/viewmodels/trash_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository (unused stub — needed only for super constructor)
// ---------------------------------------------------------------------------

class _FakeTrashRepository implements TrashRepository {
  @override
  Stream<List<Notation>> watchTrashedNotations() => const Stream.empty();
  @override
  Future<void> restoreNotation(String id) async {}
  @override
  Future<void> purgeNotation(String id) async {}
  @override
  Future<void> purgeAll() async {}
  @override
  Future<int> autoPurgeExpired() async => 0;
}

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class FakeTrashViewModel extends TrashViewModel {
  FakeTrashViewModel({TrashState initialState = const TrashStateIdle()})
      : super(_FakeTrashRepository()) {
    _state = initialState;
  }

  TrashState _state = const TrashStateIdle();
  String? _operationError;

  bool initCalled = false;
  String? lastRestoredId;
  String? lastPurgedId;
  bool purgeAllCalled = false;

  @override
  TrashState get state => _state;

  @override
  String? get operationError => _operationError;

  void setState(TrashState s) {
    _state = s;
    notifyListeners();
  }

  void setOperationError(String? error) {
    _operationError = error;
    notifyListeners();
  }

  @override
  void init() {
    initCalled = true;
  }

  @override
  Future<void> restoreNotation(String id) async {
    lastRestoredId = id;
  }

  @override
  Future<void> purgeNotation(String id) async {
    lastPurgedId = id;
  }

  @override
  Future<void> purgeAll() async {
    purgeAllCalled = true;
  }

  @override
  void clearOperationError() {
    _operationError = null;
    notifyListeners();
  }
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

Widget _buildScreen(FakeTrashViewModel vm) {
  return MaterialApp(
    home: ChangeNotifierProvider<TrashViewModel>.value(
      value: vm,
      child: const TrashScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Rendering
  // -------------------------------------------------------------------------

  group('rendering', () {
    testWidgets('shows loading indicator in loading state', (tester) async {
      final vm = FakeTrashViewModel(initialState: const TrashStateLoading());
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state when notation list is empty',
        (tester) async {
      final vm = FakeTrashViewModel(
        initialState: const TrashStateSuccess(notations: []),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.text('Trash is empty'), findsOneWidget);
    });

    testWidgets('shows error view on TrashStateError', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: const TrashStateError(message: 'DB failed'),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.text('Failed to load trash'), findsOneWidget);
      expect(find.textContaining('DB failed'), findsOneWidget);
    });

    testWidgets('shows notation list in success state', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(
          notations: [
            _makeNotation(id: 'n-1', title: 'Yaman'),
            _makeNotation(id: 'n-2', title: 'Bhairavi'),
          ],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.text('Yaman'), findsOneWidget);
      expect(find.text('Bhairavi'), findsOneWidget);
    });

    testWidgets('shows Empty Trash action when list is non-empty',
        (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation()]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('hides Empty Trash action when list is empty', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: const TrashStateSuccess(notations: []),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(find.text('Empty'), findsNothing);
    });

    testWidgets('calls init on first frame', (tester) async {
      final vm = FakeTrashViewModel();
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      expect(vm.initCalled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Swipe-to-restore
  // -------------------------------------------------------------------------

  group('swipe-to-restore', () {
    testWidgets('swiping right calls restoreNotation', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation(id: 'n-1')]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.drag(find.text('Yaman'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(vm.lastRestoredId, 'n-1');
    });
  });

  // -------------------------------------------------------------------------
  // Permanent delete
  // -------------------------------------------------------------------------

  group('permanent delete', () {
    testWidgets('tapping delete icon shows confirmation dialog',
        (tester) async {
      final vm = FakeTrashViewModel(
        initialState:
            TrashStateSuccess(notations: [_makeNotation(title: 'Yaman')]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Delete permanently?'), findsOneWidget);
    });

    testWidgets('confirming delete calls purgeNotation', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation(id: 'n-1')]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(vm.lastPurgedId, 'n-1');
    });

    testWidgets('cancelling delete does not call purgeNotation',
        (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation()]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(vm.lastPurgedId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Empty Trash
  // -------------------------------------------------------------------------

  group('empty trash', () {
    testWidgets('tapping Empty shows confirmation dialog', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation()]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();

      expect(find.text('Empty Trash?'), findsOneWidget);
    });

    testWidgets('confirming empty trash calls purgeAll', (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation()]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Empty Trash'));
      await tester.pumpAndSettle();

      expect(vm.purgeAllCalled, isTrue);
    });

    testWidgets('cancelling empty trash does not call purgeAll',
        (tester) async {
      final vm = FakeTrashViewModel(
        initialState: TrashStateSuccess(notations: [_makeNotation()]),
      );
      await tester.pumpWidget(_buildScreen(vm));
      await tester.pump();

      await tester.tap(find.text('Empty'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(vm.purgeAllCalled, isFalse);
    });
  });
}
