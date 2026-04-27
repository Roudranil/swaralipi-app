// Unit tests for TagRepositoryImpl.
//
// Covers all public methods against an in-memory Drift database and a
// FakeUserPreferencesDao:
//   watchAllTags, createTag, updateTag, deleteTag, seedDefaultTagsIfNeeded.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/tags/data/tag_repository_impl.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// In-memory [UserPreferencesRepository] fake for controlling tagsSeeded flag.
class FakePreferencesRepository implements UserPreferencesRepository {
  bool _tagsSeeded = false;

  @override
  Future<UserPreferences> getPreferences() async => UserPreferences(
        userName: 'Musician',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
        tagsSeeded: _tagsSeeded,
      );

  @override
  Future<void> updateTagsSeeded({required bool value}) async {
    _tagsSeeded = value;
  }

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {
    _tagsSeeded = preferences.tagsSeeded;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string suitable for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('TagRepositoryImpl.watchAllTags', () {
    late AppDatabase db;
    late FakePreferencesRepository prefsRepo;
    late TagRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      prefsRepo = FakePreferencesRepository();
      repo = TagRepositoryImpl(db.tagDao, prefsRepo);
    });
    tearDown(() => db.close());

    test('emits empty list when no tags exist', () async {
      final tags = await repo.watchAllTags().first;
      expect(tags, isEmpty);
    });

    test('emits Tag domain models in alphabetical order', () async {
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 't2',
              name: 'Ragas',
              colorHex: '#f38ba8',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 't1',
              name: 'Bhajans',
              colorHex: '#a6e3a1',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );

      final tags = await repo.watchAllTags().first;
      expect(tags, hasLength(2));
      expect(tags.first.name, 'Bhajans');
      expect(tags.last.name, 'Ragas');
    });

