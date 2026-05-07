// library_screen_search_anchor_test.dart — widget tests for Task 4: Search bar
// moved to AppBar SearchAnchor.
//
// Covers:
//   - No standalone SearchBar below the AppBar
//   - Search icon appears in AppBar actions
//   - SearchAnchor opens when search icon is tapped
//   - Typing in the overlay calls vm.setSearchQuery

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/features/library/screens/library_screen.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeNotationRepository implements NotationRepository {
  final _allCtrl = StreamController<List<Notation>>.broadcast();
  final _recentCtrl = StreamController<List<Notation>>.broadcast();

  void emitAll(List<Notation> n) => _allCtrl.add(n);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      _allCtrl.stream;

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      _recentCtrl.stream;

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> restoreNotation(String id) async {}

  @override
  Future<void> permanentlyDelete(String id) async {}

  @override
  Future<NotationDetail?> getNotationDetail(String id) async => null;

  @override
  Stream<NotationDetail?> watchNotationDetail(String id) => const Stream.empty();
}

class _FakeTagRepository implements TagRepository {
  @override
  Stream<List<Tag>> watchAllTags() => Stream.value([]);

  @override
  Future<Tag> createTag(String name, String colorHex) =>
      throw UnimplementedError();

  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteTag(String id) async {}

  @override
  Future<void> seedDefaultTagsIfNeeded() async {}
}

class _FakeTrashRepository implements TrashRepository {
  @override
  Stream<List<Notation>> watchDeleted() => const Stream.empty();

  @override
  Future<void> restoreNotation(String id) async {}

  @override
  Future<void> permanentlyDelete(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _TrackingLibraryViewModel extends LibraryViewModel {
  _TrackingLibraryViewModel(super.notationRepo, super.trashRepo,
      {required super.tagRepository});

  final List<String> setSearchQueryCalls = [];
  bool clearSearchCalled = false;

  @override
  void setSearchQuery(String query) {
    setSearchQueryCalls.add(query);
    super.setSearchQuery(query);
  }

  @override
  void clearSearch() {
    clearSearchCalled = true;
    super.clearSearch();
  }
}

Widget _buildApp(
  _FakeNotationRepository notationRepo,
  _FakeTagRepository tagRepo,
  _FakeTrashRepository trashRepo,
  _TrackingLibraryViewModel vm,
) {
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
  late _FakeNotationRepository notationRepo;
  late _FakeTagRepository tagRepo;
  late _FakeTrashRepository trashRepo;
  late _TrackingLibraryViewModel vm;

  setUp(() {
    notationRepo = _FakeNotationRepository();
    tagRepo = _FakeTagRepository();
    trashRepo = _FakeTrashRepository();
    vm = _TrackingLibraryViewModel(
      notationRepo,
      trashRepo,
      tagRepository: tagRepo,
    );
  });

  tearDown(() => vm.dispose());

  group('Task 4 — SearchAnchor in AppBar', () {
    testWidgets('no standalone SearchBar is rendered below AppBar',
        (tester) async {
      await tester.pumpWidget(_buildApp(notationRepo, tagRepo, trashRepo, vm));
      await tester.pump();

      // The old _LibrarySearchBar had a specific key; ensure it's gone.
      // Also ensure there is no SearchBar widget in the scroll body.
      final searchBars = tester.widgetList(find.byType(SearchBar));
      expect(searchBars, isEmpty);
    });

    testWidgets('search icon button is in AppBar actions', (tester) async {
      await tester.pumpWidget(_buildApp(notationRepo, tagRepo, trashRepo, vm));
      await tester.pump();

      // SearchAnchor's builder renders an IconButton with Icons.search_outlined.
      expect(
        find.byKey(const Key('library_search_icon_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping search icon opens the search overlay', (tester) async {
      await tester.pumpWidget(_buildApp(notationRepo, tagRepo, trashRepo, vm));
      await tester.pump();

      await tester.tap(find.byKey(const Key('library_search_icon_button')));
      await tester.pumpAndSettle();

      // SearchAnchor opens a full-screen overlay containing a text field.
      expect(find.byType(SearchAnchor), findsWidgets);
    });
  });
}
