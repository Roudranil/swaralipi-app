// Integration tests for Settings sub-route navigation.
//
// Verifies that tapping each settings tile from SettingsScreen navigates to
// the correct sub-screen and that back navigation returns to SettingsScreen
// without resetting ViewModel state.
//
// The full SwaralipiApp is pumped with all dependencies wired via fake
// repositories, exercising the real GoRouter configuration.
//
// Covered routes:
//   /settings/tags         — TagsScreen
//   /settings/instruments  — InstrumentClassesScreen
//   /settings/trash        — TrashScreen
//   /settings/appearance   — AppearanceScreen
//   /settings/custom-fields — CustomFieldsScreen
//
// Naming convention:
//   <starting state> → <action> → <expected result>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:swaralipi/app.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';

// ---------------------------------------------------------------------------
// Fake repositories
// ---------------------------------------------------------------------------

class _FakeTagRepository implements TagRepository {
  @override
  Stream<List<Tag>> watchAllTags() => Stream.value([]);
  @override
  Future<Tag> createTag(String name, String colorHex) async => _kStubTag;

  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) async =>
      _kStubTag;
  @override
  Future<void> deleteTag(String id) async {}
  @override
  Future<void> seedDefaultTagsIfNeeded() async {}
}

const Tag _kStubTag = Tag(
  id: 'tag-1',
  name: 'stub',
  colorHex: '#ffffff',
  createdAt: '2024-01-01T00:00:00.000Z',
  updatedAt: '2024-01-01T00:00:00.000Z',
);

class _FakeTrashRepository implements TrashRepository {
  @override
  Stream<List<Notation>> watchTrashedNotations() => Stream.value([]);
  @override
  Future<void> restoreNotation(String id) async {}
  @override
  Future<void> purgeNotation(String id) async {}
  @override
  Future<void> purgeAll() async {}
  @override
  Future<int> autoPurgeExpired() async => 0;
}

class _FakeInstrumentRepository implements InstrumentRepository {
  @override
  Stream<List<InstrumentClass>> watchActiveClasses() => Stream.value([]);
  @override
  Future<InstrumentClass> createClass(String name) async => InstrumentClass(
        id: 'ic-1',
        name: name,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );

  @override
  Future<InstrumentClass> updateClass(String id, String name) async =>
      InstrumentClass(
        id: id,
        name: name,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );
  @override
  Future<void> archiveClass(String id) async {}
  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
    String classId,
  ) =>
      Stream.value([]);
  @override
  Future<InstrumentInstance> createInstance(
    String classId, {
    required String colorHex,
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  }) =>
      throw UnimplementedError();
  @override
  Future<InstrumentInstance> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> archiveInstance(String id) async {}
}

class _FakeCustomFieldRepository implements CustomFieldRepository {
  @override
  Stream<List<CustomFieldDefinition>> watchAllDefinitions() => Stream.value([]);
  @override
  Future<CustomFieldDefinition> createDefinition(
    String keyName,
    String fieldType,
  ) =>
      throw UnimplementedError();
  @override
  Future<CustomFieldDefinition> updateDefinition(
    String id, {
    String? keyName,
    String? fieldType,
  }) =>
      throw UnimplementedError();
  @override
  Future<void> deleteDefinition(String id) async {}
}

class _FakePreferencesRepository implements PreferencesRepository {
  UserPreferences _prefs = const UserPreferences(
    userName: '',
    themeMode: AppThemeMode.system,
    colorSchemeMode: ColorSchemeMode.catppuccin,
    defaultSort: SortOrder.createdAtDesc,
    defaultView: ViewMode.list,
  );

  @override
  Future<UserPreferences> getPreferences() async => _prefs;

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    _prefs = preferences;
  }

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {
    _prefs = _prefs.copyWith(themeMode: mode);
  }

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {
    _prefs = _prefs.copyWith(colorSchemeMode: mode);
  }

  @override
  Future<void> updateSeedColor(String? colorHex) async {
    _prefs = _prefs.copyWith(seedColor: colorHex);
  }

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {
    _prefs = _prefs.copyWith(playerOrientation: orientation);
  }

  @override
  Future<void> updateAutoScrollSpeed(double speed) async {
    _prefs = _prefs.copyWith(autoScrollSpeed: speed);
  }

  @override
  Future<void> updateTagsSeeded({required bool value}) async {
    _prefs = _prefs.copyWith(tagsSeeded: value);
  }
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Builds [SwaralipiApp] pre-seeded with fake repositories and navigates
/// directly to /settings by providing a test router seeded at /settings.
Widget _buildAppAtSettings({
  _FakeTagRepository? tagRepo,
  _FakeTrashRepository? trashRepo,
  _FakeInstrumentRepository? instrumentRepo,
  _FakeCustomFieldRepository? customFieldRepo,
  _FakePreferencesRepository? prefsRepo,
}) {
  PackageInfo.setMockInitialValues(
    appName: 'Swaralipi',
    packageName: 'com.example.swaralipi',
    version: '0.1.0',
    buildNumber: '1',
    buildSignature: '',
  );

  return SwaralipiApp.forTesting(
    initialLocation: '/settings',
    tagRepository: tagRepo ?? _FakeTagRepository(),
    trashRepository: trashRepo ?? _FakeTrashRepository(),
    instrumentRepository: instrumentRepo ?? _FakeInstrumentRepository(),
    customFieldRepository: customFieldRepo ?? _FakeCustomFieldRepository(),
    preferencesRepository: prefsRepo ?? _FakePreferencesRepository(),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings sub-route navigation —', () {
    testWidgets(
      'tapping Tags tile renders TagsScreen at /settings/tags',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Tags'), findsOneWidget);

        await tester.tap(find.text('Tags'));
        await tester.pumpAndSettle();

        // TagsScreen has an AppBar titled 'Tags'
        expect(find.widgetWithText(AppBar, 'Tags'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Instruments tile renders InstrumentClassesScreen at '
      '/settings/instruments',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Instruments'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Instruments'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Trash tile renders TrashScreen at /settings/trash',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Trash'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Trash'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Appearance tile renders AppearanceScreen at '
      '/settings/appearance',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Appearance'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Appearance'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Custom Fields tile renders CustomFieldsScreen at '
      '/settings/custom-fields',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom Fields'));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Custom Fields'), findsOneWidget);
      },
    );

    testWidgets(
      'back navigation from Tags sub-screen returns to SettingsScreen',
      (tester) async {
        await tester.pumpWidget(_buildAppAtSettings());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Tags'));
        await tester.pumpAndSettle();

        // Navigate back using the back button
        final NavigatorState navigator = tester.state(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
      },
    );

    testWidgets(
      'deep-link navigation directly to /settings/tags does not crash',
      (tester) async {
        PackageInfo.setMockInitialValues(
          appName: 'Swaralipi',
          packageName: 'com.example.swaralipi',
          version: '0.1.0',
          buildNumber: '1',
          buildSignature: '',
        );

        await tester.pumpWidget(
          SwaralipiApp.forTesting(
            initialLocation: '/settings/tags',
            tagRepository: _FakeTagRepository(),
            trashRepository: _FakeTrashRepository(),
            instrumentRepository: _FakeInstrumentRepository(),
            customFieldRepository: _FakeCustomFieldRepository(),
            preferencesRepository: _FakePreferencesRepository(),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.widgetWithText(AppBar, 'Tags'), findsOneWidget);
      },
    );
  });
}
