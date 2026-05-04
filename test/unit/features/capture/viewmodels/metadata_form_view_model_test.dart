// Unit tests for MetadataFormViewModel.
//
// Covers:
// - Initial state has correct default values
// - Field update methods produce immutable state copies
// - Title validation: empty title is invalid, non-empty is valid
// - Artists chip management: add, remove, blank-ignored
// - Language management: toggle on/off
// - Tag selection: toggle on/off
// - Instrument selection: toggle on/off
// - Custom field value updates
// - loadDependencies: loading -> success / loading -> error transitions
// - save: blocked when title empty
// - save: blocked while already saving
// - save: calls FileStorageService.saveImage for each draft
// - save: delegates to NotationRepository.saveNotation on success
// - save: passes the same notationId to file storage and repository
// - save: rolls back written files on FileStorageService failure
// - save: transitions to error state on repository failure
// - notifyListeners called on mutation

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/metadata_form_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/render_params.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/core/database/daos/notation_dao.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeTagRepository implements TagRepository {
  final _controller = StreamController<List<Tag>>.broadcast();

  void emitTags(List<Tag> tags) => _controller.add(tags);
  void emitError(Object e) => _controller.addError(e);

  @override
  Stream<List<Tag>> watchAllTags() => _controller.stream;

  @override
  Future<Tag> createTag(String name, String colorHex) async =>
      _makeTag(name: name, colorHex: colorHex);

  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) async =>
      _makeTag(id: id, name: name ?? 'tag', colorHex: colorHex ?? '#aabbcc');

  @override
  Future<void> deleteTag(String id) async {}

  @override
  Future<void> seedDefaultTagsIfNeeded() async {}

  void closeStream() => _controller.close();
}

class FakeInstrumentRepository implements InstrumentRepository {
  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
          String classId) =>
      const Stream.empty();

  @override
  Stream<List<InstrumentClass>> watchActiveClasses() => const Stream.empty();

  @override
  Future<InstrumentClass> createClass(String name) =>
      throw UnimplementedError();

  @override
  Future<InstrumentClass> updateClass(String id, String name) =>
      throw UnimplementedError();

  @override
  Future<void> archiveClass(String id) async {}

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

class FakeCustomFieldRepository implements CustomFieldRepository {
  final _controller = StreamController<List<CustomFieldDefinition>>.broadcast();

  void emitDefinitions(List<CustomFieldDefinition> defs) =>
      _controller.add(defs);
  void emitError(Object e) => _controller.addError(e);

  @override
  Stream<List<CustomFieldDefinition>> watchAllDefinitions() =>
      _controller.stream;

  @override
  Future<CustomFieldDefinition> createDefinition(
          String keyName, String fieldType) =>
      throw UnimplementedError();

  @override
  Future<CustomFieldDefinition> updateDefinition(String id,
          {String? keyName, String? fieldType}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDefinition(String id) async {}

  void closeStream() => _controller.close();
}

class FakeNotationRepository implements NotationRepository {
  Notation? lastSavedNotation;
  NotationDraft? lastSavedDraft;
  List<SavedPage>? lastSavedPages;
  Object? saveError;
  int callCount = 0;

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async {
    callCount++;
    if (saveError != null) throw saveError!;
    lastSavedDraft = draft;
    lastSavedPages = pages;
    final now = DateTime.now().toIso8601String();
    lastSavedNotation = Notation(
      id: notationId ?? 'n-test',
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
    return lastSavedNotation!;
  }

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) =>
      throw UnimplementedError();

  @override
  Future<NotationDetail?> loadNotation(String id) async => null;

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
  Future<void> updatePlayCount(String id) async {}

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {}
}

// Slow repo for concurrency test
class _SlowFakeNotationRepository extends FakeNotationRepository {
  _SlowFakeNotationRepository(this._slowFuture);
  final Future<Notation> _slowFuture;

  @override
  Future<Notation> saveNotation(
    NotationDraft draft,
    List<SavedPage> pages, {
    String? notationId,
  }) async {
    callCount++;
    return _slowFuture;
  }
}

/// Fake [FileStorageService] that records calls and optionally throws.
///
/// [savedPaths] collects the relative paths returned by [saveImage].
/// [deletedPaths] collects the paths passed to [deletePageFile].
/// Set [saveError] to an [Exception] to simulate a write failure on
/// the next [saveImage] call.
class FakeFileStorageService extends FileStorageService {
  FakeFileStorageService() : super();

  final List<String> savedPaths = [];
  final List<String> deletedPaths = [];

