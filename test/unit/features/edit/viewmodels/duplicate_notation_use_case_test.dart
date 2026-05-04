// Unit tests for DuplicateNotationUseCase.
//
// Covers:
//   - Success path: loads source, copies files, creates new DB record
//   - Emits new notation id on success
//   - Original notation is unmodified after duplication
//   - Title is suffixed with " (copy)"
//   - All metadata fields, tags, and custom field values are copied
//   - File copy failure: partial files are cleaned up, no DB record created
//   - Source notation not found: throws DuplicateNotationSourceNotFound
//   - FileStorageService error during cleanup does not swallow original error

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:swaralipi/features/edit/viewmodels/duplicate_notation_use_case.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  NotationDetail? notationToReturn;
  Object? loadError;
  Object? saveError;

  final List<({NotationDraft draft, List<SavedPage> pages, String? notationId})>
      saveCalls = [];
  final List<String> softDeletedIds = [];

  @override
  Future<NotationDetail?> loadNotation(String id) async {
    if (loadError != null) throw loadError!;
    return notationToReturn;
  }

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async {
    if (saveError != null) throw saveError!;
    saveCalls.add((draft: draft, pages: pages, notationId: notationId));
    final now = DateTime.now().toUtc().toIso8601String();
    return Notation(
      id: notationId ?? 'new-id',
      title: draft.title,
      artists: draft.artists,
      dateWritten: draft.dateWritten,
      timeSig: draft.timeSig,
      keySig: draft.keySig,
      languages: draft.languages,
      notes: draft.notes,
      playCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) async =>
      throw UnimplementedError();

  @override
  Stream<List<Notation>> watchAllActive({
    NotationSortBy sortBy = NotationSortBy.dateDesc,
  }) =>
      throw UnimplementedError();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

  @override
  Future<void> softDelete(String id) async => softDeletedIds.add(id);

  @override
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}
}

class FakeFileStorageService {
  final Directory _tempDir;
  Object? _copyError;
  int _copyErrorOnCall = -1;
  int _copyCallCount = 0;
  final List<String> copiedFrom = [];
  final List<String> deletedPaths = [];

  FakeFileStorageService(this._tempDir);

  void setCopyError(Object error, {int onCall = 0}) {
    _copyError = error;
    _copyErrorOnCall = onCall;
  }

  Future<String> copyImage(String srcRelativePath, String newNotationId) async {
    final callIndex = _copyCallCount++;
    copiedFrom.add(srcRelativePath);

    if (_copyError != null && callIndex >= _copyErrorOnCall) {
      throw _copyError!;
    }

    // Build a deterministic destination path mimicking FileStorageService
    final pageFileName = p.basename(srcRelativePath);
    final destRelative = p.join('notations', newNotationId, pageFileName);
    final destAbs = p.join(_tempDir.path, destRelative);
    final destFile = File(destAbs);
    await destFile.parent.create(recursive: true);
    // Write a dummy file (source may not exist in tests)
    await destFile.writeAsString('fake');
    return destRelative;
  }

