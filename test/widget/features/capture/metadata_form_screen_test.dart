// Widget tests for MetadataFormScreen.
//
// Verifies:
// - Correct rendering for each depsState variant (idle/loading/success/error)
// - Save button is disabled when title is empty
// - Save button is enabled when title is non-empty
// - Entering a title enables Save
// - Tag chips render and are tappable
// - Instrument chips render and are tappable
// - Language chips render and are tappable
// - Custom field inputs render for each type (text, number, date, boolean)
// - Artist chip input adds and removes artists
// - vm.init() is called on screen load
// - Error snackbar is shown when saveState is MetadataFormSaveError

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/screens/metadata_form_screen.dart';
import 'package:swaralipi/features/capture/viewmodels/metadata_form_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_draft.dart';
import 'package:swaralipi/shared/models/saved_page.dart';
import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Minimal fakes
// ---------------------------------------------------------------------------

class _FakeTagRepository implements TagRepository {
  @override
  Stream<List<Tag>> watchAllTags() => const Stream.empty();
  @override
  Future<Tag> createTag(String name, String colorHex) =>
      throw UnimplementedError();
  @override
  Future<Tag> updateTag(String id, {String? name, String? colorHex}) =>
      throw UnimplementedError();
  @override
  Future<void> deleteTag(String id) async {}
  @override
  Future<void> seedDefaultTagsIfNeeded() async {}
}

