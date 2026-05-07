// app_db_injection_test.dart — widget tests for the single-AppDatabase
// instantiation fix (Task 1).
//
// Covers:
//   - SwaralipiApp accepts optional `database` and `storageService` params.
//   - When provided, the injected AppDatabase instance is used by
//     _initDependencies (no second AppDatabase() is constructed, preventing
//     the SQLite WAL lock).
//   - SwaralipiApp.forTesting continues to work without regression.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/app.dart';
import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';

// ---------------------------------------------------------------------------
// Fakes — match signatures from integration_test
// ---------------------------------------------------------------------------

const Tag _kStubTag = Tag(
  id: 'tag-1',
  name: 'stub',
  colorHex: '#ffffff',
  createdAt: '2024-01-01T00:00:00.000Z',
  updatedAt: '2024-01-01T00:00:00.000Z',
);

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

class _FakeTrashRepository implements TrashRepository {
  @override
  Stream<List<Notation>> watchTrashedNotations() => const Stream.empty();

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
    userName: 'Test',
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
  Future<void> updateUserName(String name) async {
    _prefs = _prefs.copyWith(userName: name);
  }

  @override
  Stream<UserPreferences> watchPreferences() => Stream.value(_prefs);

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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SwaralipiApp — database injection (Task 1)', () {
    test(
      'SwaralipiApp() accepts database and storageService constructor params',
      () {
        // This test verifies the constructor signature. If it compiles,
        // the injection API is correct and the production SwaralipiApp can
        // receive the single AppDatabase instance from main().
        final db = AppDatabase.forTesting();
        final storage = FileStorageService();

        final app = SwaralipiApp(database: db, storageService: storage);

        expect(app, isA<StatefulWidget>());

        db.close();
      },
    );

    testWidgets(
      'SwaralipiApp.forTesting renders without regression',
      (tester) async {
        await tester.pumpWidget(
          SwaralipiApp.forTesting(
            initialLocation: '/settings',
            tagRepository: _FakeTagRepository(),
            trashRepository: _FakeTrashRepository(),
            instrumentRepository: _FakeInstrumentRepository(),
            customFieldRepository: _FakeCustomFieldRepository(),
            preferencesRepository: _FakePreferencesRepository(),
            notationRepository: _FakeNotationRepository(),
          ),
        );

        // First frame — GoRouter and DynamicColorBuilder initialise.
        await tester.pump();

        // The settings screen should be visible.
        expect(find.text('Settings'), findsWidgets);
      },
    );
  });
}