  /// When non-null, the next [saveImage] call throws this exception.
  Exception? saveError;

  /// Counter tracking how many times [saveImage] was called.
  int saveCallCount = 0;

  @override
  Future<String> saveImage(
    Uint8List bytes,
    String notationId,
    int pageIndex,
  ) async {
    saveCallCount++;
    if (saveError != null) throw saveError!;
    final path = 'notations/$notationId/page_${pageIndex}_original.jpg';
    savedPaths.add(path);
    return path;
  }

  @override
  Future<void> deletePageFile(String relativePath) async {
    deletedPaths.add(relativePath);
  }
}

/// [FileStorageService] fake that succeeds on the first [failAfter] calls and
/// then throws on the next call to simulate a mid-write failure.
class _FailingAfterNFileStorageService extends FileStorageService {
  _FailingAfterNFileStorageService({required this.failAfter}) : super();

  final int failAfter;
  int _callCount = 0;
  final List<String> savedPaths = [];
  final List<String> deletedPaths = [];

  @override
  Future<String> saveImage(
    Uint8List bytes,
    String notationId,
    int pageIndex,
  ) async {
    _callCount++;
    if (_callCount > failAfter) {
      throw Exception('Simulated write failure at call $_callCount');
    }
    final path = 'notations/$notationId/page_${pageIndex}_original.jpg';
    savedPaths.add(path);
    return path;
  }

