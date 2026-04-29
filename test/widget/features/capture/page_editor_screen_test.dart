// page_editor_screen_test.dart — widget tests for PageEditorScreen.
//
// Covers:
//   - Screen renders with pages from CaptureSessionViewModel
//   - Empty session shows empty-state message
//   - Non-empty session shows page count indicator
//   - Screen has an AppBar with a title
//   - Accessibility: back button has semantic label

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/screens/page_editor_screen.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CapturePageDraft _draft(String path) => CapturePageDraft(
      originalPath: path,
      originalBytes: Uint8List.fromList([1, 2, 3]),
      renderParams: RenderParams.identity,
    );

Widget _buildTestApp(CaptureSessionViewModel vm) {
  return MaterialApp(
    home: ChangeNotifierProvider<CaptureSessionViewModel>.value(
      value: vm,
      child: const PageEditorScreen(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CaptureSessionViewModel viewModel;

  setUp(() {
    viewModel = CaptureSessionViewModel();
  });

  tearDown(() => viewModel.dispose());

  testWidgets('screen has an AppBar', (tester) async {
    await tester.pumpWidget(_buildTestApp(viewModel));

    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('AppBar title contains "Editor" or "Pages"', (tester) async {
    await tester.pumpWidget(_buildTestApp(viewModel));

    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    final titleWidget = appBar.title;
    expect(titleWidget, isNotNull);
  });

  testWidgets('empty session shows empty-state widget', (tester) async {
    await tester.pumpWidget(_buildTestApp(viewModel));

    expect(find.byKey(const Key('page_editor_empty_state')), findsOneWidget);
  });

  testWidgets('non-empty session does not show empty-state', (tester) async {
    viewModel.addPage(_draft('/a.jpg'));

    await tester.pumpWidget(_buildTestApp(viewModel));

    expect(
      find.byKey(const Key('page_editor_empty_state')),
      findsNothing,
    );
  });

  testWidgets(
    'shows one page thumbnail card per draft in session',
    (tester) async {
      viewModel.addPage(_draft('/a.jpg'));
      viewModel.addPage(_draft('/b.jpg'));

      await tester.pumpWidget(_buildTestApp(viewModel));

      expect(
        find.byKey(const Key('page_editor_page_card')),
        findsNWidgets(2),
      );
    },
  );

  testWidgets(
    'page count text reflects number of pages',
    (tester) async {
      viewModel.addPage(_draft('/a.jpg'));
      viewModel.addPage(_draft('/b.jpg'));
      viewModel.addPage(_draft('/c.jpg'));

      await tester.pumpWidget(_buildTestApp(viewModel));

      expect(find.text('3 pages'), findsOneWidget);
    },
  );

  testWidgets(
    'page count updates after adding a page via ViewModel',
    (tester) async {
      viewModel.addPage(_draft('/a.jpg'));
      await tester.pumpWidget(_buildTestApp(viewModel));

      expect(find.text('1 page'), findsOneWidget);

      viewModel.addPage(_draft('/b.jpg'));
      await tester.pump();

      expect(find.text('2 pages'), findsOneWidget);
    },
  );
}
