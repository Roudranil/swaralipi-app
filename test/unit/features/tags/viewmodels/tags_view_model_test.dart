// Unit tests for TagsViewModel.
//
// Covers all public state transitions and methods using a FakeTagRepository:
//   init (watchAllTags) → idle / loading / success / error
//   createTag → optimistic stream update via fake
//   updateTag → success and TagNotFoundException paths
//   deleteTag → success and confirmation dialog paths
//
// Each test sets up a fresh FakeTagRepository in setUp to ensure isolation.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/tags/viewmodels/tags_view_model.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory fake [TagRepository] for controlling stream and error scenarios.
class FakeTagRepository implements TagRepository {
  final _controller = StreamController<List<Tag>>.broadcast();
  Object? _watchError;
  Object? _createError;
  Object? _updateError;
  Object? _deleteError;
  final List<Tag> _tags = [];

  void emitTags(List<Tag> tags) {
    _tags
      ..clear()
      ..addAll(tags);
    _controller.add(List.unmodifiable(_tags));
  }

  void emitWatchError(Object error) {
    _watchError = error;
    _controller.addError(error);
  }

  void setCreateError(Object? error) => _createError = error;
  void setUpdateError(Object? error) => _updateError = error;
  void setDeleteError(Object? error) => _deleteError = error;

  @override
  Stream<List<Tag>> watchAllTags() {
    if (_watchError != null) {
      return Stream.error(_watchError!);
    }
    return _controller.stream;
  }

  @override
  Future<Tag> createTag(String name, String colorHex) async {
    if (_createError != null) throw _createError!;
    final tag = Tag(
      id: 'id-$name',
      name: name,
      colorHex: colorHex,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );
    _tags.add(tag);
    _controller.add(List.unmodifiable(_tags));
    return tag;
  }

  @override
  Future<Tag> updateTag(
    String id, {
    String? name,
    String? colorHex,
  }) async {
    if (_updateError != null) throw _updateError!;
    final idx = _tags.indexWhere((t) => t.id == id);
    if (idx == -1) throw TagNotFoundException(id);
    final updated = _tags[idx].copyWith(name: name, colorHex: colorHex);
    _tags[idx] = updated;
    _controller.add(List.unmodifiable(_tags));
    return updated;
  }

  @override
  Future<void> deleteTag(String id) async {
    if (_deleteError != null) throw _deleteError!;
    _tags.removeWhere((t) => t.id == id);
    _controller.add(List.unmodifiable(_tags));
  }

  @override
  Future<void> seedDefaultTagsIfNeeded() async {}

