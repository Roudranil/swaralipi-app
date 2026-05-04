// Unit tests for LibraryViewModel search and tag-filter behaviour.
//
// Covers:
//   - searchQuery: initial value is empty
//   - setSearchQuery: updates query and notifies listeners
//   - searchResults reflects filtered notations from SearchService
//   - debounce: search is debounced 300 ms (uses fake_async)
//   - clearSearch: resets query to empty and returns full list
//   - tag filter: initial selectedTagIds is empty
//   - toggleTag: adds/removes a tag id and notifies listeners
//   - clearTagFilter: resets to empty set
//   - composition: search + tag filter compose (search first, then tag filter)
//   - tags stream emits available tags from TagRepository
//
// Uses FakeNotationRepository, FakeTagRepository, FakeSearchService, and
// FakeNotationTagDao to control behaviour without touching the database.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/daos/notation_dao.dart';
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
  final _allActiveController = StreamController<List<Notation>>.broadcast();
  final _recentController = StreamController<List<Notation>>.broadcast();

  void emitAll(List<Notation> notations) => _allActiveController.add(notations);

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      _allActiveController.stream;

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
    _allActiveController.close();
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

/// Fake that returns IDs matching a set of mock query-to-id mappings.
class _FakeSearchService implements LibrarySearchService {
  /// Map of query → notation IDs to return.
  final Map<String, List<String>> _results;

  const _FakeSearchService(this._results);

  @override
  Future<List<String>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async =>
      _results[query] ?? const [];
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

/// Fake that maps notationId → Set<tagId> for client-side filtering.
class _FakeNotationTagService {
  final Map<String, Set<String>> _notationTagIds;

  const _FakeNotationTagService(this._notationTagIds);

