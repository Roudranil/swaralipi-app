// page_editor_filters_panel_test.dart — widget tests for Task 2: animated
// Filters side panel in PageEditorScreen.
//
// Covers:
//   - Filter chip row is no longer rendered inline
//   - Filters icon button is present in the toolbar
//   - Tapping Filters button toggles the side panel open
//   - Panel is collapsed by default
//   - Tapping a filter option applies the filter and collapses the panel
//   - Tapping the image preview area collapses the panel

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/screens/page_editor_screen.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/features/capture/viewmodels/page_editor_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CapturePageDraft _draft(String path) => CapturePageDraft(
      originalPath: path,
      originalBytes: Uint8List.fromList([1, 2, 3]),
      renderParams: RenderParams.identity,
    );

Widget _buildTestApp({
  required CaptureSessionViewModel session,
  required PageEditorViewModel editorVm,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<CaptureSessionViewModel>.value(value: session),
        ChangeNotifierProvider<PageEditorViewModel>.value(value: editorVm),
      ],
      child: PageEditorScreen(onNext: (_) {}),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CaptureSessionViewModel session;
  late PageEditorViewModel editorVm;

  setUp(() {
    session = CaptureSessionViewModel();
    editorVm = PageEditorViewModel(session: session);
  });

  tearDown(() {
    editorVm.dispose();
    session.dispose();
  });

  group('Filters side panel', () {
    testWidgets('inline filter chip row is not rendered', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      expect(
        find.byKey(const Key('page_editor_filter_chips')),
        findsNothing,
      );
    });

    testWidgets('Filters icon button is present in toolbar', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      expect(
        find.byKey(const Key('page_editor_filters_button')),
        findsOneWidget,
      );
    });

    testWidgets('filter panel is collapsed by default', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      expect(
        find.byKey(const Key('page_editor_filter_panel')),
        findsNothing,
      );
    });

    testWidgets('tapping Filters button opens the side panel', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      await tester.tap(find.byKey(const Key('page_editor_filters_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('page_editor_filter_panel')),
        findsOneWidget,
      );
    });

    testWidgets(
        'tapping Filters button again collapses the panel', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      // Open
      await tester.tap(find.byKey(const Key('page_editor_filters_button')));
      await tester.pumpAndSettle();

      // Close
      await tester.tap(find.byKey(const Key('page_editor_filters_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('page_editor_filter_panel')),
        findsNothing,
      );
    });

    testWidgets('tapping a filter in panel applies it and collapses panel',
        (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      await tester.tap(find.byKey(const Key('page_editor_filters_button')));
      await tester.pumpAndSettle();

      // Tap grayscale filter in the panel
      await tester.tap(find.byKey(const Key('filter_panel_item_grayscale')));
      await tester.pumpAndSettle();

      // Panel should be gone
      expect(
        find.byKey(const Key('page_editor_filter_panel')),
        findsNothing,
      );

      // Filter should be applied
      expect(
        editorVm.activePage?.renderParams.filter,
        NotationFilter.grayscale,
      );
    });

    testWidgets('tapping outside panel (image area) collapses it',
        (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester.pumpWidget(
        _buildTestApp(session: session, editorVm: editorVm),
      );

      await tester.tap(find.byKey(const Key('page_editor_filters_button')));
      await tester.pumpAndSettle();

      // Tap the image preview area to collapse
      await tester.tap(find.byKey(const Key('page_editor_image_preview')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('page_editor_filter_panel')),
        findsNothing,
      );
    });
  });
}
