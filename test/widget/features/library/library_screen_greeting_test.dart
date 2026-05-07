// library_screen_greeting_test.dart — widget tests for LibraryScreen greeting
// and first-launch name prompt.
//
// Covers:
//   - Shows "Hi, <name>" when preferences return a non-empty name.
//   - Shows "Hi there" when preferencesRepository is null.
//   - Shows the name-prompt dialog when preferences return an empty name.
//   - Dialog Save button is disabled while the text field is empty.
//   - Dialog Save button is enabled after text is entered.
//   - Saving a name updates the greeting and dismisses the dialog.

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
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeNotationRepository implements NotationRepository {
  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      const Stream.empty();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

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

/// Fake [PreferencesRepository] that returns a configurable [UserPreferences].
class _FakePreferencesRepository implements PreferencesRepository {
  _FakePreferencesRepository({required this.userName});

  String userName;
  String? savedName;

  @override
  Future<UserPreferences> getPreferences() async {
    return UserPreferences(
      userName: userName,
      themeMode: AppThemeMode.system,
      colorSchemeMode: ColorSchemeMode.catppuccin,
      defaultSort: SortOrder.createdAtDesc,
      defaultView: ViewMode.list,
    );
  }

  @override
  Stream<UserPreferences> watchPreferences() => Stream.value(
        UserPreferences(
          userName: userName,
          themeMode: AppThemeMode.system,
          colorSchemeMode: ColorSchemeMode.catppuccin,
          defaultSort: SortOrder.createdAtDesc,
          defaultView: ViewMode.list,
        ),
      );

  @override
  Future<void> updateUserName(String name) async {
    savedName = name;
    userName = name;
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {}

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {}

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {}

  @override
  Future<void> updateSeedColor(String? colorHex) async {}

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {}

  @override
  Future<void> updateAutoScrollSpeed(double speed) async {}

  @override
  Future<void> updateTagsSeeded({required bool value}) async {}
}

/// Pumps a [LibraryScreen] with a fresh [LibraryViewModel] and the given
/// optional [preferencesRepository].
Future<void> _pumpLibrary(
  WidgetTester tester, {
  _FakePreferencesRepository? preferencesRepository,
}) async {
  final notationRepo = _FakeNotationRepository();
  final trashRepo = _FakeTrashRepository();
  final vm = LibraryViewModel(notationRepo, trashRepo);

  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<LibraryViewModel>.value(
        value: vm,
        child: LibraryScreen(
          preferencesRepository: preferencesRepository,
        ),
      ),
    ),
  );
  // Allow postFrameCallback to run (initState → _loadGreeting).
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LibraryScreen greeting', () {
    testWidgets(
      'shows "Hi there" when preferencesRepository is null',
      (tester) async {
        await _pumpLibrary(tester);

        expect(find.text('Hi there'), findsOneWidget);
      },
    );

    testWidgets(
      'shows "Hi, <name>" when preferences return a non-empty name',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: 'Roudranil');
        await _pumpLibrary(tester, preferencesRepository: repo);

        // Wait for the async _loadGreeting to complete.
        await tester.pump();

        expect(find.text('Hi, Roudranil'), findsOneWidget);
      },
    );
  });

  group('LibraryScreen first-launch name prompt', () {
    /// Pumps enough frames for the async _loadGreeting to complete and the
    /// dialog to appear without needing pumpAndSettle (which times out because
    /// the stream-based notation list never completes).
    Future<void> pumpUntilDialog(WidgetTester tester) async {
      // Allow postFrameCallback + async getPreferences + showDialog.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
    }

    testWidgets(
      'shows dialog when preferences return an empty name',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: '');
        await _pumpLibrary(tester, preferencesRepository: repo);
        await pumpUntilDialog(tester);

        expect(find.text("What's your name?"), findsOneWidget);
      },
    );

    testWidgets(
      'Save button is disabled while text field is empty',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: '');
        await _pumpLibrary(tester, preferencesRepository: repo);
        await pumpUntilDialog(tester);

        // The FilledButton should be disabled: onPressed == null.
        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save'),
        );
        expect(saveButton.onPressed, isNull);
      },
    );

    testWidgets(
      'Save button is enabled after text is entered',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: '');
        await _pumpLibrary(tester, preferencesRepository: repo);
        await pumpUntilDialog(tester);

        // Target the dialog's TextField via the hint text to avoid ambiguity
        // with the LibraryScreen search bar.
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your name'),
          'Roudranil',
        );
        await tester.pump();

        final saveButton = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Save'),
        );
        expect(saveButton.onPressed, isNotNull);
      },
    );

    testWidgets(
      'tapping Save persists the name and updates the greeting',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: '');
        await _pumpLibrary(tester, preferencesRepository: repo);
        await pumpUntilDialog(tester);

        await tester.enterText(
          find.widgetWithText(TextField, 'Enter your name'),
          'Roudranil',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Save'));
        // pump(0): processes the tap; Navigator.pop() queues the dialog exit.
        await tester.pump();
        // pump(200ms): completes the dialog exit animation.
        await tester.pump(const Duration(milliseconds: 200));
        // pump(): allows showDialog future to complete + updateUserName await.
        await tester.pump();
        // pump(): allows setState + frame rebuild.
        await tester.pump();

        // Dialog should be dismissed.
        expect(find.text("What's your name?"), findsNothing);

        // Greeting should be updated.
        expect(find.text('Hi, Roudranil'), findsOneWidget);

        // Repository should have received the save call.
        expect(repo.savedName, 'Roudranil');
      },
    );

    testWidgets(
      'dialog cannot be dismissed by tapping the barrier',
      (tester) async {
        final repo = _FakePreferencesRepository(userName: '');
        await _pumpLibrary(tester, preferencesRepository: repo);
        await pumpUntilDialog(tester);

        // Tap outside the dialog (barrier).
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();

        // Dialog should still be present because barrierDismissible: false.
        expect(find.text("What's your name?"), findsOneWidget);
      },
    );
  });
}
