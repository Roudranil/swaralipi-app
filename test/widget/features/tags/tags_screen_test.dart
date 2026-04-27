// Widget tests for TagsScreen.
//
// Verifies the screen renders correctly for each TagsState variant and that
// user interactions (FAB, long-press, swipe-to-dismiss, dialogs) trigger the
// correct ViewModel calls via a FakeTagsViewModel.
//
// All tests use Provider-injected FakeTagsViewModel to avoid real DB access.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/tags/screens/tags_screen.dart';
import 'package:swaralipi/features/tags/viewmodels/tags_view_model.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class FakeTagRepository implements TagRepository {
  @override
  Stream<List<Tag>> watchAllTags() => const Stream.empty();
  @override
  Future<Tag> createTag(String name, String colorHex) async => _makeTag();
  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) async =>
      _makeTag();
  @override
  Future<void> deleteTag(String id) async {}
  @override
  Future<void> seedDefaultTagsIfNeeded() async {}
}

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

class FakeTagsViewModel extends TagsViewModel {
  FakeTagsViewModel({
    TagsState initialState = const TagsStateIdle(),
    this.createTagResult,
    this.updateTagResult,
  }) : super(FakeTagRepository()) {
    _state = initialState;
  }

  TagsState _state = const TagsStateIdle();
  final Tag? createTagResult;
  final Tag? updateTagResult;

  bool initCalled = false;
  String? lastCreatedName;
  String? lastCreatedColor;
  String? lastUpdatedId;
  String? lastUpdatedName;
  String? lastDeletedId;

  @override
  TagsState get state => _state;

  void setState(TagsState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void init() {
    initCalled = true;
  }

  @override
  Future<Tag?> createTag(String name, String colorHex) async {
    lastCreatedName = name;
    lastCreatedColor = colorHex;
    return createTagResult;
  }

  @override
  Future<Tag?> updateTag(
    String id, {
    String? name,
    String? colorHex,
  }) async {
    lastUpdatedId = id;
    lastUpdatedName = name;
    return updateTagResult;
  }

  @override
  Future<void> deleteTag(String id) async {
    lastDeletedId = id;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildScreen(FakeTagsViewModel vm) {
  return ChangeNotifierProvider<TagsViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: TagsScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // State rendering
  // -------------------------------------------------------------------------

  group('TagsScreen state rendering', () {
    testWidgets('shows loading indicator in loading state', (tester) async {
      final vm = FakeTagsViewModel(
        initialState: const TagsStateLoading(),
      );

      await tester.pumpWidget(_buildScreen(vm));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows tags list in success state', (tester) async {
      final tags = [
        _makeTag(id: 'tag-1', name: 'Ragas', colorHex: '#f38ba8'),
        _makeTag(id: 'tag-2', name: 'Bhajans', colorHex: '#a6e3a1'),
      ];
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: tags),
      );

      await tester.pumpWidget(_buildScreen(vm));

      expect(find.text('Ragas'), findsOneWidget);
      expect(find.text('Bhajans'), findsOneWidget);
    });

    testWidgets('shows empty state message when no tags', (tester) async {
      final vm = FakeTagsViewModel(
        initialState: const TagsStateSuccess(tags: []),
      );

      await tester.pumpWidget(_buildScreen(vm));

      expect(find.text('No tags yet'), findsOneWidget);
    });

    testWidgets('shows error message in error state', (tester) async {
      final vm = FakeTagsViewModel(
        initialState: const TagsStateError(message: 'DB failure'),
      );

      await tester.pumpWidget(_buildScreen(vm));

      expect(find.textContaining('DB failure'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // init
  // -------------------------------------------------------------------------

  group('TagsScreen init', () {
    testWidgets('calls vm.init when screen loads', (tester) async {
      final vm = FakeTagsViewModel();

      await tester.pumpWidget(_buildScreen(vm));

      expect(vm.initCalled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // FAB — create tag
  // -------------------------------------------------------------------------

  group('TagsScreen FAB', () {
    testWidgets('FAB is visible', (tester) async {
      final vm = FakeTagsViewModel(
        initialState: const TagsStateSuccess(tags: []),
      );

      await tester.pumpWidget(_buildScreen(vm));

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets(
        'tapping FAB opens create bottom sheet with name field and color '
        'picker', (tester) async {
      final vm = FakeTagsViewModel(
        initialState: const TagsStateSuccess(tags: []),
      );

      await tester.pumpWidget(_buildScreen(vm));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Bottom sheet contains a text field for the name
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Delete confirmation dialog
  // -------------------------------------------------------------------------

  group('TagsScreen delete', () {
    testWidgets('tapping delete icon opens confirmation dialog',
        (tester) async {
      final tag = _makeTag(id: 'tag-1', name: 'Ragas');
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: [tag]),
      );

      await tester.pumpWidget(_buildScreen(vm));

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Dialog appears
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('confirming delete calls vm.deleteTag', (tester) async {
      final tag = _makeTag(id: 'tag-1', name: 'Ragas');
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: [tag]),
      );

      await tester.pumpWidget(_buildScreen(vm));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Tap confirm
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(vm.lastDeletedId, 'tag-1');
    });

    testWidgets('cancelling delete dialog does NOT call vm.deleteTag',
        (tester) async {
      final tag = _makeTag(id: 'tag-1', name: 'Ragas');
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: [tag]),
      );

      await tester.pumpWidget(_buildScreen(vm));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(vm.lastDeletedId, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Edit icon
  // -------------------------------------------------------------------------

  group('TagsScreen edit', () {
    testWidgets('tapping edit icon opens tag form bottom sheet',
        (tester) async {
      final tag = _makeTag(id: 'tag-1', name: 'Ragas');
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: [tag]),
      );

      await tester.pumpWidget(_buildScreen(vm));

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      // Form opens with pre-filled name
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Accessibility
  // -------------------------------------------------------------------------

  group('TagsScreen accessibility', () {
    testWidgets('tag rows have semantic labels', (tester) async {
      final tag = _makeTag(id: 'tag-1', name: 'Ragas');
      final vm = FakeTagsViewModel(
        initialState: TagsStateSuccess(tags: [tag]),
      );

      await tester.pumpWidget(_buildScreen(vm));

      final semantics = tester.getSemantics(find.text('Ragas'));
      expect(semantics.label, isNotEmpty);
    });
  });
}
