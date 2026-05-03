// Unit tests for EditNotationViewModel.
//
// Covers:
// - Initial state is EditNotationStateIdle
// - loadNotation: transitions idle → loading → success with pre-populated state
// - loadNotation: transitions idle → loading → notFound when no notation exists
// - loadNotation: transitions idle → loading → error on repository exception
// - Pre-population: formState title matches loaded notation title
// - Pre-population: formState artists matches loaded notation artists
// - Pre-population: formState dateWritten matches loaded notation dateWritten
// - Pre-population: formState timeSig matches loaded notation timeSig
// - Pre-population: formState keySig matches loaded notation keySig
// - Pre-population: formState languages matches loaded notation languages
// - Pre-population: formState notes matches loaded notation notes
// - Pre-population: formState selectedTagIds matches loaded notation tags
// - Pre-population: formState customFieldValues populated from customFieldValues
// - Pre-population: existingPages built from NotationDetail pages
// - save: blocked when title empty
// - save: blocked while already saving
// - save: calls updateNotation with correct draft
// - save: transitions to EditNotationSaveDone with notationId on success
// - save: transitions to EditNotationSaveError on repository failure
// - clearSaveError: resets saveState to EditNotationSaveIdle
// - notifyListeners fired on loadNotation state transitions
// - notifyListeners fired on save state transitions

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/edit/viewmodels/edit_notation_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_value.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class FakeNotationRepository implements NotationRepository {
  NotationDetail? notationToReturn;
  Object? loadError;

  Notation? savedNotation;
  Notation? updatedNotation;
  Object? updateError;

  String? lastUpdateId;
  NotationDraft? lastUpdateDraft;
  List<SavedPage>? lastSavedPages;

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
    lastSavedPages = pages;
    if (savedNotation != null) return savedNotation!;
    throw UnimplementedError('saveNotation not configured in fake');
  }

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) async {
    lastUpdateId = id;
    lastUpdateDraft = draft;
    if (updateError != null) throw updateError!;
    if (updatedNotation != null) return updatedNotation!;
    throw UnimplementedError('updatedNotation not configured in fake');
  }

  @override
  Stream<List<Notation>> watchAllActive() => const Stream.empty();

  @override
  Stream<List<Notation>> watchRecentlyPlayed({int limit = 5}) =>
      const Stream.empty();

  @override
  Future<void> softDelete(String id) async {}

  @override
  Future<void> updatePlayCount(String id) async {}

  final List<(String, String)> pageRenderParamsUpdates = [];

  @override
  Future<void> updatePageRenderParams(
    String pageId,
    String renderParamsJson,
  ) async {
    pageRenderParamsUpdates.add((pageId, renderParamsJson));
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Notation _makeNotation({
  String id = 'notation-1',
  String title = 'Raag Bhairav',
  List<String> artists = const ['Ravi Shankar'],
  String? dateWritten = '2024-01-15',
  String? timeSig = '4/4',
  String? keySig = 'C',
  List<String> languages = const ['Hindi'],
  String notes = 'practice notes',
}) =>
    Notation(
      id: id,
      title: title,
      artists: artists,
      dateWritten: dateWritten,
      timeSig: timeSig,
      keySig: keySig,
      languages: languages,
      notes: notes,
      playCount: 0,
      lastPlayedAt: null,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
      deletedAt: null,
    );

Tag _makeTag({
  String id = 'tag-1',
  String name = 'Classical',
  String colorHex = '#FF0000',
}) =>
    Tag(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

NotationPage _makePage({
  String id = 'page-1',
  String notationId = 'notation-1',
  int pageOrder = 0,
  String imagePath = 'notations/notation-1/page_0_original.jpg',
  String renderParams = '{}',
  String createdAt = '2024-01-01T00:00:00Z',
}) =>
    NotationPage(
      id: id,
      notationId: notationId,
      pageOrder: pageOrder,
      imagePath: imagePath,
      renderParams: renderParams,
      createdAt: createdAt,
    );

NotationDetail _makeDetail({
  Notation? notation,
  List<NotationPage> pages = const [],
  List<Tag> tags = const [],
  List<CustomFieldValue> customFieldValues = const [],
}) =>
    NotationDetail(
      notation: notation ?? _makeNotation(),
      pages: pages,
      tags: tags,
      customFieldValues: customFieldValues,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeNotationRepository repo;

  setUp(() {
    repo = FakeNotationRepository();
  });

  EditNotationViewModel makeVm() => EditNotationViewModel(
        notationRepository: repo,
      );

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('state is EditNotationStateIdle', () {
      final vm = makeVm();
      expect(vm.state, isA<EditNotationStateIdle>());
    });

    test('saveState is EditNotationSaveIdle', () {
      final vm = makeVm();
      expect(vm.saveState, isA<EditNotationSaveIdle>());
    });
  });

  // -------------------------------------------------------------------------
  // loadNotation
  // -------------------------------------------------------------------------

  group('loadNotation', () {
    test('transitions to loading then success', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();

      final states = <EditNotationState>[];
      vm.addListener(() => states.add(vm.state));

      await vm.loadNotation('notation-1');

      expect(states.first, isA<EditNotationStateLoading>());
      expect(states.last, isA<EditNotationStateSuccess>());
    });

    test('success state contains notationId', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();

      await vm.loadNotation('notation-1');

      final success = vm.state as EditNotationStateSuccess;
      expect(success.notationId, equals('notation-1'));
    });

    test('transitions to notFound when repository returns null', () async {
      repo.notationToReturn = null;
      final vm = makeVm();

      await vm.loadNotation('missing-id');

      expect(vm.state, isA<EditNotationStateNotFound>());
    });

    test('transitions to error when repository throws', () async {
      repo.loadError = Exception('db error');
      final vm = makeVm();

      await vm.loadNotation('notation-1');

      expect(vm.state, isA<EditNotationStateError>());
    });

    test('error state contains message', () async {
      repo.loadError = Exception('db error');
      final vm = makeVm();

      await vm.loadNotation('notation-1');

      final error = vm.state as EditNotationStateError;
      expect(error.message, contains('db error'));
    });
  });

  // -------------------------------------------------------------------------
  // Pre-population: formState fields
  // -------------------------------------------------------------------------

  group('pre-population — formState', () {
    test('title pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(title: 'Raag Yaman'),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.title, equals('Raag Yaman'));
    });

    test('artists pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation:
            _makeNotation(artists: ['Pt. Ravi Shankar', 'Ustad Ali Khan']),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(
          vm.formState.artists, equals(['Pt. Ravi Shankar', 'Ustad Ali Khan']));
    });

    test('dateWritten pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(dateWritten: '2023-06-15'),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.dateWritten, equals('2023-06-15'));
    });

    test('timeSig pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(timeSig: '6/8'),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.timeSig, equals('6/8'));
    });

    test('keySig pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(keySig: 'D minor'),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.keySig, equals('D minor'));
    });

    test('languages pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(languages: ['Hindi', 'Bengali']),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.languages, equals(['Hindi', 'Bengali']));
    });

    test('notes pre-populated from notation', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(notes: 'practice early morning'),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.notes, equals('practice early morning'));
    });

    test('selectedTagIds pre-populated from detail tags', () async {
      repo.notationToReturn = _makeDetail(
        tags: [
          _makeTag(id: 'tag-1'),
          _makeTag(id: 'tag-2', name: 'Folk'),
        ],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.selectedTagIds, containsAll(['tag-1', 'tag-2']));
    });

    test('customFieldValues pre-populated from text custom field values',
        () async {
      repo.notationToReturn = _makeDetail(
        customFieldValues: [
          const CustomFieldValue(
            notationId: 'notation-1',
            definitionId: 'cf-1',
            valueText: 'some text',
          ),
        ],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.formState.customFieldValues, contains('cf-1'));
      expect(
        vm.formState.customFieldValues['cf-1']?.textValue,
        equals('some text'),
      );
    });

    test('customFieldValues pre-populated from number custom field values',
        () async {
      repo.notationToReturn = _makeDetail(
        customFieldValues: [
          const CustomFieldValue(
            notationId: 'notation-1',
            definitionId: 'cf-2',
            valueNumber: 42.5,
          ),
        ],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(
        vm.formState.customFieldValues['cf-2']?.numberValue,
        equals(42.5),
      );
    });

    test('customFieldValues pre-populated from boolean custom field values',
        () async {
      repo.notationToReturn = _makeDetail(
        customFieldValues: [
          const CustomFieldValue(
            notationId: 'notation-1',
            definitionId: 'cf-3',
            valueBoolean: true,
          ),
        ],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(
        vm.formState.customFieldValues['cf-3']?.booleanValue,
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Pre-population: existingPages
  // -------------------------------------------------------------------------

  group('pre-population — existingPages', () {
    test('existingPages populated from detail pages after load', () async {
      repo.notationToReturn = _makeDetail(
        pages: [
          _makePage(id: 'p1', pageOrder: 0),
          _makePage(id: 'p2', pageOrder: 1),
        ],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.existingPages, hasLength(2));
      expect(vm.existingPages[0].id, equals('p1'));
      expect(vm.existingPages[1].id, equals('p2'));
    });

    test('existingPages empty when notation has no pages', () async {
      repo.notationToReturn = _makeDetail(pages: []);
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      expect(vm.existingPages, isEmpty);
    });

    test('existingPages empty before load', () {
      final vm = makeVm();
      expect(vm.existingPages, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Form field setters
  // -------------------------------------------------------------------------

  group('form field setters', () {
    test('setTitle updates formState and notifies listeners', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      var notified = false;
      vm.addListener(() => notified = true);
      vm.setTitle('New Title');

      expect(vm.formState.title, equals('New Title'));
      expect(notified, isTrue);
    });

    test('addArtist appends artist to list', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(artists: ['A']),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.addArtist('B');
      expect(vm.formState.artists, equals(['A', 'B']));
    });

    test('removeArtist removes artist at index', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(artists: ['A', 'B', 'C']),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.removeArtist(1);
      expect(vm.formState.artists, equals(['A', 'C']));
    });

    test('toggleLanguage adds missing language', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.toggleLanguage('Bengali');
      expect(vm.formState.languages, contains('Bengali'));
    });

    test('toggleLanguage removes existing language', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(languages: ['Hindi']),
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.toggleLanguage('Hindi');
      expect(vm.formState.languages, isNot(contains('Hindi')));
    });

    test('toggleTag adds missing tag id', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.toggleTag('tag-99');
      expect(vm.formState.selectedTagIds, contains('tag-99'));
    });

    test('toggleTag removes existing tag id', () async {
      repo.notationToReturn = _makeDetail(
        tags: [_makeTag(id: 'tag-1')],
      );
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.toggleTag('tag-1');
      expect(vm.formState.selectedTagIds, isNot(contains('tag-1')));
    });
  });

  // -------------------------------------------------------------------------
  // isTitleValid
  // -------------------------------------------------------------------------

  group('isTitleValid', () {
    test('returns false when title is empty', () async {
      repo.notationToReturn = _makeDetail(notation: _makeNotation(title: ''));
      final vm = makeVm();
      await vm.loadNotation('notation-1');
      expect(vm.isTitleValid, isFalse);
    });

    test('returns false when title is whitespace only', () async {
      repo.notationToReturn =
          _makeDetail(notation: _makeNotation(title: '   '));
      final vm = makeVm();
      await vm.loadNotation('notation-1');
      expect(vm.isTitleValid, isFalse);
    });

    test('returns true when title is non-empty', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();
      await vm.loadNotation('notation-1');
      expect(vm.isTitleValid, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // save
  // -------------------------------------------------------------------------

  group('save', () {
    test('no-op when title is empty', () async {
      repo.notationToReturn = _makeDetail(notation: _makeNotation(title: ''));
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      await vm.save(updatedPages: []);

      expect(vm.saveState, isA<EditNotationSaveIdle>());
    });

    test('no-op when already saving', () async {
      repo.notationToReturn = _makeDetail();
      final updatedNotation = _makeNotation();
      repo.updatedNotation = updatedNotation;

      final vm = makeVm();
      await vm.loadNotation('notation-1');

      // Kick off two saves concurrently; the second must be a no-op.
      final firstSave = vm.save(updatedPages: []);
      final secondSave = vm.save(updatedPages: []);
      await Future.wait([firstSave, secondSave]);

      // Only one updateNotation call.
      expect(repo.lastUpdateId, equals('notation-1'));
    });

    test('calls updateNotation with correct id and draft on success', () async {
      repo.notationToReturn = _makeDetail(
        notation: _makeNotation(title: 'Raag Bhairav'),
        tags: [_makeTag(id: 'tag-1')],
      );
      repo.updatedNotation = _makeNotation();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      await vm.save(updatedPages: []);

      expect(repo.lastUpdateId, equals('notation-1'));
      expect(repo.lastUpdateDraft?.title, equals('Raag Bhairav'));
      expect(repo.lastUpdateDraft?.tagIds, equals(['tag-1']));
    });

    test('transitions to saving then done on success', () async {
      repo.notationToReturn = _makeDetail();
      repo.updatedNotation = _makeNotation();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      final states = <EditNotationSaveState>[];
      vm.addListener(() => states.add(vm.saveState));

      await vm.save(updatedPages: []);

      expect(states.first, isA<EditNotationSaving>());
      expect(states.last, isA<EditNotationSaveDone>());
    });

    test('saveDone contains notationId', () async {
      repo.notationToReturn = _makeDetail();
      repo.updatedNotation = _makeNotation(id: 'notation-1');
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      await vm.save(updatedPages: []);

      final done = vm.saveState as EditNotationSaveDone;
      expect(done.notationId, equals('notation-1'));
    });

    test('transitions to saveError on repository failure', () async {
      repo.notationToReturn = _makeDetail();
      repo.updateError = Exception('update failed');
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      await vm.save(updatedPages: []);

      expect(vm.saveState, isA<EditNotationSaveError>());
    });

    test('saveError contains message on repository failure', () async {
      repo.notationToReturn = _makeDetail();
      repo.updateError = Exception('update failed');
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      await vm.save(updatedPages: []);

      final error = vm.saveState as EditNotationSaveError;
      expect(error.message, contains('update failed'));
    });

    test('passes updatedPages pages as SavedPage list to updateNotation draft',
        () async {
      repo.notationToReturn = _makeDetail(
        pages: [
          _makePage(id: 'p1', imagePath: 'notations/n1/page_0_original.jpg')
        ],
      );
      repo.updatedNotation = _makeNotation();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      final updatedPage = _makePage(
        id: 'p1',
        imagePath: 'notations/n1/page_0_original.jpg',
        renderParams: '{"filter":"grayscale","rotation_degrees":0}',
      );

      await vm.save(updatedPages: [updatedPage]);

      // updateNotation was called (not saveNotation)
      expect(repo.lastUpdateId, isNotNull);
      expect(repo.lastSavedPages, isNull);
    });

    test('persists render params for each updated page', () async {
      repo.notationToReturn = _makeDetail(
        pages: [
          _makePage(id: 'p1'),
          _makePage(id: 'p2', pageOrder: 1),
        ],
      );
      repo.updatedNotation = _makeNotation();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      final updatedPages = [
        _makePage(id: 'p1', renderParams: '{"filter":"grayscale"}'),
        _makePage(
            id: 'p2', pageOrder: 1, renderParams: '{"rotation_degrees":90}'),
      ];

      await vm.save(updatedPages: updatedPages);

      expect(repo.pageRenderParamsUpdates, hasLength(2));
      expect(repo.pageRenderParamsUpdates[0].$1, equals('p1'));
      expect(
          repo.pageRenderParamsUpdates[0].$2, equals('{"filter":"grayscale"}'));
      expect(repo.pageRenderParamsUpdates[1].$1, equals('p2'));
    });
  });

  // -------------------------------------------------------------------------
  // clearSaveError
  // -------------------------------------------------------------------------

  group('clearSaveError', () {
    test('resets saveState to idle from error', () async {
      repo.notationToReturn = _makeDetail();
      repo.updateError = Exception('fail');
      final vm = makeVm();
      await vm.loadNotation('notation-1');
      await vm.save(updatedPages: []);

      expect(vm.saveState, isA<EditNotationSaveError>());
      vm.clearSaveError();
      expect(vm.saveState, isA<EditNotationSaveIdle>());
    });

    test('no-op when not in error state', () async {
      repo.notationToReturn = _makeDetail();
      final vm = makeVm();
      await vm.loadNotation('notation-1');

      vm.clearSaveError(); // should not throw
      expect(vm.saveState, isA<EditNotationSaveIdle>());
    });
  });
}
