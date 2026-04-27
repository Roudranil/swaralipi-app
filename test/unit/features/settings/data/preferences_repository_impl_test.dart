// Unit tests for UserPreferencesRepositoryImpl.
//
// Covers all public methods against an in-memory Drift database:
//   getPreferences, updatePreferences, updateThemeMode, updateColorSchemeMode,
//   updateSeedColor, updateTagsSeeded.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/settings/data/user_preferences_repository_impl.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';

void main() {
  group('UserPreferencesRepositoryImpl.getPreferences', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('returns default preferences on first call', () async {
      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.system);
      expect(prefs.colorSchemeMode, ColorSchemeMode.catppuccin);
      expect(prefs.defaultSort, SortOrder.createdAtDesc);
      expect(prefs.defaultView, ViewMode.list);
      expect(prefs.seedColor, isNull);
      expect(prefs.tagsSeeded, isFalse);
    });

    test('returns same row on subsequent calls (singleton)', () async {
      final first = await repo.getPreferences();
      final second = await repo.getPreferences();
      expect(first, equals(second));
    });
  });

  group('UserPreferencesRepositoryImpl.updatePreferences', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('persists full preferences and reads back identical', () async {
      const updated = UserPreferences(
        userName: 'Test',
        themeMode: AppThemeMode.dark,
        colorSchemeMode: ColorSchemeMode.monet,
        seedColor: '#f38ba8',
        defaultSort: SortOrder.titleAsc,
        defaultView: ViewMode.list,
        tagsSeeded: true,
      );

      await repo.updatePreferences(updated);
      final result = await repo.getPreferences();

      expect(result, equals(updated));
    });

    test('multiple updates are idempotent — last write wins', () async {
      const first = UserPreferences(
        userName: 'A',
        themeMode: AppThemeMode.light,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
      );
      const second = UserPreferences(
        userName: 'B',
        themeMode: AppThemeMode.dark,
        colorSchemeMode: ColorSchemeMode.monet,
        defaultSort: SortOrder.titleAsc,
        defaultView: ViewMode.list,
      );

      await repo.updatePreferences(first);
      await repo.updatePreferences(second);

      final result = await repo.getPreferences();
      expect(result.userName, 'B');
      expect(result.themeMode, AppThemeMode.dark);
    });
  });

  group('UserPreferencesRepositoryImpl.updateThemeMode', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('light — persists and reads back light', () async {
      await repo.updateThemeMode(AppThemeMode.light);
      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.light);
    });

    test('dark — persists and reads back dark', () async {
      await repo.updateThemeMode(AppThemeMode.dark);
      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.dark);
    });

    test('system — persists and reads back system', () async {
      await repo.updateThemeMode(AppThemeMode.light);
      await repo.updateThemeMode(AppThemeMode.system);
      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.system);
    });

    test('does not affect other fields', () async {
      // set a non-default color scheme first
      await repo.updateColorSchemeMode(ColorSchemeMode.monet);
      await repo.updateThemeMode(AppThemeMode.dark);

      final prefs = await repo.getPreferences();
      expect(prefs.colorSchemeMode, ColorSchemeMode.monet);
    });
  });

  group('UserPreferencesRepositoryImpl.updateColorSchemeMode', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('monet — persists and reads back monet', () async {
      await repo.updateColorSchemeMode(ColorSchemeMode.monet);
      final prefs = await repo.getPreferences();
      expect(prefs.colorSchemeMode, ColorSchemeMode.monet);
    });

    test('catppuccin — persists and reads back catppuccin', () async {
      await repo.updateColorSchemeMode(ColorSchemeMode.monet);
      await repo.updateColorSchemeMode(ColorSchemeMode.catppuccin);
      final prefs = await repo.getPreferences();
      expect(prefs.colorSchemeMode, ColorSchemeMode.catppuccin);
    });

    test('does not affect themeMode', () async {
      await repo.updateThemeMode(AppThemeMode.dark);
      await repo.updateColorSchemeMode(ColorSchemeMode.monet);

      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.dark);
    });
  });

  group('UserPreferencesRepositoryImpl.updateSeedColor', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('stores hex string and reads back same value', () async {
      await repo.updateSeedColor('#cba6f7');
      final prefs = await repo.getPreferences();
      expect(prefs.seedColor, '#cba6f7');
    });

    test('null clears seed color', () async {
      await repo.updateSeedColor('#cba6f7');
      await repo.updateSeedColor(null);
      final prefs = await repo.getPreferences();
      expect(prefs.seedColor, isNull);
    });

    test('does not affect themeMode or colorSchemeMode', () async {
      await repo.updateThemeMode(AppThemeMode.dark);
      await repo.updateColorSchemeMode(ColorSchemeMode.monet);
      await repo.updateSeedColor('#f38ba8');

      final prefs = await repo.getPreferences();
      expect(prefs.themeMode, AppThemeMode.dark);
      expect(prefs.colorSchemeMode, ColorSchemeMode.monet);
    });
  });

  group('UserPreferencesRepositoryImpl.updateTagsSeeded', () {
    late AppDatabase db;
    late UserPreferencesRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
    });
    tearDown(() => db.close());

    test('sets tagsSeeded to true', () async {
      await repo.updateTagsSeeded(value: true);
      final prefs = await repo.getPreferences();
      expect(prefs.tagsSeeded, isTrue);
    });

    test('sets tagsSeeded to false', () async {
      await repo.updateTagsSeeded(value: true);
      await repo.updateTagsSeeded(value: false);
      final prefs = await repo.getPreferences();
      expect(prefs.tagsSeeded, isFalse);
    });
  });
}