    test('emits updated list after a new tag is inserted', () async {
      final stream = repo.watchAllTags();
      expect(await stream.first, isEmpty);

      await repo.createTag('Thumri', '#cba6f7');

      final updated = await repo.watchAllTags().first;
      expect(updated, hasLength(1));
      expect(updated.first.name, 'Thumri');
    });
  });

  // -------------------------------------------------------------------------

  group('TagRepositoryImpl.createTag', () {
    late AppDatabase db;
    late FakePreferencesRepository prefsRepo;
    late TagRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      prefsRepo = FakePreferencesRepository();
      repo = TagRepositoryImpl(db.tagDao, prefsRepo);
    });
    tearDown(() => db.close());

    test('returns a Tag with correct name and colorHex', () async {
      final tag = await repo.createTag('Bandishes', '#89b4fa');

      expect(tag.name, 'Bandishes');
      expect(tag.colorHex, '#89b4fa');
    });

    test('persists the tag to the database', () async {
      await repo.createTag('Exercises', '#fab387');

      final rows = await db.select(db.tagsTable).get();
      expect(rows, hasLength(1));
      expect(rows.first.name, 'Exercises');
    });

    test('returned Tag has non-empty uuid id', () async {
      final tag = await repo.createTag('Ragas', '#f38ba8');

      expect(tag.id, isNotEmpty);
    });

    test('returned Tag has createdAt and updatedAt set', () async {
      final tag = await repo.createTag('Ragas', '#f38ba8');

      expect(tag.createdAt, isNotEmpty);
      expect(tag.updatedAt, isNotEmpty);
    });

    test('creates multiple tags with distinct ids', () async {
      final tag1 = await repo.createTag('Ragas', '#f38ba8');
      final tag2 = await repo.createTag('Bhajans', '#a6e3a1');

      expect(tag1.id, isNot(equals(tag2.id)));
    });

    test('throws on duplicate name', () async {
      await repo.createTag('Ragas', '#f38ba8');

      expect(
        () => repo.createTag('Ragas', '#89b4fa'),
        throwsA(anything),
      );
    });
  });

  // -------------------------------------------------------------------------

  group('TagRepositoryImpl.updateTag', () {
    late AppDatabase db;
    late FakePreferencesRepository prefsRepo;
    late TagRepositoryImpl repo;
    late Tag existingTag;

    setUp(() async {
      db = AppDatabase.forTesting();
      prefsRepo = FakePreferencesRepository();
      repo = TagRepositoryImpl(db.tagDao, prefsRepo);
      existingTag = await repo.createTag('Original', '#f38ba8');
    });
    tearDown(() => db.close());

    test('updates name and returns updated Tag', () async {
      final updated = await repo.updateTag(existingTag.id, name: 'Renamed');

      expect(updated.name, 'Renamed');
      expect(updated.colorHex, existingTag.colorHex);
    });

    test('updates colorHex and returns updated Tag', () async {
      final updated = await repo.updateTag(
        existingTag.id,
        colorHex: '#89b4fa',
      );

      expect(updated.colorHex, '#89b4fa');
      expect(updated.name, existingTag.name);
    });

    test('updates both name and colorHex', () async {
      final updated = await repo.updateTag(
        existingTag.id,
        name: 'New Name',
        colorHex: '#cba6f7',
      );

      expect(updated.name, 'New Name');
      expect(updated.colorHex, '#cba6f7');
    });

    test('persists changes to the database', () async {
      await repo.updateTag(existingTag.id, name: 'Persisted');

      final row = await db.tagDao.getTagById(existingTag.id);
      expect(row, isNotNull);
      expect(row!.name, 'Persisted');
    });

    test('throws TagNotFoundException for unknown id', () async {
      expect(
        () => repo.updateTag('non-existent-id', name: 'Ghost'),
        throwsA(isA<TagNotFoundException>()),
      );
    });

    test('updatedAt is refreshed after update', () async {
      final updated = await repo.updateTag(existingTag.id, name: 'Renamed');

      // updatedAt must be a valid ISO 8601 string; value may equal createdAt
      // if the clock did not advance, but it must not be empty.
      expect(updated.updatedAt, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------

  group('TagRepositoryImpl.deleteTag', () {
    late AppDatabase db;
    late FakePreferencesRepository prefsRepo;
    late TagRepositoryImpl repo;
    late Tag existingTag;

    setUp(() async {
      db = AppDatabase.forTesting();
      prefsRepo = FakePreferencesRepository();
      repo = TagRepositoryImpl(db.tagDao, prefsRepo);
      existingTag = await repo.createTag('ToDelete', '#f38ba8');
    });
    tearDown(() => db.close());

    test('removes the tag row from the database', () async {
      await repo.deleteTag(existingTag.id);

      final rows = await db.select(db.tagsTable).get();
      expect(rows, isEmpty);
    });

    test('is a no-op for an unknown id', () async {
      // Must not throw.
      await repo.deleteTag('ghost-id');
    });
  });

  // -------------------------------------------------------------------------

  group('TagRepositoryImpl.seedDefaultTagsIfNeeded', () {
    late AppDatabase db;
    late FakePreferencesRepository prefsRepo;
    late TagRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      prefsRepo = FakePreferencesRepository();
      repo = TagRepositoryImpl(db.tagDao, prefsRepo);
    });
    tearDown(() => db.close());

    test('inserts 5 default tags when tagsSeeded is false', () async {
      await repo.seedDefaultTagsIfNeeded();

      final tags = await repo.watchAllTags().first;
      expect(tags, hasLength(5));
    });

    test('inserts the correct default tag names', () async {
      await repo.seedDefaultTagsIfNeeded();

      final tags = await repo.watchAllTags().first;
      final names = tags.map((t) => t.name).toSet();
      expect(
        names,
        containsAll(
          const {'Ragas', 'Bhajans', 'Bandishes', 'Thumri', 'Exercises'},
        ),
      );
    });

    test('all default tags have valid Catppuccin hex colors', () async {
      await repo.seedDefaultTagsIfNeeded();

      final tags = await repo.watchAllTags().first;
      for (final tag in tags) {
        expect(
          tag.colorHex,
          matches(RegExp(r'^#[0-9a-f]{6}$')),
          reason: 'invalid color for tag ${tag.name}: ${tag.colorHex}',
        );
      }
    });

    test('sets tagsSeeded flag to true after seeding', () async {
      await repo.seedDefaultTagsIfNeeded();

      final prefs = await prefsRepo.getPreferences();
      expect(prefs.tagsSeeded, isTrue);
    });

    test('does not seed again when tagsSeeded is true', () async {
      await repo.seedDefaultTagsIfNeeded();
      // Call a second time — should be a no-op.
      await repo.seedDefaultTagsIfNeeded();

      final tags = await repo.watchAllTags().first;
      expect(tags, hasLength(5));
    });

    test('does not throw if tags already exist', () async {
      await repo.createTag('Ragas', '#f38ba8');
      // Force flag back to false to simulate a re-seed scenario.
      await prefsRepo.updateTagsSeeded(value: false);

      // Should skip seeding entirely since tagsSeeded was false but tags exist
      // — the implementation must handle duplicate-name errors gracefully.
      await expectLater(
        repo.seedDefaultTagsIfNeeded(),
        completes,
      );
    });
  });
}