  @override
  Future<void> deletePageFile(String relativePath) async {
    deletedPaths.add(relativePath);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [CapturePageDraft] with empty bytes for use in tests.
CapturePageDraft _makeDraft({String path = 'img/page_0.jpg'}) =>
    CapturePageDraft(
      originalPath: path,
      originalBytes: Uint8List(0),
      renderParams: RenderParams.identity,
    );

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

InstrumentInstance _makeInstance({
  String id = 'inst-1',
  String classId = 'class-1',
  String colorHex = '#cba6f7',
}) =>
    InstrumentInstance(
      id: id,
      classId: classId,
      colorHex: colorHex,
      notes: '',
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );

CustomFieldDefinition _makeDefinition({
  String id = 'def-1',
  String keyName = 'raga_name',
  CustomFieldType fieldType = CustomFieldType.text,
}) =>
    CustomFieldDefinition(
      id: id,
      keyName: keyName,
      fieldType: fieldType,
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );

MetadataFormViewModel _buildVm({
  FakeTagRepository? tagRepo,
  FakeInstrumentRepository? instrumentRepo,
  FakeCustomFieldRepository? customFieldRepo,
  FakeNotationRepository? notationRepo,
  FileStorageService? fileStorage,
  List<CapturePageDraft> drafts = const [],
  Stream<List<InstrumentInstance>>? allInstancesStream,
}) {
  return MetadataFormViewModel(
    tagRepository: tagRepo ?? FakeTagRepository(),
    instrumentRepository: instrumentRepo ?? FakeInstrumentRepository(),
    customFieldRepository: customFieldRepo ?? FakeCustomFieldRepository(),
    notationRepository: notationRepo ?? FakeNotationRepository(),
    fileStorageService: fileStorage ?? FakeFileStorageService(),
    drafts: drafts,
    allInstancesStream: allInstancesStream,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel initial state', () {
    test('formState.title is empty', () {
      expect(_buildVm().formState.title, isEmpty);
    });

    test('formState.artists is empty', () {
      expect(_buildVm().formState.artists, isEmpty);
    });

    test('formState.dateWritten is null', () {
      expect(_buildVm().formState.dateWritten, isNull);
    });

    test('formState.timeSig is null', () {
      expect(_buildVm().formState.timeSig, isNull);
    });

    test('formState.keySig is null', () {
      expect(_buildVm().formState.keySig, isNull);
    });

    test('formState.languages is empty', () {
      expect(_buildVm().formState.languages, isEmpty);
    });

    test('formState.notes is empty', () {
      expect(_buildVm().formState.notes, isEmpty);
    });

    test('formState.selectedTagIds is empty', () {
      expect(_buildVm().formState.selectedTagIds, isEmpty);
    });

    test('formState.selectedInstrumentIds is empty', () {
      expect(_buildVm().formState.selectedInstrumentIds, isEmpty);
    });

    test('formState.customFieldValues is empty', () {
      expect(_buildVm().formState.customFieldValues, isEmpty);
    });

    test('depsState is MetadataFormDepsIdle', () {
      expect(_buildVm().depsState, isA<MetadataFormDepsIdle>());
    });

    test('saveState is MetadataFormSaveIdle', () {
      expect(_buildVm().saveState, isA<MetadataFormSaveIdle>());
    });
  });

  // -------------------------------------------------------------------------
  // Title validation
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel title validation', () {
    test('isTitleValid is false when title is empty', () {
      expect(_buildVm().isTitleValid, isFalse);
    });

    test('isTitleValid is true when title is non-empty', () {
      final vm = _buildVm();
      vm.setTitle('Yaman');
      expect(vm.isTitleValid, isTrue);
    });

    test('isTitleValid is false when title is only whitespace', () {
      final vm = _buildVm();
      vm.setTitle('   ');
      expect(vm.isTitleValid, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Field setters
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel field setters', () {
    test('setTitle updates formState.title', () {
      final vm = _buildVm();
      vm.setTitle('Bhairavi');
      expect(vm.formState.title, 'Bhairavi');
    });

    test('setDateWritten updates formState.dateWritten', () {
      final vm = _buildVm();
      vm.setDateWritten('2024-03-15');
      expect(vm.formState.dateWritten, '2024-03-15');
    });

    test('setTimeSig updates formState.timeSig', () {
      final vm = _buildVm();
      vm.setTimeSig('4/4');
      expect(vm.formState.timeSig, '4/4');
    });

    test('setKeySig updates formState.keySig', () {
      final vm = _buildVm();
      vm.setKeySig('C major');
      expect(vm.formState.keySig, 'C major');
    });

    test('setNotes updates formState.notes', () {
      final vm = _buildVm();
      vm.setNotes('Evening raga');
      expect(vm.formState.notes, 'Evening raga');
    });
  });

  // -------------------------------------------------------------------------
  // Artists chip management
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel artists', () {
    test('addArtist appends a name', () {
      final vm = _buildVm();
      vm.addArtist('Vilayat Khan');
      expect(vm.formState.artists, ['Vilayat Khan']);
    });

    test('addArtist trims whitespace', () {
      final vm = _buildVm();
      vm.addArtist('  Ravi Shankar  ');
      expect(vm.formState.artists, ['Ravi Shankar']);
    });

    test('addArtist ignores blank entries', () {
      final vm = _buildVm();
      vm.addArtist('   ');
      expect(vm.formState.artists, isEmpty);
    });

    test('removeArtist removes by index', () {
      final vm = _buildVm();
      vm.addArtist('A');
      vm.addArtist('B');
      vm.removeArtist(0);
      expect(vm.formState.artists, ['B']);
    });

    test('artists list is a new instance after mutation (immutable)', () {
      final vm = _buildVm();
      vm.addArtist('A');
      final first = vm.formState.artists;
      vm.addArtist('B');
      expect(identical(first, vm.formState.artists), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Language management
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel languages', () {
    test('toggleLanguage adds a language when absent', () {
      final vm = _buildVm();
      vm.toggleLanguage('Hindi');
      expect(vm.formState.languages, contains('Hindi'));
    });

    test('toggleLanguage removes a language when present', () {
      final vm = _buildVm();
      vm.toggleLanguage('Hindi');
      vm.toggleLanguage('Hindi');
      expect(vm.formState.languages, isNot(contains('Hindi')));
    });
  });

  // -------------------------------------------------------------------------
  // Tag selection
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel tag selection', () {
    test('toggleTag adds id when absent', () {
      final vm = _buildVm();
      vm.toggleTag('tag-1');
      expect(vm.formState.selectedTagIds, contains('tag-1'));
    });

    test('toggleTag removes id when present', () {
      final vm = _buildVm();
      vm.toggleTag('tag-1');
      vm.toggleTag('tag-1');
      expect(vm.formState.selectedTagIds, isNot(contains('tag-1')));
    });
  });

  // -------------------------------------------------------------------------
  // Instrument selection
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel instrument selection', () {
    test('toggleInstrument adds id when absent', () {
      final vm = _buildVm();
      vm.toggleInstrument('inst-1');
      expect(vm.formState.selectedInstrumentIds, contains('inst-1'));
    });

    test('toggleInstrument removes id when present', () {
      final vm = _buildVm();
      vm.toggleInstrument('inst-1');
      vm.toggleInstrument('inst-1');
      expect(vm.formState.selectedInstrumentIds, isNot(contains('inst-1')));
    });
  });

