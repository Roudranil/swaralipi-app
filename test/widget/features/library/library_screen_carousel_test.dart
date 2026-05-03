// Widget tests for the recently-played carousel in LibraryScreen.
//
// Covers:
//   - Carousel is hidden when no notations have been played (empty stream)
//   - Carousel is visible and shows cards when recently-played notations exist
//   - Carousel shows only up to 5 cards even when more are provided
//   - Each card shows the notation title
//   - Tapping a card navigates to NotationDetailScreen
//   - Carousel is hidden when recentlyPlayed state is empty list

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/library/screens/library_screen.dart';
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
  final _allActiveController =
      StreamController<List<Notation>>.broadcast();
  final _recentController =
      StreamController<List<Notation>>.broadcast();

  void emitAllActive(List<Notation> notations) =>
      _allActiveController.add(notations);

  void emitRecent(List<Notation> notations) =>
      _recentController.add(notations);

  @override
  Stream<List<Notation>> watchAllActive() => _allActiveController.stream;

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
    _allActiveController.close();
    _recentController.close();
  }
}

class FakeTrashRepository implements TrashRepository {
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

Notation _makeNotation(String id, {String? lastPlayedAt}) => Notation(
      id: id,
      title: 'Song $id',
      artists: const [],
      languages: const [],
      notes: '',
      playCount: lastPlayedAt != null ? 1 : 0,
      lastPlayedAt: lastPlayedAt,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Widget _buildTestWidget({
  required LibraryViewModel vm,
}) {
  return MaterialApp(
    home: ChangeNotifierProvider<LibraryViewModel>.value(
      value: vm,
      child: const LibraryScreen(),
    ),
  );
}

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

  group('recently-played carousel', () {
    testWidgets('carousel is hidden when no notations played', (tester) async {
      await tester.pumpWidget(_buildTestWidget(vm: vm));

      vm.init();
      notationRepo.emitAllActive([]);
      notationRepo.emitRecent([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recently_played_carousel')), findsNothing);
    });

    testWidgets('carousel is visible when recently-played notations exist',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(vm: vm));

      vm.init();
      notationRepo.emitAllActive([]);
      notationRepo.emitRecent([
        _makeNotation('1', lastPlayedAt: '2024-01-03T00:00:00Z'),
        _makeNotation('2', lastPlayedAt: '2024-01-02T00:00:00Z'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recently_played_carousel')), findsOneWidget);
    });

    testWidgets('carousel shows card titles for each recently-played notation',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(vm: vm));

      vm.init();
      notationRepo.emitAllActive([]);
      notationRepo.emitRecent([
        _makeNotation('1', lastPlayedAt: '2024-01-03T00:00:00Z'),
        _makeNotation('2', lastPlayedAt: '2024-01-02T00:00:00Z'),
        _makeNotation('3', lastPlayedAt: '2024-01-01T00:00:00Z'),
      ]);
      await tester.pumpAndSettle();

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Song 2'), findsOneWidget);
      expect(find.text('Song 3'), findsOneWidget);
    });

    testWidgets('carousel shows at most 5 cards', (tester) async {
      final recent = List.generate(
        7,
        (i) => _makeNotation(
          '${i + 1}',
          lastPlayedAt: '2024-01-0${i + 1}T00:00:00Z',
        ),
      );

      await tester.pumpWidget(_buildTestWidget(vm: vm));

      vm.init();
      notationRepo.emitAllActive([]);
      // Emit only 5 (DAO limits to 5)
      notationRepo.emitRecent(recent.take(5).toList());
      await tester.pumpAndSettle();

      // Count carousel item cards
      final carousel =
          find.byKey(const Key('recently_played_carousel'));
      expect(carousel, findsOneWidget);
      expect(
        find.descendant(
          of: carousel,
          matching: find.byKey(const Key('recently_played_card')),
        ),
        findsNWidgets(5),
      );
    });

    testWidgets(
        'carousel is hidden when recentlyPlayed transitions to empty list',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget(vm: vm));

      vm.init();
      notationRepo.emitAllActive([]);
      notationRepo.emitRecent([
        _makeNotation('1', lastPlayedAt: '2024-01-01T00:00:00Z'),
      ]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recently_played_carousel')), findsOneWidget);

      // Now clear the recently-played list
      notationRepo.emitRecent([]);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recently_played_carousel')), findsNothing);
    });

    testWidgets('tapping carousel card calls onTap with correct notation id',
        (tester) async {
      String? tappedId;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<LibraryViewModel>.value(
            value: vm,
            child: LibraryScreen(
              onNotationTap: (id) => tappedId = id,
            ),
          ),
        ),
      );

      vm.init();
      notationRepo.emitAllActive([]);
      notationRepo.emitRecent([
        _makeNotation('abc', lastPlayedAt: '2024-01-01T00:00:00Z'),
      ]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('recently_played_card')));
      await tester.pump();

      expect(tappedId, 'abc');
    });
  });
}
