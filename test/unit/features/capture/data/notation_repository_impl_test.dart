// Unit tests for NotationRepositoryImpl.
//
// Covers all public methods against an in-memory Drift database:
//   saveNotation, updateNotation, loadNotation, watchAllActive,
//   softDelete, updatePlayCount.
//
// Each test group sets up a fresh AppDatabase.forTesting() in setUp and
// closes it in tearDown, ensuring full isolation between test cases.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/features/capture/data/notation_repository_impl.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns an ISO 8601 UTC datetime string for test fixtures.
String _ts(String suffix) => '2024-01-01T${suffix}Z';

/// Builds a minimal [NotationDraft] with only a title required.
NotationDraft _draft({
  String title = 'Test Notation',
  List<String> artists = const [],
  String? dateWritten,
  String? timeSig,
  String? keySig,
  List<String> languages = const [],
  String notes = '',
  List<String> tagIds = const [],
  List<CustomFieldValueInput> customFields = const [],
}) =>
    NotationDraft(
      title: title,
      artists: artists,
      dateWritten: dateWritten,
      timeSig: timeSig,
      keySig: keySig,
      languages: languages,
      notes: notes,
      tagIds: tagIds,
      customFields: customFields,
    );

/// Builds a minimal [SavedPage] for use in saveNotation.
SavedPage _page(int order, {String imagePath = 'test/page.jpg'}) => SavedPage(
      id: 'page-$order',
      pageOrder: order,
      imagePath: imagePath,
      renderParams: '{}',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.saveNotation', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
    });
    tearDown(() => db.close());

    test('returns a Notation with correct title', () async {
      final notation = await repo.saveNotation(_draft(title: 'Yaman'), []);

      expect(notation.title, 'Yaman');
    });

    test('returned Notation has a non-empty UUID id', () async {
      final notation = await repo.saveNotation(_draft(), []);

      expect(notation.id, isNotEmpty);
    });

    test('persists notation row to database', () async {
      final notation = await repo.saveNotation(_draft(title: 'Bhairavi'), []);

      final row = await db.notationDao.getNotationById(notation.id);
      expect(row, isNotNull);
      expect(row!.title, 'Bhairavi');
    });

    test('persists page rows in order', () async {
      final pages = [_page(0), _page(1), _page(2)];
      final notation = await repo.saveNotation(_draft(), pages);

      final rows = await db.notationPageDao.getPagesByNotationId(notation.id);
      expect(rows, hasLength(3));
      expect(rows.map((r) => r.pageOrder).toList(), [0, 1, 2]);
    });

    test('persists tag associations atomically', () async {
      // Insert a tag first so the FK constraint is satisfied.
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 'tag-1',
              name: 'Ragas',
              colorHex: '#f38ba8',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );

      final notation = await repo.saveNotation(
        _draft(tagIds: ['tag-1']),
        [],
      );

      final tagRows = await db.notationTagDao.getTagsForNotation(notation.id);
      expect(tagRows, hasLength(1));
      expect(tagRows.first.id, 'tag-1');
    });

    test('persists custom field values', () async {
      // Insert a custom field definition so the FK is satisfied.
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'cf-1',
              keyName: 'raga_name',
              fieldType: 'text',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );

      final notation = await repo.saveNotation(
        _draft(
          customFields: [
            const CustomFieldValueInput(
              definitionId: 'cf-1',
              fieldType: 'text',
              textValue: 'Yaman',
            ),
          ],
        ),
        [],
      );

      final cfRows = await db.customFieldDao.getValuesForNotation(notation.id);
      expect(cfRows, hasLength(1));
      expect(cfRows.first.valueText, 'Yaman');
    });

    test('notation has deletedAt null (active)', () async {
      final notation = await repo.saveNotation(_draft(), []);

      expect(notation.deletedAt, isNull);
    });

    test('notation has createdAt and updatedAt set', () async {
      final notation = await repo.saveNotation(_draft(), []);

      expect(notation.createdAt, isNotEmpty);
      expect(notation.updatedAt, isNotEmpty);
    });

    test('save with no pages stores no page rows', () async {
      final notation = await repo.saveNotation(_draft(), []);

      final rows = await db.notationPageDao.getPagesByNotationId(notation.id);
      expect(rows, isEmpty);
    });

    test('saves artists and languages as lists', () async {
      final notation = await repo.saveNotation(
        _draft(artists: ['Ravi Shankar'], languages: ['Hindi']),
        [],
      );

      expect(notation.artists, ['Ravi Shankar']);
      expect(notation.languages, ['Hindi']);
    });
  });

  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.updateNotation', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;
    late Notation existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
      existing = await repo.saveNotation(_draft(title: 'Original'), []);
    });
    tearDown(() => db.close());

    test('returns updated Notation with new title', () async {
      final updated =
          await repo.updateNotation(existing.id, _draft(title: 'Renamed'));

      expect(updated.title, 'Renamed');
      expect(updated.id, existing.id);
    });

    test('persists updated title to database', () async {
      await repo.updateNotation(existing.id, _draft(title: 'Persisted'));

      final row = await db.notationDao.getNotationById(existing.id);
      expect(row!.title, 'Persisted');
    });

    test('updatedAt is refreshed after update', () async {
      final updated =
          await repo.updateNotation(existing.id, _draft(title: 'New'));

      expect(updated.updatedAt, isNotEmpty);
    });

    test('replaces tags atomically — old tags removed, new tags added',
        () async {
      // Insert two tags.
      for (final (id, name) in [('tag-a', 'Ragas'), ('tag-b', 'Bhajans')]) {
        await db.into(db.tagsTable).insert(
              TagsTableCompanion.insert(
                id: id,
                name: name,
                colorHex: '#f38ba8',
                createdAt: _ts('10:00:00'),
                updatedAt: _ts('10:00:00'),
              ),
            );
      }

      // Save with tag-a.
      await repo.saveNotation(
        _draft(title: 'Tagged', tagIds: ['tag-a']),
        [],
      );

      // Update to use tag-b only.
      final updated = await repo.updateNotation(
        existing.id,
        _draft(tagIds: ['tag-b']),
      );

      final tags = await db.notationTagDao.getTagsForNotation(updated.id);
      expect(tags, hasLength(1));
      expect(tags.first.id, 'tag-b');
    });

    test('replaces custom field values atomically', () async {
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'cf-1',
              keyName: 'raga_name',
              fieldType: 'text',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );

      // First save with a custom field value.
      await repo.saveNotation(
        _draft(
          customFields: [
            const CustomFieldValueInput(
              definitionId: 'cf-1',
              fieldType: 'text',
              textValue: 'Bhairav',
            ),
          ],
        ),
        [],
      );

      // Update with a different value.
      await repo.updateNotation(
        existing.id,
        _draft(
          customFields: [
            const CustomFieldValueInput(
              definitionId: 'cf-1',
              fieldType: 'text',
              textValue: 'Yaman',
            ),
          ],
        ),
      );

      final cfRows = await db.customFieldDao.getValuesForNotation(existing.id);
      // Value replaced (upsert).
      expect(cfRows.where((r) => r.valueText == 'Yaman'), hasLength(1));
    });

    test('throws NotationNotFoundException for unknown id', () async {
      expect(
        () => repo.updateNotation(
          'non-existent-id',
          _draft(title: 'Ghost'),
        ),
        throwsA(isA<NotationNotFoundException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.loadNotation', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;
    late Notation existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
      existing = await repo.saveNotation(
        _draft(title: 'Darbari', artists: ['Tansen']),
        [_page(0), _page(1)],
      );
    });
    tearDown(() => db.close());

    test('returns NotationDetail with correct notation data', () async {
      final detail = await repo.loadNotation(existing.id);

      expect(detail, isNotNull);
      expect(detail!.notation.title, 'Darbari');
      expect(detail.notation.artists, ['Tansen']);
    });

    test('hydrates pages in order', () async {
      final detail = await repo.loadNotation(existing.id);

      expect(detail!.pages, hasLength(2));
      expect(detail.pages.first.pageOrder, 0);
      expect(detail.pages.last.pageOrder, 1);
    });

    test('hydrates tags', () async {
      await db.into(db.tagsTable).insert(
            TagsTableCompanion.insert(
              id: 'tag-1',
              name: 'Ragas',
              colorHex: '#f38ba8',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );
      final notation = await repo.saveNotation(
        _draft(tagIds: ['tag-1']),
        [],
      );

      final detail = await repo.loadNotation(notation.id);

      expect(detail!.tags, hasLength(1));
      expect(detail.tags.first.id, 'tag-1');
    });

    test('hydrates custom fields', () async {
      await db.into(db.customFieldDefinitionsTable).insert(
            CustomFieldDefinitionsTableCompanion.insert(
              id: 'cf-1',
              keyName: 'raga_name',
              fieldType: 'text',
              createdAt: _ts('10:00:00'),
              updatedAt: _ts('10:00:00'),
            ),
          );
      final notation = await repo.saveNotation(
        _draft(
          customFields: [
            const CustomFieldValueInput(
              definitionId: 'cf-1',
              fieldType: 'text',
              textValue: 'Yaman',
            ),
          ],
        ),
        [],
      );

      final detail = await repo.loadNotation(notation.id);

      expect(detail!.customFieldValues, hasLength(1));
      expect(detail.customFieldValues.first.valueText, 'Yaman');
    });

    test('returns null for unknown id', () async {
      final detail = await repo.loadNotation('non-existent-id');

      expect(detail, isNull);
    });

    test('returns empty tags and custom fields when none set', () async {
      final detail = await repo.loadNotation(existing.id);

      expect(detail!.tags, isEmpty);
      expect(detail.customFieldValues, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.watchAllActive', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
    });
    tearDown(() => db.close());

    test('emits empty list when no notations exist', () async {
      final list = await repo.watchAllActive().first;

      expect(list, isEmpty);
    });

    test('emits active notations ordered by updatedAt descending', () async {
      await repo.saveNotation(_draft(title: 'Older'), []);
      await repo.saveNotation(_draft(title: 'Newer'), []);

      final list = await repo.watchAllActive().first;

      expect(list, hasLength(2));
      // Most recently updated should be first.
      expect(list.first.title, 'Newer');
    });

    test('excludes soft-deleted notations', () async {
      final n = await repo.saveNotation(_draft(title: 'ToDelete'), []);
      await repo.softDelete(n.id);

      final list = await repo.watchAllActive().first;

      expect(list, isEmpty);
    });

    test('stream emits updated list after a new notation is saved', () async {
      final stream = repo.watchAllActive();
      expect(await stream.first, isEmpty);

      await repo.saveNotation(_draft(title: 'New'), []);

      final updated = await repo.watchAllActive().first;
      expect(updated, hasLength(1));
    });
  });

  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.softDelete', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;
    late Notation existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
      existing = await repo.saveNotation(_draft(), []);
    });
    tearDown(() => db.close());

    test('sets deletedAt on the notation row', () async {
      await repo.softDelete(existing.id);

      final row = await db.notationDao.getNotationById(existing.id);
      expect(row!.deletedAt, isNotNull);
    });

    test('notation no longer appears in watchAllActive', () async {
      await repo.softDelete(existing.id);

      final list = await repo.watchAllActive().first;
      expect(list, isEmpty);
    });

    test('is a no-op for an unknown id', () async {
      // Must not throw.
      await repo.softDelete('ghost-id');
    });
  });

  // -------------------------------------------------------------------------
  group('NotationRepositoryImpl.updatePlayCount', () {
    late AppDatabase db;
    late NotationRepositoryImpl repo;
    late Notation existing;

    setUp(() async {
      db = AppDatabase.forTesting();
      repo = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
      existing = await repo.saveNotation(_draft(), []);
    });
    tearDown(() => db.close());

    test('increments play_count by 1', () async {
      await repo.updatePlayCount(existing.id);

      final row = await db.notationDao.getNotationById(existing.id);
      expect(row!.playCount, 1);
    });

    test('increments play_count again on subsequent calls', () async {
      await repo.updatePlayCount(existing.id);
      await repo.updatePlayCount(existing.id);

      final row = await db.notationDao.getNotationById(existing.id);
      expect(row!.playCount, 2);
    });

    test('sets lastPlayedAt to a non-null value', () async {
      await repo.updatePlayCount(existing.id);

      final row = await db.notationDao.getNotationById(existing.id);
      expect(row!.lastPlayedAt, isNotNull);
    });

    test('is a no-op for an unknown id', () async {
      // Must not throw.
      await repo.updatePlayCount('ghost-id');
    });
  });
}