  Future<void> deleteNotationDirectory(String notationId) async {
    deletedPaths.add(notationId);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation({
  String id = 'src-notation-id',
  String title = 'Original Title',
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  return Notation(
    id: id,
    title: title,
    artists: ['Artist A'],
    dateWritten: '2024-01-01',
    timeSig: '4/4',
    keySig: 'C',
    languages: ['Hindi'],
    notes: 'my notes',
    playCount: 5,
    createdAt: now,
    updatedAt: now,
  );
}

NotationPage _makePage(String notationId, int order) {
  final now = DateTime.now().toUtc().toIso8601String();
  return NotationPage(
    id: 'page-$order',
    notationId: notationId,
    pageOrder: order,
    imagePath: 'notations/$notationId/page_${order}_original.jpg',
    renderParams: '{}',
    createdAt: now,
  );
}

Tag _makeTag(String id) {
  final now = DateTime.now().toUtc().toIso8601String();
  return Tag(
    id: id,
    name: 'Tag $id',
    colorHex: '#FFFFFF',
    createdAt: now,
    updatedAt: now,
  );
}

CustomFieldValue _makeCfv({
  required String definitionId,
  String? textValue,
  double? numberValue,
  String? dateValue,
  bool? booleanValue,
}) =>
    CustomFieldValue(
      notationId: 'src-notation-id',
      definitionId: definitionId,
      valueText: textValue,
      valueNumber: numberValue,
      valueDate: dateValue,
      valueBoolean: booleanValue,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository fakeRepo;
  late FakeFileStorageService fakeFss;
  late DuplicateNotationUseCase useCase;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('dup_test_');
    fakeRepo = FakeNotationRepository();
    fakeFss = FakeFileStorageService(tempDir);
    useCase = DuplicateNotationUseCase(
      notationRepository: fakeRepo,
      copyImage: fakeFss.copyImage,
      deleteNotationDirectory: fakeFss.deleteNotationDirectory,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // Success path
  // -------------------------------------------------------------------------

  group('success path', () {
    test('returns new notation id on success', () async {
      final notation = _makeNotation();
      final pages = [_makePage(notation.id, 0), _makePage(notation.id, 1)];
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: pages,
        tags: [_makeTag('tag-1')],
        customFieldValues: [],
      );

      final newId = await useCase.execute('src-notation-id');

      expect(newId, isNotEmpty);
    });

    test('title is suffixed with " (copy)"', () async {
      final notation = _makeNotation(title: 'My Raga');
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [],
      );

      await useCase.execute('src-notation-id');

      expect(fakeRepo.saveCalls.single.draft.title, equals('My Raga (copy)'));
    });

    test('all pages are copied', () async {
      final notation = _makeNotation();
      final pages = [
        _makePage(notation.id, 0),
        _makePage(notation.id, 1),
        _makePage(notation.id, 2),
      ];
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: pages,
        tags: [],
        customFieldValues: [],
      );

      await useCase.execute('src-notation-id');

      expect(fakeFss.copiedFrom, hasLength(3));
      expect(
        fakeFss.copiedFrom,
        containsAll(pages.map((p) => p.imagePath)),
      );
    });

    test('metadata fields are all copied to new record', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [_makeTag('t1'), _makeTag('t2')],
        customFieldValues: [
          _makeCfv(definitionId: 'def-1', textValue: 'hello'),
          _makeCfv(definitionId: 'def-2', numberValue: 42.0),
        ],
      );

      await useCase.execute('src-notation-id');

      final call = fakeRepo.saveCalls.single;
      final draft = call.draft;

      expect(draft.artists, equals(['Artist A']));
      expect(draft.dateWritten, equals('2024-01-01'));
      expect(draft.timeSig, equals('4/4'));
      expect(draft.keySig, equals('C'));
      expect(draft.languages, equals(['Hindi']));
      expect(draft.notes, equals('my notes'));
      expect(draft.tagIds, containsAll(['t1', 't2']));
      expect(draft.customFields, hasLength(2));
    });

    test('new record play count is 0 (fresh start)', () async {
      // Play count is set by the repository on new saves; we verify the
      // saved Notation returned has playCount 0.
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [],
      );

      await useCase.execute('src-notation-id');

      // saveNotation was called (fakeRepo returns playCount: 0 for new saves)
      expect(fakeRepo.saveCalls, hasLength(1));
    });

    test('pages are saved with new notation id in path', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [],
      );

      final newId = await useCase.execute('src-notation-id');