  /// Returns the tag IDs for a given notation.
  Set<String> tagsForNotation(String notationId) =>
      _notationTagIds[notationId] ?? const {};
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation(String id, {String title = ''}) => Notation(
      id: id,
      title: title.isEmpty ? 'Test $id' : title,
      artists: const [],
      languages: const [],
      notes: '',
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Tag _makeTag(String id, {String name = ''}) => Tag(
      id: id,
      name: name.isEmpty ? 'Tag $id' : name,
      colorHex: '#f38ba8',
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeNotationRepository notationRepo;
  late _FakeTrashRepository trashRepo;
  late _FakeTagRepository tagRepo;
  late LibraryViewModel vm;

  final n1 = _makeNotation('n1', title: 'Bhairav');
  final n2 = _makeNotation('n2', title: 'Yaman');
  final n3 = _makeNotation('n3', title: 'Darbari');

  final tag1 = _makeTag('t1', name: 'Raag');
  final tag2 = _makeTag('t2', name: 'Folk');

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
  // Search query state
  // -------------------------------------------------------------------------

  group('searchQuery initial state', () {
    test('starts empty', () {
      expect(vm.searchQuery, isEmpty);
    });
  });

  group('setSearchQuery', () {
    setUp(() async {
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);
    });

    test('updates searchQuery', () {
      vm.setSearchQuery('Bhai');
      expect(vm.searchQuery, 'Bhai');
    });

    test('notifies listeners when query changes', () {
      var count = 0;
      vm.addListener(() => count++);
      vm.setSearchQuery('x');
      expect(count, greaterThan(0));
    });

    test('setting the same query twice is a no-op', () {
      vm.setSearchQuery('abc');
      var count = 0;
      vm.addListener(() => count++);
      vm.setSearchQuery('abc');
      expect(count, 0);
    });
  });

  group('clearSearch', () {
    setUp(() async {
      vm.init();
      notationRepo.emitAll([n1, n2]);
      await Future<void>.delayed(Duration.zero);
    });

    test('resets searchQuery to empty', () async {
      vm.setSearchQuery('Bhai');
      vm.clearSearch();
      expect(vm.searchQuery, isEmpty);
    });

    test('notifies listeners', () {
      vm.setSearchQuery('Bhai');
      var count = 0;
      vm.addListener(() => count++);
      vm.clearSearch();
      expect(count, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // Tag filter state
  // -------------------------------------------------------------------------

  group('selectedTagIds initial state', () {
    test('starts empty', () {
      expect(vm.selectedTagIds, isEmpty);
    });
  });

  group('toggleTag', () {
    setUp(() async {
      vm.init();
      notationRepo.emitAll([n1, n2]);
      await Future<void>.delayed(Duration.zero);
    });

    test('adds a tag id when not already selected', () {
      vm.toggleTag('t1');
      expect(vm.selectedTagIds, contains('t1'));
    });

    test('removes a tag id when already selected', () {
      vm.toggleTag('t1');
      vm.toggleTag('t1');
      expect(vm.selectedTagIds, isNot(contains('t1')));
    });

    test('notifies listeners on toggle', () {
      var count = 0;
      vm.addListener(() => count++);
      vm.toggleTag('t1');
      expect(count, greaterThan(0));
    });

    test('supports multiple tags selected simultaneously', () {
      vm.toggleTag('t1');
      vm.toggleTag('t2');
      expect(vm.selectedTagIds, containsAll(['t1', 't2']));
    });
  });

  group('clearTagFilter', () {
    setUp(() async {
      vm.init();
      notationRepo.emitAll([n1]);
      await Future<void>.delayed(Duration.zero);
    });

    test('resets selectedTagIds to empty', () {
      vm.toggleTag('t1');
      vm.toggleTag('t2');
      vm.clearTagFilter();
      expect(vm.selectedTagIds, isEmpty);
    });

    test('notifies listeners', () {
      vm.toggleTag('t1');
      var count = 0;
      vm.addListener(() => count++);
      vm.clearTagFilter();
      expect(count, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // Search filtering (no tag filter)
  // -------------------------------------------------------------------------

  group('displayedNotations with search only', () {
    setUp(() async {
      vm = LibraryViewModel(
        notationRepo,
        trashRepo,
        tagRepository: tagRepo,
        searchService: _FakeSearchService({
          'Bhai': ['n1'],
          'Yam': ['n2'],
        }),
      );
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);
    });

    test('returns all notations when query is empty', () async {
      final displayed = await vm.displayedNotations;
      expect(displayed.map((n) => n.id), containsAll(['n1', 'n2', 'n3']));
    });

    test('returns filtered notations when query matches', () async {
      vm.setSearchQuery('Bhai');
      // Allow debounce to fire.
      await Future<void>.delayed(
        const Duration(milliseconds: 350),
      );
      final displayed = await vm.displayedNotations;
      expect(displayed.map((n) => n.id), contains('n1'));
      expect(displayed.map((n) => n.id), isNot(contains('n2')));
    });

    test('returns empty when query matches nothing', () async {
      vm = LibraryViewModel(
        notationRepo,
        trashRepo,
        tagRepository: tagRepo,
        searchService: _FakeSearchService({'xyz': []}),
      );
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);

      vm.setSearchQuery('xyz');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final displayed = await vm.displayedNotations;
      expect(displayed, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Debounce
  // -------------------------------------------------------------------------

  group('search debounce', () {
    test('does not trigger search before 300 ms elapses', () {
      fakeAsync((async) {
        var searchCallCount = 0;
        final service = _CountingSearchService(() => searchCallCount++);
        final repo2 = _FakeNotationRepository();
        final vm2 = LibraryViewModel(
          repo2,
          trashRepo,
          tagRepository: tagRepo,
          searchService: service,
        );
        vm2.init();
        repo2.emitAll([n1]);
        async.flushMicrotasks();

        vm2.setSearchQuery('a');
        async.elapse(const Duration(milliseconds: 200));
        expect(searchCallCount, 0);

        async.elapse(const Duration(milliseconds: 200));
        expect(searchCallCount, 1);

        vm2.dispose();
        repo2.close();
      });
    });

    test('resets debounce on rapid successive keystrokes', () {
      fakeAsync((async) {
        var searchCallCount = 0;
        final service = _CountingSearchService(() => searchCallCount++);
        final repo2 = _FakeNotationRepository();
        final vm2 = LibraryViewModel(
          repo2,
          trashRepo,
          tagRepository: tagRepo,
          searchService: service,
        );
        vm2.init();
        repo2.emitAll([n1]);
        async.flushMicrotasks();

        vm2.setSearchQuery('a');
        async.elapse(const Duration(milliseconds: 100));
        vm2.setSearchQuery('ab');
        async.elapse(const Duration(milliseconds: 100));
        vm2.setSearchQuery('abc');
        async.elapse(const Duration(milliseconds: 350));

        // Only one call despite three keystrokes.
        expect(searchCallCount, 1);

        vm2.dispose();
        repo2.close();
      });
    });
  });

  // -------------------------------------------------------------------------
  // Tag filtering (no search)
  // -------------------------------------------------------------------------

  group('displayedNotations with tag filter only', () {
    setUp(() async {
      vm = LibraryViewModel(
        notationRepo,
        trashRepo,
        tagRepository: tagRepo,
        notationTagIds: {
          'n1': {'t1'},
          'n2': {'t1', 't2'},
          'n3': {'t2'},
        },
      );
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);
    });

    test('returns all when no tags selected', () async {
      final displayed = await vm.displayedNotations;
      expect(displayed, hasLength(3));
    });

    test('filters to notations with selected tag', () async {
      vm.toggleTag('t1');
      final displayed = await vm.displayedNotations;
      expect(displayed.map((n) => n.id), containsAll(['n1', 'n2']));
      expect(displayed.map((n) => n.id), isNot(contains('n3')));
    });

    test('AND logic: only notations with ALL selected tags pass', () async {
      vm.toggleTag('t1');
      vm.toggleTag('t2');
      final displayed = await vm.displayedNotations;
      expect(displayed.map((n) => n.id), equals(['n2']));
    });

    test('returns empty when no notations match AND filter', () async {
      // n1 has t1 only, n3 has t2 only — no notation has both
      vm.toggleTag('t1');
      vm.toggleTag('t2');
      // Override to have n2 without t2.
      vm = LibraryViewModel(
        notationRepo,
        trashRepo,
        tagRepository: tagRepo,
        notationTagIds: {
          'n1': {'t1'},
          'n2': {'t1'},
          'n3': {'t2'},
        },
      );
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);

      vm.toggleTag('t1');
      vm.toggleTag('t2');
      final displayed = await vm.displayedNotations;
      expect(displayed, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Composition: search + tag filter
  // -------------------------------------------------------------------------

  group('displayedNotations with search AND tag filter', () {
    setUp(() async {
      vm = LibraryViewModel(
        notationRepo,
        trashRepo,
        tagRepository: tagRepo,
        searchService: _FakeSearchService({
          'Bhai': ['n1', 'n2'],
        }),
        notationTagIds: {
          'n1': {'t1'},
          'n2': {'t2'},
        },
      );
      vm.init();
      notationRepo.emitAll([n1, n2, n3]);
      await Future<void>.delayed(Duration.zero);
    });

    test('search then tag filter narrows results', () async {
      vm.setSearchQuery('Bhai');
      await Future<void>.delayed(const Duration(milliseconds: 350));
      vm.toggleTag('t1');

      final displayed = await vm.displayedNotations;
      // Search returns n1+n2; tag t1 further narrows to n1 only.
      expect(displayed.map((n) => n.id), equals(['n1']));
    });
  });

  // -------------------------------------------------------------------------
  // Available tags stream
  // -------------------------------------------------------------------------

  group('availableTags', () {
    test('starts empty', () {
      expect(vm.availableTags, isEmpty);
    });

    test('reflects tags from TagRepository stream', () async {
      vm.init();
      tagRepo.emitTags([tag1, tag2]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.availableTags, hasLength(2));
      expect(vm.availableTags.map((t) => t.id), containsAll(['t1', 't2']));
    });

    test('updates when stream emits new tags', () async {
      vm.init();
      tagRepo.emitTags([tag1]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.availableTags, hasLength(1));

      tagRepo.emitTags([tag1, tag2]);
      await Future<void>.delayed(Duration.zero);
      expect(vm.availableTags, hasLength(2));
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: counting search service
// ---------------------------------------------------------------------------

class _CountingSearchService implements LibrarySearchService {
  final void Function() onCall;
  _CountingSearchService(this.onCall);

  @override
  Future<List<String>> search(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.isNotEmpty) onCall();
    return const [];
  }
}
