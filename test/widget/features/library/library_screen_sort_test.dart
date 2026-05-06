// Widget tests for LibraryScreen sort controls, NotationCard rendering,
// and empty state.
//
// Covers:
//   - Sort icon button is present in the SliverAppBar actions
//   - Tapping the sort icon opens the sort bottom sheet
//   - Tapping a sort option in the bottom sheet calls LibraryViewModel.setSort
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
import 'package:swaralipi/features/library/widgets/sort_bottom_sheet.dart';
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
    testWidgets('sort icon button is present in the SliverAppBar',
        (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      // The sort button is an IconButton with Icons.sort_outlined.
      expect(
        find.widgetWithIcon(IconButton, Icons.sort_outlined),
        findsOneWidget,
      );
    });

    testWidgets('tapping sort icon opens sort bottom sheet', (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.sort_outlined));
      // Use pump with a short duration instead of pumpAndSettle — the
      // LibraryViewModel debounce timer keeps the frame loop active.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SortBottomSheet), findsOneWidget);
      expect(find.text('Sort by'), findsOneWidget);
    });

    testWidgets('sort bottom sheet shows all sort option labels',
        (tester) async {
      await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.sort_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Date written'), findsOneWidget);
      expect(find.text('Date added'), findsOneWidget);
      expect(find.text('Play count'), findsOneWidget);
      expect(find.text('Last played'), findsOneWidget);
    });
  });

  group('Sort control — interaction', () {
    testWidgets('tapping Title in sheet changes vm.sort to titleDesc',
        (tester) async {
      final vm = await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.sort_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('Title'));
      await tester.pump();

      // Default tap → desc direction.
      expect(vm.sort, LibrarySort.titleDesc);
    });

    testWidgets(
        're-tapping active sort group in sheet toggles direction to asc',
        (tester) async {
      final vm = await _pumpLibrary(
        tester,
        notationRepo: notationRepo,
        trashRepo: trashRepo,
      );

      // Open sheet, tap Title (→ titleDesc), then re-open, tap Title again (→ titleAsc).
      await tester.tap(find.widgetWithIcon(IconButton, Icons.sort_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Title'));
      await tester.pump();

      expect(vm.sort, LibrarySort.titleDesc);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.sort_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Title'));
      await tester.pump();

      expect(vm.sort, LibrarySort.titleAsc);
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
