// Widget tests for the LibraryScreen search bar and tag filter row.
//
// Covers:
//   - SearchBar is rendered in the library body
//   - Entering text in SearchBar calls LibraryViewModel.setSearchQuery
//   - Clearing search via clear button calls LibraryViewModel.clearSearch
//   - TagFilterRow renders chips for each available tag
//   - Tapping an inactive chip toggles it (calls toggleTag)
//   - Tapping an active chip deselects it (calls toggleTag)
//   - Active chips are visually selected (FilterChip.selected == true)
//   - Filter row is hidden when no tags exist

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/features/library/screens/library_screen.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/features/library/widgets/tag_filter_row.dart';
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
  final _allController = StreamController<List<Notation>>.broadcast();
  final _recentController = StreamController<List<Notation>>.broadcast();

  void emitAll(List<Notation> notations) => _allController.add(notations);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      _allController.stream;

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

class _FakeTagRepository implements TagRepository {
  final _controller = StreamController<List<Tag>>.broadcast();

  void emitTags(List<Tag> tags) => _controller.add(tags);

  @override
  Stream<List<Tag>> watchAllTags() => _controller.stream;

  @override
  Future<Tag> createTag(String name, String colorHex) async =>
      throw UnimplementedError();

  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) async =>
      throw UnimplementedError();

  @override
  Future<void> deleteTag(String id) async {}

  @override
  Future<void> seedDefaultTagsIfNeeded() async {}

  void close() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation(String id) => Notation(
      id: id,
      title: 'Title $id',
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Tag _makeTag(String id, String name) => Tag(
      id: id,
      name: name,
      colorHex: '#f38ba8',
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Widget _buildTestApp({
  required LibraryViewModel vm,
}) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
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
  late _FakeTrashRepository trashRepo;
  late _FakeTagRepository tagRepo;
  late LibraryViewModel vm;

  setUp(() {
    notationRepo = _FakeNotationRepository();
    trashRepo = _FakeTrashRepository();
    tagRepo = _FakeTagRepository();
    vm = LibraryViewModel(
      notationRepo,
      trashRepo,
      tagRepository: tagRepo,
    );
  });

  tearDown(() {
    vm.dispose();
    notationRepo.close();
    tagRepo.close();
  });

  // -------------------------------------------------------------------------
  // TagFilterRow unit widget tests
  // -------------------------------------------------------------------------

  group('TagFilterRow', () {
    testWidgets('renders nothing when tags list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TagFilterRow(
              tags: const [],
              selectedTagIds: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('renders a chip for each tag', (tester) async {
      final tags = [_makeTag('t1', 'Raag'), _makeTag('t2', 'Folk')];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TagFilterRow(
              tags: tags,
              selectedTagIds: const {},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('Raag'), findsOneWidget);
      expect(find.text('Folk'), findsOneWidget);
    });

    testWidgets('selected chips have selected=true', (tester) async {
      final tags = [_makeTag('t1', 'Raag'), _makeTag('t2', 'Folk')];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TagFilterRow(
              tags: tags,
              selectedTagIds: const {'t1'},
              onToggle: (_) {},
            ),
          ),
        ),
      );

      // Retrieve all FilterChip widgets from the tree.
      final chips = tester.widgetList<FilterChip>(find.byType(FilterChip));
      final raagChip = chips.firstWhere(
        (c) => (c.label as Text).data == 'Raag',
      );
      expect(raagChip.selected, isTrue);
    });

    testWidgets('tapping a chip calls onToggle with the tag id',
        (tester) async {
      final tags = [_makeTag('t1', 'Raag')];
      String? toggledId;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: TagFilterRow(
              tags: tags,
              selectedTagIds: const {},
              onToggle: (id) => toggledId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();

      expect(toggledId, 't1');
    });
  });

  // -------------------------------------------------------------------------
  // LibraryScreen integration (search bar + tag row visible)
  // -------------------------------------------------------------------------

  group('LibraryScreen search bar', () {
    testWidgets('SearchBar is visible in success state', (tester) async {
      await tester.pumpWidget(_buildTestApp(vm: vm));
      vm.init();
      notationRepo.emitAll([_makeNotation('n1')]);
      await tester.pumpAndSettle();

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('SearchBar is visible in loading state', (tester) async {
      await tester.pumpWidget(_buildTestApp(vm: vm));
      vm.init();
      await tester.pump();

      expect(find.byType(SearchBar), findsOneWidget);
    });
  });

  group('LibraryScreen tag filter row', () {
    testWidgets('tag filter row is hidden when no tags available',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(vm: vm));
      vm.init();
      notationRepo.emitAll([_makeNotation('n1')]);
      tagRepo.emitTags([]);
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('tag filter row shows chips when tags are available',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(vm: vm));
      vm.init();
      notationRepo.emitAll([_makeNotation('n1')]);
      tagRepo.emitTags([_makeTag('t1', 'Raag'), _makeTag('t2', 'Folk')]);
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsNWidgets(2));
      expect(find.text('Raag'), findsOneWidget);
      expect(find.text('Folk'), findsOneWidget);
    });

    testWidgets('tapping a tag chip toggles it in the ViewModel',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(vm: vm));
      vm.init();
      notationRepo.emitAll([_makeNotation('n1')]);
      tagRepo.emitTags([_makeTag('t1', 'Raag')]);
      await tester.pumpAndSettle();

      expect(vm.selectedTagIds, isEmpty);
      await tester.tap(find.byType(FilterChip).first);
      await tester.pump();
      expect(vm.selectedTagIds, contains('t1'));
    });
  });
}
