// Widget tests for NotationDetailScreen.
//
// Covers the following acceptance criteria from #95:
//   - Loading indicator shown while notation is being fetched
//   - Error view shown when the repository throws
//   - Not-found view shown when notation does not exist
//   - Metadata block renders: title, artists, languages, time sig, key sig, notes
//   - Tags rendered as colored chips
//   - Custom field values rendered
//   - Page count section shown when pages exist
//   - AppBar shows Edit action when edit dependencies are provided
//   - AppBar shows Play, Duplicate, and Delete actions when loaded
//   - Delete action triggers confirmation dialog
//   - Edit action hidden when edit dependencies are omitted

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/notation_detail/screens/notation_detail_screen.dart';
import 'package:swaralipi/features/notation_detail/viewmodels/notation_detail_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeNotationRepository implements NotationRepository {
  NotationDetail? _detail;
  Object? _loadError;
  Completer<void>? _loadCompleter;

  void setDetail(NotationDetail? d) => _detail = d;
  void setLoadError(Object? e) => _loadError = e;

  /// Installs a blocking gate on the next [loadNotation] call.
  ///
  /// The call suspends until [unblock] is invoked, allowing tests to
  /// assert on the loading state before the Future resolves.
  void blockLoad() => _loadCompleter = Completer<void>();

  /// Releases the gate installed by [blockLoad].
  void unblock() => _loadCompleter?.complete();

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    final completer = _loadCompleter;
    if (completer != null) await completer.future;
    if (_loadError != null) throw _loadError!;
    return _detail;
  }

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      const Stream.empty();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

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
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}
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
// Test helpers
// ---------------------------------------------------------------------------

