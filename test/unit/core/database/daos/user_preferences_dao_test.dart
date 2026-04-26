// Unit tests for UserPreferencesDao.
//
// Covers all public methods against an in-memory Drift database:
//   getPreferences, upsertPreferences.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/database/daos/user_preferences_dao.dart';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // getPreferences
  // -------------------------------------------------------------------------

  group('UserPreferencesDao.getPreferences', () {
    late AppDatabase db;
    late UserPreferencesDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = UserPreferencesDao(db);
    });
    tearDown(() => db.close());

    test('returns default row when table is empty', () async {
      final prefs = await dao.getPreferences();

      expect(prefs, isNotNull);
      expect(prefs.id, 1);
      expect(prefs.userName, 'Musician');
      expect(prefs.themeMode, 'system');
      expect(prefs.colorSchemeMode, 'catppuccin');
      expect(prefs.seedColor, isNull);
      expect(prefs.defaultSort, 'created_at_desc');
      expect(prefs.defaultView, 'list');
    });

    test('returns existing row when one is already present', () async {
      // Pre-insert a row with custom values.
      await db.into(db.userPreferencesTable).insert(
            const UserPreferencesTableCompanion(),
          );

      final prefs = await dao.getPreferences();
      expect(prefs.id, 1);
      expect(prefs.userName, 'Musician');
    });

    test('calling getPreferences twice returns the same row', () async {
      final first = await dao.getPreferences();
      final second = await dao.getPreferences();

      expect(first.id, second.id);
      expect(first.userName, second.userName);
    });

    test('singleton row always has id = 1', () async {
      final prefs = await dao.getPreferences();
      expect(prefs.id, 1);
    });
  });

  // -------------------------------------------------------------------------
  // upsertPreferences
  // -------------------------------------------------------------------------

  group('UserPreferencesDao.upsertPreferences — insert path', () {
    late AppDatabase db;
    late UserPreferencesDao dao;

    setUp(() {
      db = AppDatabase.forTesting();
      dao = UserPreferencesDao(db);
    });
    tearDown(() => db.close());

    test('inserts preferences when table is empty', () async {
      const companion = UserPreferencesTableCompanion();
      await dao.upsertPreferences(companion);

      final rows = await db.select(db.userPreferencesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.id, 1);
    });

    test('persists non-default userName', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          userName: Value('Roudranil'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.userName, 'Roudranil');
    });

    test('persists dark themeMode', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          themeMode: Value('dark'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.themeMode, 'dark');
    });

    test('persists monet colorSchemeMode', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          colorSchemeMode: Value('monet'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.colorSchemeMode, 'monet');
    });

    test('persists a seedColor hex', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          seedColor: Value('#cba6f7'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.seedColor, '#cba6f7');
    });

    test('persists a non-default defaultSort', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          defaultSort: Value('title_asc'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.defaultSort, 'title_asc');
    });
  });

  group('UserPreferencesDao.upsertPreferences — update path', () {
    late AppDatabase db;
    late UserPreferencesDao dao;

    setUp(() async {
      db = AppDatabase.forTesting();
      dao = UserPreferencesDao(db);
      // Seed the singleton row.
      await dao.upsertPreferences(const UserPreferencesTableCompanion());
    });
    tearDown(() => db.close());

    test('updates userName without creating a duplicate row', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          userName: Value('New Name'),
        ),
      );

      final rows = await db.select(db.userPreferencesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.userName, 'New Name');
    });

    test('updates themeMode to light', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          themeMode: Value('light'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.themeMode, 'light');
    });

    test('updates multiple fields in one call', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          userName: Value('Raaga'),
          themeMode: Value('dark'),
          colorSchemeMode: Value('monet'),
          defaultSort: Value('play_count_desc'),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.userName, 'Raaga');
      expect(prefs.themeMode, 'dark');
      expect(prefs.colorSchemeMode, 'monet');
      expect(prefs.defaultSort, 'play_count_desc');
    });

    test('clears seedColor when set to null', () async {
      // First set a seed color.
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          seedColor: Value('#f38ba8'),
        ),
      );
      // Now clear it.
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(
          seedColor: Value(null),
        ),
      );

      final prefs = await dao.getPreferences();
      expect(prefs.seedColor, isNull);
    });

    test('table still has exactly one row after multiple upserts', () async {
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(userName: Value('A')),
      );
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(userName: Value('B')),
      );
      await dao.upsertPreferences(
        const UserPreferencesTableCompanion(userName: Value('C')),
      );

      final rows = await db.select(db.userPreferencesTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.userName, 'C');
    });
  });
}