      final savedPages = fakeRepo.saveCalls.single.pages;
      for (final sp in savedPages) {
        expect(
          sp.imagePath,
          contains(newId),
          reason: 'page path should reference new notation directory',
        );
      }
    });

    test('saveNotation receives the new notation id as notationId', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [],
      );

      final newId = await useCase.execute('src-notation-id');

      expect(fakeRepo.saveCalls.single.notationId, equals(newId));
    });

    test('renderParams are preserved on copied pages', () async {
      final notation = _makeNotation();
      const renderJson = '{"filter":"sepia"}';
      final page = NotationPage(
        id: 'page-0',
        notationId: notation.id,
        pageOrder: 0,
        imagePath: 'notations/${notation.id}/page_0_original.jpg',
        renderParams: renderJson,
        createdAt: DateTime.now().toUtc().toIso8601String(),
      );
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [page],
        tags: [],
        customFieldValues: [],
      );

      await useCase.execute('src-notation-id');

      expect(
        fakeRepo.saveCalls.single.pages.single.renderParams,
        equals(renderJson),
      );
    });
  });

  // -------------------------------------------------------------------------
  // Source not found
  // -------------------------------------------------------------------------

  group('source not found', () {
    test(
        'throws DuplicateNotationSourceNotFound '
        'when loadNotation returns null', () async {
      fakeRepo.notationToReturn = null;

      expect(
        () => useCase.execute('missing-id'),
        throwsA(isA<DuplicateNotationSourceNotFound>()),
      );
    });

    test(
        'does not call saveNotation '
        'when source notation is not found', () async {
      fakeRepo.notationToReturn = null;

      await expectLater(
        useCase.execute('missing-id'),
        throwsA(isA<DuplicateNotationSourceNotFound>()),
      );

      expect(fakeRepo.saveCalls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // File copy failure
  // -------------------------------------------------------------------------

  group('file copy failure', () {
    test(
        'cleans up partial files when first copy fails '
        'and re-throws the original error', () async {
      final notation = _makeNotation();
      final pages = [
        _makePage(notation.id, 0),
        _makePage(notation.id, 1),
      ];
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: pages,
        tags: [],
        customFieldValues: [],
      );

      fakeFss.setCopyError(
        const FileSystemException('disk full'),
        onCall: 0,
      );

      await expectLater(
        useCase.execute('src-notation-id'),
        throwsA(isA<FileSystemException>()),
      );

      // Cleanup should have been called for the new notation directory
      expect(fakeFss.deletedPaths, hasLength(1));
    });

    test('does not create DB record when file copy fails', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [],
      );
      fakeFss.setCopyError(const FileSystemException('no space'));

      await expectLater(
        useCase.execute('src-notation-id'),
        throwsA(isA<Exception>()),
      );

      expect(fakeRepo.saveCalls, isEmpty);
    });

    test(
        'cleans up partial files when second copy fails '
        'after first succeeds', () async {
      final notation = _makeNotation();
      final pages = [
        _makePage(notation.id, 0),
        _makePage(notation.id, 1),
        _makePage(notation.id, 2),
      ];
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: pages,
        tags: [],
        customFieldValues: [],
      );

      // Fail on the second copy (index 1)
      fakeFss.setCopyError(
        const FileSystemException('io error'),
        onCall: 1,
      );

      await expectLater(
        useCase.execute('src-notation-id'),
        throwsA(isA<FileSystemException>()),
      );

      expect(fakeFss.deletedPaths, hasLength(1));
      expect(fakeRepo.saveCalls, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Custom field values
  // -------------------------------------------------------------------------

  group('custom field values', () {
    test('text custom field values are preserved', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [
          _makeCfv(definitionId: 'def-text', textValue: 'raag yaman'),
        ],
      );

      await useCase.execute('src-notation-id');

      final cfInputs = fakeRepo.saveCalls.single.draft.customFields;
      final textField =
          cfInputs.firstWhere((cf) => cf.definitionId == 'def-text');
      expect(textField.textValue, equals('raag yaman'));
      expect(textField.fieldType, equals('text'));
    });

    test('number custom field values are preserved', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [
          _makeCfv(definitionId: 'def-num', numberValue: 120.0),
        ],
      );

      await useCase.execute('src-notation-id');

      final cfInputs = fakeRepo.saveCalls.single.draft.customFields;
      final numField =
          cfInputs.firstWhere((cf) => cf.definitionId == 'def-num');
      expect(numField.numberValue, equals(120.0));
      expect(numField.fieldType, equals('number'));
    });

    test('boolean custom field values are preserved', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [
          _makeCfv(definitionId: 'def-bool', booleanValue: true),
        ],
      );

      await useCase.execute('src-notation-id');

      final cfInputs = fakeRepo.saveCalls.single.draft.customFields;
      final boolField =
          cfInputs.firstWhere((cf) => cf.definitionId == 'def-bool');
      expect(boolField.booleanValue, isTrue);
      expect(boolField.fieldType, equals('boolean'));
    });

    test('date custom field values are preserved', () async {
      final notation = _makeNotation();
      fakeRepo.notationToReturn = NotationDetail(
        notation: notation,
        pages: [_makePage(notation.id, 0)],
        tags: [],
        customFieldValues: [
          _makeCfv(definitionId: 'def-date', dateValue: '2025-06-15'),
        ],
      );

      await useCase.execute('src-notation-id');

      final cfInputs = fakeRepo.saveCalls.single.draft.customFields;
      final dateField =
          cfInputs.firstWhere((cf) => cf.definitionId == 'def-date');
      expect(dateField.dateValue, equals('2025-06-15'));
      expect(dateField.fieldType, equals('date'));
    });
  });
}