  // -------------------------------------------------------------------------
  // Custom field values
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel custom field values', () {
    test('setCustomFieldText stores text value', () {
      final vm = _buildVm();
      vm.setCustomFieldText('def-1', 'Yaman');
      expect(vm.formState.customFieldValues['def-1']?.textValue, 'Yaman');
    });

    test('setCustomFieldNumber stores number value', () {
      final vm = _buildVm();
      vm.setCustomFieldNumber('def-2', 3.14);
      expect(vm.formState.customFieldValues['def-2']?.numberValue, 3.14);
    });

    test('setCustomFieldDate stores date value', () {
      final vm = _buildVm();
      vm.setCustomFieldDate('def-3', '2024-01-01');
      expect(vm.formState.customFieldValues['def-3']?.dateValue, '2024-01-01');
    });

    test('setCustomFieldBoolean stores boolean value', () {
      final vm = _buildVm();
      vm.setCustomFieldBoolean('def-4', value: true);
      expect(vm.formState.customFieldValues['def-4']?.booleanValue, isTrue);
    });

    test('second set replaces first', () {
      final vm = _buildVm();
      vm.setCustomFieldText('def-1', 'Old');
      vm.setCustomFieldText('def-1', 'New');
      expect(vm.formState.customFieldValues['def-1']?.textValue, 'New');
    });
  });

  // -------------------------------------------------------------------------
  // loadDependencies
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel loadDependencies', () {
    test('transitions to loading immediately', () {
      final vm = _buildVm();
      vm.loadDependencies();
      expect(vm.depsState, isA<MetadataFormDepsLoading>());
    });

    test('transitions to success when all three streams emit', () async {
      final tagRepo = FakeTagRepository();
      final cfRepo = FakeCustomFieldRepository();
      final instrController =
          StreamController<List<InstrumentInstance>>.broadcast();
      final vm = _buildVm(
        tagRepo: tagRepo,
        customFieldRepo: cfRepo,
        allInstancesStream: instrController.stream,
      );

      vm.loadDependencies();

      tagRepo.emitTags([_makeTag()]);
      instrController.add([_makeInstance()]);
      cfRepo.emitDefinitions([_makeDefinition()]);

      await Future<void>.delayed(Duration.zero);

      expect(vm.depsState, isA<MetadataFormDepsSuccess>());
      final success = vm.depsState as MetadataFormDepsSuccess;
      expect(success.tags.length, 1);
      expect(success.instruments.length, 1);
      expect(success.customFieldDefinitions.length, 1);

      await instrController.close();
    });

    test('stays loading when only one stream has emitted', () async {
      final tagRepo = FakeTagRepository();
      final cfRepo = FakeCustomFieldRepository();
      final instrController =
          StreamController<List<InstrumentInstance>>.broadcast();
      final vm = _buildVm(
        tagRepo: tagRepo,
        customFieldRepo: cfRepo,
        allInstancesStream: instrController.stream,
      );

      vm.loadDependencies();
      tagRepo.emitTags([]);

      await Future<void>.delayed(Duration.zero);

      expect(vm.depsState, isA<MetadataFormDepsLoading>());
      await instrController.close();
    });

    test('transitions to error when tag stream emits an error', () async {
      final tagRepo = FakeTagRepository();
      final cfRepo = FakeCustomFieldRepository();
      final instrController =
          StreamController<List<InstrumentInstance>>.broadcast();
      final vm = _buildVm(
        tagRepo: tagRepo,
        customFieldRepo: cfRepo,
        allInstancesStream: instrController.stream,
      );

      vm.loadDependencies();
      tagRepo.emitError(Exception('DB failure'));

      await Future<void>.delayed(Duration.zero);

      expect(vm.depsState, isA<MetadataFormDepsError>());
      await instrController.close();
    });
  });

  // -------------------------------------------------------------------------
  // save
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel save', () {
    test('save does nothing when title is empty', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);

      await vm.save();

      expect(notationRepo.callCount, 0);
      expect(vm.saveState, isA<MetadataFormSaveIdle>());
    });

    test('save transitions to done on success', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Yaman');

      await vm.save();

      expect(vm.saveState, isA<MetadataFormSaveDone>());
    });

    test('save passes title in the draft', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Bhairavi');

      await vm.save();

      expect(notationRepo.lastSavedDraft?.title, 'Bhairavi');
    });

    test('save passes artists in the draft', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Test');
      vm.addArtist('Ravi Shankar');

      await vm.save();

      expect(notationRepo.lastSavedDraft?.artists, ['Ravi Shankar']);
    });

    test('save passes dateWritten in the draft', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Test');
      vm.setDateWritten('2024-06-01');

      await vm.save();

      expect(notationRepo.lastSavedDraft?.dateWritten, '2024-06-01');
    });

    test('save passes languages in the draft', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Test');
      vm.toggleLanguage('Hindi');

      await vm.save();

      expect(notationRepo.lastSavedDraft?.languages, contains('Hindi'));
    });

    test('save passes selected tag ids in the draft', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Test');
      vm.toggleTag('tag-abc');

      await vm.save();

      expect(notationRepo.lastSavedDraft?.tagIds, contains('tag-abc'));
    });

    test('save writes each draft to file storage', () async {
      final storage = FakeFileStorageService();
      final vm = _buildVm(
        fileStorage: storage,
        drafts: [
          _makeDraft(path: 'img/p0.jpg'),
          _makeDraft(path: 'img/p1.jpg')
        ],
      );
      vm.setTitle('Test');

      await vm.save();

      expect(storage.saveCallCount, 2);
    });

    test('save passes pages list to repository', () async {
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(
        notationRepo: notationRepo,
        drafts: [_makeDraft()],
      );
      vm.setTitle('Test');

      await vm.save();

      expect(notationRepo.lastSavedPages?.length, 1);
    });

    test('save transitions to error on repository failure', () async {
      final notationRepo = FakeNotationRepository()
        ..saveError = Exception('Write error');
      final vm = _buildVm(notationRepo: notationRepo);
      vm.setTitle('Yaman');

      await vm.save();

      expect(vm.saveState, isA<MetadataFormSaveError>());
    });

    test('save rolls back written files on FileStorageService failure',
        () async {
      // Fail on the second saveImage call; the first file has already been
      // written and must be rolled back.
      final failingStorage = _FailingAfterNFileStorageService(failAfter: 1);
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(
        fileStorage: failingStorage,
        notationRepo: notationRepo,
        drafts: [
          _makeDraft(path: 'img/p0.jpg'),
          _makeDraft(path: 'img/p1.jpg'),
        ],
      );
      vm.setTitle('Yaman');

      await vm.save();

      expect(vm.saveState, isA<MetadataFormSaveError>());
      // One file was written before the failure; it must be rolled back.
      expect(failingStorage.deletedPaths, hasLength(1));
      // Repository must NOT be called when file writes fail.
      expect(notationRepo.callCount, 0);
    });

    test('save passes the same notationId to file storage and repository',
        () async {
      final storage = FakeFileStorageService();
      final notationRepo = FakeNotationRepository();
      final vm = _buildVm(
        fileStorage: storage,
        notationRepo: notationRepo,
        drafts: [_makeDraft()],
      );
      vm.setTitle('Yaman');

      await vm.save();

      // The notationId embedded in the saved path must match the id used
      // for the notation row.
      final savedPath = storage.savedPaths.first;
      final notationId = (vm.saveState as MetadataFormSaveDone).notationId;
      expect(savedPath, contains(notationId));
    });

    test('save does not call repository again while saving', () async {
      final completer = Completer<Notation>();
      final slowRepo = _SlowFakeNotationRepository(completer.future);
      final vm = _buildVm(notationRepo: slowRepo);
      vm.setTitle('Test');

      unawaited(vm.save());
      // Second call while first is in-flight — should be ignored
      await vm.save();

      const result = Notation(
        id: 'n1',
        title: 'Test',
        artists: [],
        languages: [],
        notes: '',
        playCount: 0,
        createdAt: '2024-01-01T00:00:00.000Z',
        updatedAt: '2024-01-01T00:00:00.000Z',
      );
      completer.complete(result);
      await Future<void>.delayed(Duration.zero);

      expect(slowRepo.callCount, 1);
    });
  });

  // -------------------------------------------------------------------------
  // notifyListeners
  // -------------------------------------------------------------------------

  group('MetadataFormViewModel notifyListeners', () {
    test('setTitle calls notifyListeners once', () {
      final vm = _buildVm();
      var count = 0;
      vm.addListener(() => count++);

      vm.setTitle('New Title');

      expect(count, 1);
    });

    test('toggleTag calls notifyListeners once', () {
      final vm = _buildVm();
      var count = 0;
      vm.addListener(() => count++);

      vm.toggleTag('tag-1');

      expect(count, 1);
    });

    test('addArtist calls notifyListeners once', () {
      final vm = _buildVm();
      var count = 0;
      vm.addListener(() => count++);

      vm.addArtist('Zakir Hussain');

      expect(count, 1);
    });
  });
}