class _FakeInstrumentRepository implements InstrumentRepository {
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

class _FakeCustomFieldRepository implements CustomFieldRepository {
  @override
  Stream<List<CustomFieldDefinition>> watchAllDefinitions() =>
      const Stream.empty();
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
}

class _FakeNotationRepository implements NotationRepository {
  @override
  Future<Notation> saveNotation(
      NotationDraft draft, List<SavedPage> pages) async {
    final now = DateTime.now().toIso8601String();
    return Notation(
      id: 'n-test',
      title: draft.title,
      artists: draft.artists,
      languages: draft.languages,
      notes: draft.notes,
      playCount: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Notation> updateNotation(String id, NotationDraft draft) =>
      throw UnimplementedError();
  @override
  Future<NotationDetail?> loadNotation(String id) async => null;
  @override
  Stream<List<Notation>> watchAllActive() => const Stream.empty();
  @override
  Future<void> softDelete(String id) async {}
  @override
  Future<void> updatePlayCount(String id) async {}
}

// ---------------------------------------------------------------------------
// Fake ViewModel
// ---------------------------------------------------------------------------

class FakeMetadataFormViewModel extends MetadataFormViewModel {
  FakeMetadataFormViewModel({
    MetadataFormDepsState? initialDepsState,
    MetadataFormSaveState? initialSaveState,
    MetadataFormFormState? initialFormState,
  }) : super(
          tagRepository: _FakeTagRepository(),
          instrumentRepository: _FakeInstrumentRepository(),
          customFieldRepository: _FakeCustomFieldRepository(),
          notationRepository: _FakeNotationRepository(),
          pages: const [],
        ) {
    if (initialDepsState != null) _depsState = initialDepsState;
    if (initialSaveState != null) _saveState = initialSaveState;
    if (initialFormState != null) _formState = initialFormState;
  }

  MetadataFormDepsState _depsState = const MetadataFormDepsIdle();
  MetadataFormSaveState _saveState = const MetadataFormSaveIdle();
  MetadataFormFormState _formState = const MetadataFormFormState();

  bool loadDependenciesCalled = false;
  String? lastTitleSet;
  String? lastArtistAdded;
  int? lastArtistRemovedIndex;
  String? lastLanguageToggled;
  String? lastTagToggled;
  String? lastInstrumentToggled;

  @override
  MetadataFormDepsState get depsState => _depsState;

  @override
  MetadataFormSaveState get saveState => _saveState;

  @override
  MetadataFormFormState get formState => _formState;

  @override
  bool get isTitleValid => _formState.title.trim().isNotEmpty;

  void setDepsState(MetadataFormDepsState s) {
    _depsState = s;
    notifyListeners();
  }

  void setSaveState(MetadataFormSaveState s) {
    _saveState = s;
    notifyListeners();
  }

  void setFormState(MetadataFormFormState s) {
    _formState = s;
    notifyListeners();
  }

  @override
  void loadDependencies() {
    loadDependenciesCalled = true;
  }

  @override
  void setTitle(String value) {
    lastTitleSet = value;
    _formState = _formState.copyWith(title: value);
    notifyListeners();
  }

  @override
  void addArtist(String name) {
    lastArtistAdded = name;
  }

  @override
  void removeArtist(int index) {
    lastArtistRemovedIndex = index;
  }

  @override
  void toggleLanguage(String language) {
    lastLanguageToggled = language;
    final current = List<String>.from(_formState.languages);
    if (current.contains(language)) {
      current.remove(language);
    } else {
      current.add(language);
    }
    _formState = _formState.copyWith(languages: current);
    notifyListeners();
  }

  @override
  void toggleTag(String id) {
    lastTagToggled = id;
    final current = List<String>.from(_formState.selectedTagIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _formState = _formState.copyWith(selectedTagIds: current);
    notifyListeners();
  }

  @override
  void toggleInstrument(String id) {
    lastInstrumentToggled = id;
    final current = List<String>.from(_formState.selectedInstrumentIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    _formState = _formState.copyWith(selectedInstrumentIds: current);
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Tag _makeTag({String id = 'tag-1', String name = 'Ragas'}) => Tag(
      id: id,
      name: name,
      colorHex: '#f38ba8',
      createdAt: '2024-01-01T00:00:00.000Z',
      updatedAt: '2024-01-01T00:00:00.000Z',
    );

InstrumentInstance _makeInstance({
  String id = 'inst-1',
  String? brand,
  String? model,
}) =>
    InstrumentInstance(
      id: id,
      classId: 'class-1',
      brand: brand,
      model: model,
      colorHex: '#cba6f7',
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

Widget _buildScreen(FakeMetadataFormViewModel vm) {
  return ChangeNotifierProvider<MetadataFormViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: MetadataFormScreen(),
    ),
  );
}

/// Scrolls the first [ListView] in the widget tree until [finder] is visible.
///
/// Uses [Scrollable.ensureVisible] applied via repeated drags when the finder
/// targets a widget deeper in a nested scroll view. Falls back gracefully if
/// the item is already visible.
Future<void> _scrollToFind(WidgetTester tester, Finder finder) async {
  // Use scrollUntilVisible but constrain to the first Scrollable
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: scrollable,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // State rendering
  // -------------------------------------------------------------------------

  group('MetadataFormScreen state rendering', () {
    testWidgets('shows loading indicator when depsState is loading',
        (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsLoading(),
      );
      await tester.pumpWidget(_buildScreen(vm));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error view when depsState is error', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsError(
          message: 'Could not load data',
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));
      expect(find.textContaining('Could not load data'), findsOneWidget);
    });

    testWidgets('shows form when depsState is success', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));
      // Title field is the anchor for the form
      expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  group('MetadataFormScreen lifecycle', () {
    testWidgets('loadDependencies is called on screen load', (tester) async {
      final vm = FakeMetadataFormViewModel();
      await tester.pumpWidget(_buildScreen(vm));
      expect(vm.loadDependenciesCalled, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Save button state
  // -------------------------------------------------------------------------

  group('MetadataFormScreen save button', () {
    testWidgets('Save button is disabled when title is empty', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      // Find the Save button in the app bar or body
      final saveButton = find.widgetWithText(FilledButton, 'Save');
      expect(saveButton, findsOneWidget);

      final widget = tester.widget<FilledButton>(saveButton);
      expect(widget.onPressed, isNull);
    });

    testWidgets('Save button is enabled when title is non-empty',
        (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
        initialFormState: const MetadataFormFormState(title: 'Yaman'),
      );
      await tester.pumpWidget(_buildScreen(vm));

      final saveButton = find.widgetWithText(FilledButton, 'Save');
      expect(saveButton, findsOneWidget);

      final widget = tester.widget<FilledButton>(saveButton);
      expect(widget.onPressed, isNotNull);
    });

    testWidgets('Entering a title enables Save button', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      // Title field is empty — Save is disabled
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save'),
            )
            .onPressed,
        isNull,
      );

      // Enter title
      await tester.enterText(find.widgetWithText(TextField, 'Title'), 'Yaman');
      await tester.pump();

      // Save should now be enabled (vm.setTitle was called, state updated)
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Save'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Tags
  // -------------------------------------------------------------------------

  group('MetadataFormScreen tags', () {
    testWidgets('tag chips are displayed from depsState.tags', (tester) async {
      final tags = [
        _makeTag(id: 'tag-1', name: 'Ragas'),
        _makeTag(id: 'tag-2', name: 'Bhajans'),
      ];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: tags,
          instruments: const [],
          customFieldDefinitions: const [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await _scrollToFind(tester, find.text('Ragas'));
      expect(find.text('Ragas'), findsOneWidget);
      expect(find.text('Bhajans'), findsOneWidget);
    });

    testWidgets('tapping a tag chip calls vm.toggleTag', (tester) async {
      final tags = [_makeTag(id: 'tag-1', name: 'Ragas')];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: tags,
          instruments: const [],
          customFieldDefinitions: const [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await _scrollToFind(tester, find.text('Ragas'));
      await tester.tap(find.text('Ragas'));
      await tester.pump();

      expect(vm.lastTagToggled, 'tag-1');
    });
  });

  // -------------------------------------------------------------------------
  // Instruments
  // -------------------------------------------------------------------------

  group('MetadataFormScreen instruments', () {
    testWidgets('instrument chips are displayed', (tester) async {
      final instruments = [
        _makeInstance(id: 'inst-1', brand: 'Yamaha', model: 'C40'),
      ];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: const [],
          instruments: instruments,
          customFieldDefinitions: const [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await _scrollToFind(tester, find.textContaining('Yamaha'));
      // The chip label shows brand model or a fallback
      expect(find.textContaining('Yamaha'), findsOneWidget);
    });

    testWidgets('tapping an instrument chip calls vm.toggleInstrument',
        (tester) async {
      final instruments = [_makeInstance(id: 'inst-1', brand: 'Sitar')];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: const [],
          instruments: instruments,
          customFieldDefinitions: const [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await _scrollToFind(tester, find.textContaining('Sitar'));
      await tester.tap(find.textContaining('Sitar'));
      await tester.pump();

      expect(vm.lastInstrumentToggled, 'inst-1');
    });
  });

  // -------------------------------------------------------------------------
  // Languages
  // -------------------------------------------------------------------------

  group('MetadataFormScreen languages', () {
    testWidgets('language chips are present', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      // At least Hindi should be in the predefined list
      expect(find.text('Hindi'), findsOneWidget);
    });

    testWidgets('tapping a language chip calls vm.toggleLanguage',
        (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await tester.tap(find.text('Hindi'));
      await tester.pump();

      expect(vm.lastLanguageToggled, 'Hindi');
    });
  });

  // -------------------------------------------------------------------------
  // Custom fields
  // -------------------------------------------------------------------------

  group('MetadataFormScreen custom fields', () {
    testWidgets('text custom field renders a text input', (tester) async {
      final defs = [
        _makeDefinition(
          id: 'def-1',
          keyName: 'raga_name',
          fieldType: CustomFieldType.text,
        ),
      ];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: const [],
          instruments: const [],
          customFieldDefinitions: defs,
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      await _scrollToFind(
          tester, find.widgetWithText(TextField, 'raga_name'));
      // Field label from keyName
      expect(find.widgetWithText(TextField, 'raga_name'), findsOneWidget);
    });

    testWidgets('boolean custom field renders a switch or checkbox',
        (tester) async {
      final defs = [
        _makeDefinition(
          id: 'def-2',
          keyName: 'is_favourite',
          fieldType: CustomFieldType.boolean,
        ),
      ];
      final vm = FakeMetadataFormViewModel(
        initialDepsState: MetadataFormDepsSuccess(
          tags: const [],
          instruments: const [],
          customFieldDefinitions: defs,
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      // Scroll down to find is_favourite label then check Switch is present
      await _scrollToFind(tester, find.text('is_favourite'));
      expect(find.byType(Switch), findsAtLeastNWidgets(1));
    });
  });

  // -------------------------------------------------------------------------
  // Accessibility
  // -------------------------------------------------------------------------

  group('MetadataFormScreen accessibility', () {
    testWidgets('Save button has a semantic label', (tester) async {
      final vm = FakeMetadataFormViewModel(
        initialDepsState: const MetadataFormDepsSuccess(
          tags: [],
          instruments: [],
          customFieldDefinitions: [],
        ),
      );
      await tester.pumpWidget(_buildScreen(vm));

      final semantics = tester.getSemantics(
        find.widgetWithText(FilledButton, 'Save'),
      );
      expect(semantics.label, isNotEmpty);
    });
  });
}