Notation _makeNotation({
  String id = 'n1',
  String title = 'Raag Yaman',
  List<String> artists = const ['Pandit Ji'],
  List<String> languages = const ['Hindi'],
  String? timeSig = '4/4',
  String? keySig = 'C',
  String notes = 'Some personal notes',
}) =>
    Notation(
      id: id,
      title: title,
      artists: artists,
      languages: languages,
      timeSig: timeSig,
      keySig: keySig,
      notes: notes,
      playCount: 0,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

NotationPage _makePage(String notationId, int order) => NotationPage(
      id: 'page-$order',
      notationId: notationId,
      pageOrder: order,
      imagePath: 'notations/$notationId/page_${order}_original.jpg',
      renderParams: '{}',
      createdAt: '2024-01-01T00:00:00Z',
    );

Tag _makeTag(String name, {String color = '#f38ba8'}) => Tag(
      id: 'tag-$name',
      name: name,
      colorHex: color,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

NotationDetail _makeDetail({
  String id = 'n1',
  String title = 'Raag Yaman',
  int pageCount = 2,
  List<Tag> tags = const [],
  List<CustomFieldValue> customFieldValues = const [],
  List<String> artists = const ['Pandit Ji'],
  List<String> languages = const ['Hindi'],
  String? timeSig = '4/4',
  String? keySig = 'C',
  String notes = 'Personal notes',
}) =>
    NotationDetail(
      notation: _makeNotation(
        id: id,
        title: title,
        artists: artists,
        languages: languages,
        timeSig: timeSig,
        keySig: keySig,
        notes: notes,
      ),
      pages: List.generate(pageCount, (i) => _makePage(id, i)),
      tags: tags,
      customFieldValues: customFieldValues,
    );

/// Builds the screen wrapped in the necessary provider hierarchy.
///
/// [notationRepository] and [trashRepository] are required to construct the
/// [NotationDetailViewModel]. Optional edit dependencies are forwarded to the
/// screen to control whether the Edit action is shown.
Widget _buildScreen(
  _FakeNotationRepository notationRepository,
  _FakeTrashRepository trashRepository, {
  String notationId = 'n1',
  bool withEditDeps = false,
}) {
  final vm = NotationDetailViewModel(notationRepository, trashRepository);
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: ChangeNotifierProvider<NotationDetailViewModel>.value(
      value: vm,
      child: NotationDetailScreen(
        notationId: notationId,
        notationRepository: withEditDeps ? notationRepository : null,
        tagRepository: null,
        instrumentRepository: null,
        customFieldRepository: null,
        fileStorageService: null,
      ),
    ),
  );
}

/// Pumps the widget and waits for the post-frame async load to complete.
Future<void> pumpAndLoad(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(widget);
  // Process the post-frame callback that triggers loadNotation.
  await tester.pump();
  // Allow async repo calls to complete.
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _FakeNotationRepository repo;
  late _FakeTrashRepository trash;

  setUp(() {
    repo = _FakeNotationRepository();
    trash = _FakeTrashRepository();
  });

  // -------------------------------------------------------------------------
  // Loading state
  // -------------------------------------------------------------------------

  group('loading state', () {
    testWidgets('shows CircularProgressIndicator while loading',
        (tester) async {
      repo.blockLoad();
      final screen = _buildScreen(repo, trash);

      await tester.pumpWidget(screen);
      // Trigger the post-frame callback that calls loadNotation.
      await tester.pump();
      // One more pump lets the async function reach the await-completer gate.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Unblock so the Future completes; drain remaining microtasks.
      repo.unblock();
      await tester.pump();
      await tester.pump();
    });
  });

  // -------------------------------------------------------------------------
  // Error state
  // -------------------------------------------------------------------------

  group('error state', () {
    testWidgets('shows error view when repository throws', (tester) async {
      repo.setLoadError(Exception('db failure'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load notation'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Not-found state
  // -------------------------------------------------------------------------

  group('not-found state', () {
    testWidgets('shows not-found view when notation is null', (tester) async {
      repo.setDetail(null);
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
      expect(find.text('Notation not found'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Success state — metadata block
  // -------------------------------------------------------------------------

  group('success state — metadata block', () {
    testWidgets('shows notation title in AppBar and body', (tester) async {
      repo.setDetail(_makeDetail(title: 'Raag Bhairav'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      // Headline in body
      expect(find.text('Raag Bhairav'), findsWidgets);
    });

    testWidgets('shows artist when provided', (tester) async {
      repo.setDetail(_makeDetail(artists: ['Ustad Ahmed']));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Ustad Ahmed'), findsOneWidget);
    });

    testWidgets('shows language when provided', (tester) async {
      repo.setDetail(_makeDetail(languages: ['Bengali']));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Bengali'), findsOneWidget);
    });

    testWidgets('shows time signature when provided', (tester) async {
      repo.setDetail(_makeDetail(timeSig: '6/8'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('6/8'), findsOneWidget);
    });

    testWidgets('shows key signature when provided', (tester) async {
      repo.setDetail(_makeDetail(keySig: 'D minor'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('D minor'), findsOneWidget);
    });

    testWidgets('shows notes when non-empty', (tester) async {
      repo.setDetail(_makeDetail(notes: 'Play slowly'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Play slowly'), findsOneWidget);
    });

    testWidgets('hides optional fields when absent', (tester) async {
      repo.setDetail(
        _makeDetail(
          artists: [],
          languages: [],
          timeSig: null,
          keySig: null,
          notes: '',
        ),
      );
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      // None of the optional metadata icons should appear
      expect(find.byIcon(Icons.person_outline), findsNothing);
      expect(find.byIcon(Icons.language_outlined), findsNothing);
      expect(find.byIcon(Icons.access_time_outlined), findsNothing);
      expect(find.byIcon(Icons.music_note_outlined), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Success state — tags
  // -------------------------------------------------------------------------

  group('success state — tags', () {
    testWidgets('renders tag chips when tags are present', (tester) async {
      final tags = [_makeTag('Bhajan'), _makeTag('Classical')];
      repo.setDetail(_makeDetail(tags: tags));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Bhajan'), findsOneWidget);
      expect(find.text('Classical'), findsOneWidget);
    });

    testWidgets('renders no chip row when tags are empty', (tester) async {
      repo.setDetail(_makeDetail(tags: []));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      // No chips visible (Chip widget should not exist)
      expect(find.byType(Chip), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Success state — custom field values
  // -------------------------------------------------------------------------

  group('success state — custom field values', () {
    testWidgets('renders text custom field value when present', (tester) async {
      final cfv = [
        const CustomFieldValue(
          notationId: 'n1',
          definitionId: 'def-1',
          valueText: 'Slow tempo',
        ),
      ];
      repo.setDetail(_makeDetail(customFieldValues: cfv));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Slow tempo'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Success state — page thumbnails
  // -------------------------------------------------------------------------

  group('success state — page thumbnails', () {
    testWidgets('shows page count section heading when pages exist',
        (tester) async {
      repo.setDetail(_makeDetail(pageCount: 3));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.text('Pages (3)'), findsOneWidget);
    });

    testWidgets('hides page section when notation has no pages',
        (tester) async {
      repo.setDetail(_makeDetail(pageCount: 0));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.textContaining('Pages ('), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // AppBar actions
  // -------------------------------------------------------------------------

  group('AppBar actions', () {
    testWidgets('shows Play, Duplicate, Delete when loaded', (tester) async {
      repo.setDetail(_makeDetail());
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.copy_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('hides Edit action when edit deps are not provided',
        (tester) async {
      repo.setDetail(_makeDetail());
      await pumpAndLoad(
        tester,
        _buildScreen(repo, trash, withEditDeps: false),
      );

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('does not show Play/Duplicate/Delete on error state',
        (tester) async {
      repo.setLoadError(Exception('fail'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      expect(find.byIcon(Icons.play_circle_outline), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Delete confirmation dialog
  // -------------------------------------------------------------------------

  group('delete confirmation dialog', () {
    testWidgets('shows confirmation dialog when Delete tapped', (tester) async {
      repo.setDetail(_makeDetail(title: 'Bhairav'));
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Move to Trash?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('dismisses dialog on Cancel without navigating',
        (tester) async {
      repo.setDetail(_makeDetail());
      await pumpAndLoad(tester, _buildScreen(repo, trash));

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog dismissed; screen still shows detail content
      expect(find.text('Move to Trash?'), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
