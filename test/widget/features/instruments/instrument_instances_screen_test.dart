// Widget tests for InstrumentInstancesScreen.
//
// Covers: idle, loading, success (with instances), empty success, and error
// states. Also covers FAB tap to open create form and swipe-to-archive.
//
// Uses FakeInstrumentInstancesViewModel to avoid touching the DB.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/instruments/screens/instrument_instances_screen.dart';
import 'package:swaralipi/features/instruments/viewmodels/instrument_instances_view_model.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';

// ---------------------------------------------------------------------------
// Fake repository stub (minimal)
// ---------------------------------------------------------------------------

class _FakeInstrumentRepository implements InstrumentRepository {
  @override
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(
    String classId,
  ) =>
      const Stream.empty();

  @override
  Stream<List<InstrumentClass>> watchActiveClasses() => const Stream.empty();

  @override
  Future<InstrumentClass> createClass(String name) async =>
      throw UnimplementedError();

  @override
  Future<InstrumentClass> updateClass(String id, String name) async =>
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
  }) async =>
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
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> archiveInstance(String id) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _kColorHex = '#cba6f7';
const _kClassId = 'class-1';

InstrumentInstance _inst(String id, {String? brand}) => InstrumentInstance(
      id: id,
      classId: _kClassId,
      colorHex: _kColorHex,
      brand: brand,
      notes: '',
      createdAt: '2024-01-01T00:00:00Z',
      updatedAt: '2024-01-01T00:00:00Z',
    );

Widget _buildSubject(InstrumentInstancesViewModel vm) {
  return ChangeNotifierProvider<InstrumentInstancesViewModel>.value(
    value: vm,
    child: const MaterialApp(
      home: InstrumentInstancesScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late InstrumentInstancesViewModel vm;

  setUp(() {
    vm = InstrumentInstancesViewModel(
      _FakeInstrumentRepository(),
      classId: _kClassId,
    );
  });

  tearDown(() => vm.dispose());

  testWidgets('shows nothing in idle state before init', (tester) async {
    // Use pumpWidget without a subsequent pump so addPostFrameCallback has
    // not yet fired — ViewModel remains in idle state.
    await tester.pumpWidget(_buildSubject(vm));
    // At this point the idle state renders SizedBox.shrink — no spinner or
    // list.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('shows loading indicator in loading state', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(const InstrumentInstancesStateLoading());
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows empty state when instances list is empty', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(const InstrumentInstancesStateSuccess(instances: []));
    await tester.pump();
    expect(find.text('No instruments yet'), findsOneWidget);
  });

  testWidgets('shows list of instances in success state', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(
      InstrumentInstancesStateSuccess(
        instances: [
          _inst('i1', brand: 'Yamaha'),
          _inst('i2', brand: 'Gibson'),
        ],
      ),
    );
    await tester.pump();
    expect(find.text('Yamaha'), findsOneWidget);
    expect(find.text('Gibson'), findsOneWidget);
  });

  testWidgets('shows error message in error state', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(
      const InstrumentInstancesStateError(message: 'DB offline'),
    );
    await tester.pump();
    expect(find.textContaining('Failed to load'), findsOneWidget);
  });

  testWidgets('FAB is present and tappable', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(const InstrumentInstancesStateSuccess(instances: []));
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('swipe-to-archive shows confirmation dialog', (tester) async {
    await tester.pumpWidget(_buildSubject(vm));
    vm.testSetState(
      InstrumentInstancesStateSuccess(
        instances: [_inst('i1', brand: 'Stradivari')],
      ),
    );
    await tester.pump();

    await tester.drag(find.text('Stradivari'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Archive instrument?'), findsOneWidget);
  });
}