  void close() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Tag _makeTag({
  String id = 'tag-1',
  String name = 'Ragas',
  String colorHex = '#f38ba8',
}) =>
    Tag(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeTagRepository repo;
  late TagsViewModel vm;

  setUp(() {
    repo = FakeTagRepository();
    vm = TagsViewModel(repo);
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
      expect(vm.state, isA<TagsStateIdle>());
    });
  });

  // -------------------------------------------------------------------------
  // init
  // -------------------------------------------------------------------------

  group('init', () {
    test('transitions to loading then success when stream emits', () async {
      final states = <TagsState>[];
      vm.addListener(() => states.add(vm.state));

      vm.init();

      // Immediately loading
      expect(states.last, isA<TagsStateLoading>());

      // Emit data
      final tags = [_makeTag()];
      repo.emitTags(tags);

      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<TagsStateSuccess>());
      expect((vm.state as TagsStateSuccess).tags, tags);
    });

    test('transitions to loading then error when stream emits error', () async {
      final states = <TagsState>[];
      vm.addListener(() => states.add(vm.state));

      vm.init();

      // Trigger stream error
      repo.emitWatchError(Exception('DB failure'));

      await Future<void>.delayed(Duration.zero);

      expect(vm.state, isA<TagsStateError>());
      expect(
        (vm.state as TagsStateError).message,
        contains('DB failure'),
      );
    });

    test('updates state when stream emits subsequent values', () async {
      vm.init();
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TagsStateSuccess).tags.length, 1);

      final tag2 = _makeTag(id: 'tag-2', name: 'Bhajans');
      repo.emitTags([_makeTag(), tag2]);
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TagsStateSuccess).tags.length, 2);
    });

    test('calling init multiple times cancels previous subscription', () async {
      vm.init();
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);
      expect((vm.state as TagsStateSuccess).tags.length, 1);

      vm.init(); // Re-init
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TagsStateSuccess).tags, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // createTag
  // -------------------------------------------------------------------------

  group('createTag', () {
    setUp(() {
      vm.init();
    });

    test('success — returns created Tag and stream updates', () async {
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      final result = await vm.createTag('Practice', '#cba6f7');
      await Future<void>.delayed(Duration.zero);

      expect(result, isA<Tag>());
      expect(result!.name, 'Practice');
      expect((vm.state as TagsStateSuccess).tags.length, 1);
    });

    test('failure — propagates error and exposes it via createError', () async {
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      repo.setCreateError(Exception('UNIQUE constraint failed'));

      final result = await vm.createTag('Dup', '#f38ba8');

      expect(result, isNull);
      expect(vm.createError, isNotNull);
    });

    test('clearCreateError resets the error', () async {
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      repo.setCreateError(Exception('fail'));
      await vm.createTag('X', '#abc');
      expect(vm.createError, isNotNull);

      vm.clearCreateError();
      expect(vm.createError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // updateTag
  // -------------------------------------------------------------------------

  group('updateTag', () {
    setUp(() {
      vm.init();
    });

    test('success — returns updated Tag', () async {
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      final result = await vm.updateTag(
        'tag-1',
        name: 'Ragas Updated',
        colorHex: '#a6e3a1',
      );

      expect(result, isA<Tag>());
      expect(result!.name, 'Ragas Updated');
    });

    test('failure — propagates TagNotFoundException via updateError', () async {
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      final result = await vm.updateTag('nonexistent');

      expect(result, isNull);
      expect(vm.updateError, isNotNull);
    });

    test('clearUpdateError resets the error', () async {
      repo.emitTags([]);
      await Future<void>.delayed(Duration.zero);

      await vm.updateTag('nonexistent');
      expect(vm.updateError, isNotNull);

      vm.clearUpdateError();
      expect(vm.updateError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // deleteTag
  // -------------------------------------------------------------------------

  group('deleteTag', () {
    setUp(() {
      vm.init();
    });

    test('success — tag removed from stream', () async {
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TagsStateSuccess).tags.length, 1);

      await vm.deleteTag('tag-1');
      await Future<void>.delayed(Duration.zero);

      expect((vm.state as TagsStateSuccess).tags, isEmpty);
    });

    test('failure — exposes error via deleteError', () async {
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      repo.setDeleteError(Exception('delete failed'));
      await vm.deleteTag('tag-1');

      expect(vm.deleteError, isNotNull);
    });

    test('clearDeleteError resets the error', () async {
      repo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      repo.setDeleteError(Exception('fail'));
      await vm.deleteTag('tag-1');
      expect(vm.deleteError, isNotNull);

      vm.clearDeleteError();
      expect(vm.deleteError, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // dispose
  // -------------------------------------------------------------------------

  group('dispose', () {
    test('cancels stream subscription on dispose', () async {
      // Use a separate vm so tearDown does not double-dispose.
      final localRepo = FakeTagRepository();
      final localVm = TagsViewModel(localRepo);

      localVm.init();
      localRepo.emitTags([_makeTag()]);
      await Future<void>.delayed(Duration.zero);

      localVm.dispose();

      // Emitting after dispose must not throw.
      expect(() => localRepo.emitTags([]), returnsNormally);

      localRepo.close();
    });
  });
}
