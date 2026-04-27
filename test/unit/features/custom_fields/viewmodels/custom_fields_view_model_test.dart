// Unit tests for CustomFieldsViewModel.
//
// Covers state transitions (idle → loading → success/error) and CRUD
// operations against a FakeCustomFieldRepository.
//
// Naming convention:
//   <method> — <scenario> → <expected outcome>

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/custom_fields/viewmodels/custom_fields_view_model.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeCustomFieldRepository implements CustomFieldRepository {
  final _defs = <String, CustomFieldDefinition>{};
  final _controller =
      StreamController<List<CustomFieldDefinition>>.broadcast();

  Object? watchError;
  Object? createError;
  Object? updateError;
  Object? deleteError;

  void _emit() => _controller.add(List.unmodifiable(_defs.values.toList()));

  @override
  Stream<List<CustomFieldDefinition>> watchAllDefinitions() {
    if (watchError != null) {
      return Stream.error(watchError!);
    }
    return _controller.stream;
  }

  @override
  Future<CustomFieldDefinition> createDefinition(
    String keyName,
    String fieldType,
  ) async {
    if (createError != null) throw createError!;
    final def = CustomFieldDefinition(
      id: 'fake-${_defs.length}',
      keyName: keyName,
      fieldType: CustomFieldType.values
          .firstWhere((e) => e.name == fieldType),
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );
    _defs[def.id] = def;
    _emit();
    return def;
  }

  @override
  Future<CustomFieldDefinition> updateDefinition(
    String id, {
    String? keyName,
    String? fieldType,
  }) async {
    if (updateError != null) throw updateError!;
    final existing = _defs[id];
    if (existing == null) throw CustomFieldNotFoundException(id);
    final updated = existing.copyWith(
      keyName: keyName,
      fieldType: fieldType != null
          ? CustomFieldType.values.firstWhere((e) => e.name == fieldType)
          : null,
    );
    _defs[id] = updated;
    _emit();
    return updated;
  }

  @override
  Future<void> deleteDefinition(String id) async {
    if (deleteError != null) throw deleteError!;
    _defs.remove(id);
    _emit();
  }

  void seedDef(CustomFieldDefinition def) {
    _defs[def.id] = def;
    _emit();
  }

  Future<void> close() => _controller.close();
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

CustomFieldDefinition _makeDef(String id, String key) =>
    CustomFieldDefinition(
      id: id,
      keyName: key,
      fieldType: CustomFieldType.text,
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CustomFieldsViewModel.init', () {
    late FakeCustomFieldRepository repo;
    late CustomFieldsViewModel vm;

    setUp(() {
      repo = FakeCustomFieldRepository();
      vm = CustomFieldsViewModel(repo);
    });
    tearDown(() async {
      vm.dispose();
      await repo.close();
    });

    test('state starts as CustomFieldsStateIdle', () {
      expect(vm.state, isA<CustomFieldsStateIdle>());
    });

    test('transitions to loading immediately after init', () {
      final states = <CustomFieldsState>[];
      vm.addListener(() => states.add(vm.state));
      vm.init();
      expect(states.first, isA<CustomFieldsStateLoading>());
    });

    test('transitions to success when stream emits a list', () async {
      vm.init();
      repo.seedDef(_makeDef('1', 'raga'));
      await Future<void>.delayed(Duration.zero);
      expect(vm.state, isA<CustomFieldsStateSuccess>());
      final state = vm.state as CustomFieldsStateSuccess;
      expect(state.definitions, hasLength(1));
    });

    test('transitions to error when stream emits an error', () async {
      repo.watchError = Exception('db failure');
      vm.init();
      await Future<void>.delayed(Duration.zero);
      expect(vm.state, isA<CustomFieldsStateError>());
    });
  });

  // -------------------------------------------------------------------------

  group('CustomFieldsViewModel.createDefinition', () {
    late FakeCustomFieldRepository repo;
    late CustomFieldsViewModel vm;

    setUp(() async {
      repo = FakeCustomFieldRepository();
      vm = CustomFieldsViewModel(repo);
      vm.init();
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      vm.dispose();
      await repo.close();
    });

    test('returns definition on success and createError is null', () async {
      final def = await vm.createDefinition('tempo', 'number');
      expect(def, isNotNull);
      expect(def!.keyName, 'tempo');
      expect(vm.createError, isNull);
    });

    test('sets createError and returns null on failure', () async {
      repo.createError = Exception('constraint violation');
      final def = await vm.createDefinition('tempo', 'number');
      expect(def, isNull);
      expect(vm.createError, isNotNull);
    });

    test('clearCreateError resets createError to null', () async {
      repo.createError = Exception('error');
      await vm.createDefinition('x', 'text');
      vm.clearCreateError();
      expect(vm.createError, isNull);
    });
  });

  // -------------------------------------------------------------------------

  group('CustomFieldsViewModel.updateDefinition', () {
    late FakeCustomFieldRepository repo;
    late CustomFieldsViewModel vm;
    late CustomFieldDefinition existing;

    setUp(() async {
      repo = FakeCustomFieldRepository();
      vm = CustomFieldsViewModel(repo);
      vm.init();
      existing = await repo.createDefinition('original', 'text');
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      vm.dispose();
      await repo.close();
    });

    test('returns updated definition on success', () async {
      final updated = await vm.updateDefinition(
        existing.id,
        keyName: 'renamed',
      );
      expect(updated, isNotNull);
      expect(updated!.keyName, 'renamed');
      expect(vm.updateError, isNull);
    });

    test('sets updateError and returns null on failure', () async {
      repo.updateError = Exception('db error');
      final result = await vm.updateDefinition(existing.id, keyName: 'x');
      expect(result, isNull);
      expect(vm.updateError, isNotNull);
    });

    test('clearUpdateError resets updateError to null', () async {
      repo.updateError = Exception('error');
      await vm.updateDefinition(existing.id, keyName: 'x');
      vm.clearUpdateError();
      expect(vm.updateError, isNull);
    });
  });

  // -------------------------------------------------------------------------

  group('CustomFieldsViewModel.deleteDefinition', () {
    late FakeCustomFieldRepository repo;
    late CustomFieldsViewModel vm;
    late CustomFieldDefinition existing;

    setUp(() async {
      repo = FakeCustomFieldRepository();
      vm = CustomFieldsViewModel(repo);
      vm.init();
      existing = await repo.createDefinition('to_delete', 'text');
      await Future<void>.delayed(Duration.zero);
    });
    tearDown(() async {
      vm.dispose();
      await repo.close();
    });

    test('deletes successfully and deleteError is null', () async {
      await vm.deleteDefinition(existing.id);
      expect(vm.deleteError, isNull);
    });

    test('sets deleteError on failure', () async {
      repo.deleteError = Exception('db error');
      await vm.deleteDefinition(existing.id);
      expect(vm.deleteError, isNotNull);
    });

    test('clearDeleteError resets deleteError to null', () async {
      repo.deleteError = Exception('error');
      await vm.deleteDefinition(existing.id);
      vm.clearDeleteError();
      expect(vm.deleteError, isNull);
    });
  });
}
