// Widget tests for LibraryScreen sort controls, NotationCard rendering,
// and empty state.
//
// Covers:
//   - Sort SegmentedButton is present in the AppBar
//   - Tapping a sort segment calls LibraryViewModel.setSort
//   - Empty state widget is shown when notation list is empty
//   - NotationCard is rendered for each notation in success state
//   - NotationCard shows title and artists
//   - NotationCard shows date written when non-null
//   - Tapping NotationCard calls onNotationTap

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/features/library/screens/library_screen.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/features/library/widgets/notation_card.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeNotationRepository implements NotationRepository {
  final _allController = StreamController<List<Notation>>.broadcast();
  final _recentController = StreamController<List<Notation>>.broadcast();
  final List<NotationSortBy> receivedSortArgs = [];

  void emitAll(List<Notation> notations) => _allController.add(notations);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) {
    receivedSortArgs.add(sortBy);
    return _allController.stream;
  }

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      _recentController.stream;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) =>
      throw UnimplementedError();

  @override
  Future<NotationDetail?> loadNotation(String id) async => null;

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}

  void close() {
    _allController.close();
    _recentController.close();
  }
}

class _FakeTrashRepository implements TrashRepository {
  @override
  Future<void> restoreNotation(String id) async {}

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

Notation _makeNotation(
  String id, {
  String title = 'Notation',
  List<String> artists = const [],
  String? dateWritten,
}) =>
    Notation(
      id: id,
      title: title,
      artists: artists,
      languages: const [],
      notes: '',
      playCount: 0,
      dateWritten: dateWritten,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

/// Pumps a [LibraryScreen] wrapped in [ChangeNotifierProvider] and
/// [MaterialApp]. Returns the [LibraryViewModel] for inspection.
Future<LibraryViewModel> _pumpLibrary(
  WidgetTester tester, {
  ValueChanged<String>? onNotationTap,
  required _FakeNotationRepository notationRepo,
  required _FakeTrashRepository trashRepo,
}) async {
  final vm = LibraryViewModel(notationRepo, trashRepo);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<LibraryViewModel>.value(
        value: vm,
        child: LibraryScreen(onNotationTap: onNotationTap),
      ),
    ),
  );
  await tester.pump(); // allow postFrameCallback init()

  return vm;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeNotationRepository notationRepo;
  late _FakeTrashRepository trashRepo;

  setUp(() {
    notationRepo = _FakeNotationRepository();
    trashRepo = _FakeTrashRepository();
  });

  tearDown(() {
    notationRepo.close();
  });

  // -------------------------------------------------------------------------
  // Sort control
  // -------------------------------------------------------------------------

  group('Sort control — presence', () {
    testWidgets('SegmentedButton is present in the AppBar', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      expect(find.byType(SegmentedButton<LibrarySort>), findsOneWidget);
    });

    testWidgets('all three sort segments are shown', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Artist'), findsOneWidget);
    });
  });

  group('Sort control — interaction', () {
    testWidgets('tapping Title segment changes vm.sort to titleAsc',
        (tester) async {
      final vm = await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      await tester.tap(find.text('Title'));
      await tester.pump();

      expect(vm.sort, LibrarySort.titleAsc);
    });

    testWidgets('tapping Artist segment changes vm.sort to artistAsc',
        (tester) async {
      final vm = await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      await tester.tap(find.text('Artist'));
      await tester.pump();

      expect(vm.sort, LibrarySort.artistAsc);
    });

    testWidgets('re-tapping the active segment is a no-op', (tester) async {
      final vm = await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      final callsBefore = notationRepo.receivedSortArgs.length;
      await tester.tap(find.text('Date')); // already selected
      await tester.pump();

      // sort unchanged, no extra subscription
      expect(vm.sort, LibrarySort.dateDesc);
      expect(notationRepo.receivedSortArgs.length, callsBefore);
    });
  });

  // -------------------------------------------------------------------------
  // Empty state
  // -------------------------------------------------------------------------

  group('Empty state', () {
    testWidgets('shows empty-state view when notation list is empty',
        (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([]);
      await tester.pumpAndSettle();

      expect(find.text('No notations yet'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // NotationCard rendering
  // -------------------------------------------------------------------------

  group('NotationCard rendering', () {
    testWidgets('renders a NotationCard for each notation', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([
        _makeNotation('1', title: 'Bhairavi'),
        _makeNotation('2', title: 'Yaman'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byType(NotationCard), findsNWidgets(2));
    });

    testWidgets('NotationCard shows notation title', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([
        _makeNotation('1', title: 'Keherwa'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Keherwa'), findsOneWidget);
    });

    testWidgets('NotationCard shows artist names', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([
        _makeNotation('1', title: 'Raga', artists: ['Ravi Shankar']),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Ravi Shankar'), findsOneWidget);
    });

    testWidgets('NotationCard shows dateWritten when non-null', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([
        _makeNotation('1', title: 'Bhairav', dateWritten: '2023-05-12'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('2023-05-12'), findsOneWidget);
    });

    testWidgets('NotationCard does not show date row when dateWritten is null',
        (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([
        _makeNotation('1', title: 'Bhairav'),
      ]);
      await tester.pumpAndSettle();

      // The date text should not appear anywhere.
      expect(find.textContaining(RegExp(r'\d{4}-\d{2}-\d{2}')), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Tap interaction
  // -------------------------------------------------------------------------

  group('Tap interaction', () {
    testWidgets('tapping NotationCard calls onNotationTap with id',
        (tester) async {
      final tapped = <String>[];
      await _pumpLibrary(
        tester,
        onNotationTap: tapped.add,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      notationRepo.emitAll([_makeNotation('abc-123', title: 'Tappa')]);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NotationCard));
      await tester.pump();

      expect(tapped, ['abc-123']);
    });
  });
}
