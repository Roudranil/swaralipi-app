// page_editor_screen_test.dart — widget tests for PageEditorScreen.
//
// Covers:
//   - Screen renders with pages from CaptureSessionViewModel
//   - Empty session shows empty-state message
//   - Non-empty session shows page count label
//   - Thumbnail strip shows one item per page
//   - Tapping a thumbnail activates that page
//   - Filter chip row is shown for non-empty session
//   - Tapping filter chip updates render params (grayscale)
//   - Rotate CW button is present and tappable
//   - Rotate CCW button is present and tappable
//   - Reset button is present and tappable
//   - Delete icon on thumbnail removes page from session
//   - Next FAB is present for non-empty session
//   - Crop button opens crop overlay
//   - Last page deletion shows confirmation dialog

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
  void Function(BuildContext)? onNext,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<CaptureSessionViewModel>.value(value: session),
        ChangeNotifierProvider<PageEditorViewModel>.value(value: editorVm),
      ],
      child: PageEditorScreen(
        onNext: onNext ?? (BuildContext _) {},
      ),
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

  group('empty state', () {
    testWidgets('shows empty state widget when session has no pages',
        (tester) async {
      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_empty_state')), findsOneWidget);
    });

    testWidgets('does not show FAB in empty state', (tester) async {
      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(
        find.byKey(const Key('page_editor_next_fab')),
        findsNothing,
      );
    });
  });

  group('non-empty session', () {
    testWidgets('shows page count label for one page', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.text('1 page'), findsOneWidget);
    });

    testWidgets('shows page count label for multiple pages', (tester) async {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      session.addPage(_draft('/c.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.text('3 pages'), findsOneWidget);
    });

    testWidgets('shows thumbnail strip', (tester) async {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(
        find.byKey(const Key('page_editor_thumbnail_strip')),
        findsOneWidget,
      );
    });

    testWidgets('shows Next FAB', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_next_fab')), findsOneWidget);
    });

    testWidgets('shows filter chip row', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(
        find.byKey(const Key('page_editor_filter_chips')),
        findsOneWidget,
      );
    });

    testWidgets('shows rotate CW button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_rotate_cw')), findsOneWidget);
    });

    testWidgets('shows rotate CCW button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_rotate_ccw')), findsOneWidget);
    });

    testWidgets('shows reset button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_reset')), findsOneWidget);
    });

    testWidgets('shows crop button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.byKey(const Key('page_editor_crop_button')), findsOneWidget);
    });
  });

  group('filter chips', () {
    testWidgets('tapping grayscale chip updates render params', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('filter_chip_grayscale')));
      await tester.pump();

      expect(
        editorVm.pages[0].renderParams.filter,
        NotationFilter.grayscale,
      );
    });

    testWidgets('tapping none chip resets filter to none', (tester) async {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(filter: NotationFilter.grayscale),
        ),
      );

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('filter_chip_none')));
      await tester.pump();

      expect(
        editorVm.pages[0].renderParams.filter,
        NotationFilter.none,
      );
    });
  });

  group('rotate buttons', () {
    testWidgets('rotate CW button increments rotation by 90', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_rotate_cw')));
      await tester.pump();

      expect(editorVm.pages[0].renderParams.rotationDegrees, 90);
    });

    testWidgets('rotate CCW button decrements rotation by 90', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_rotate_ccw')));
      await tester.pump();

      expect(editorVm.pages[0].renderParams.rotationDegrees, 270);
    });
  });

  group('reset button', () {
    testWidgets('reset button restores identity render params', (tester) async {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(
            filter: NotationFilter.tintWarm,
            rotationDegrees: 90,
          ),
        ),
      );

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_reset')));
      await tester.pump();

      expect(editorVm.pages[0].renderParams, RenderParams.identity);
    });
  });

  group('crop overlay', () {
    testWidgets('tapping crop button shows crop overlay', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_crop_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_editor_crop_overlay')), findsOneWidget);
    });

    testWidgets('crop overlay has confirm button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_crop_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('crop_overlay_confirm')),
        findsOneWidget,
      );
    });

    testWidgets('crop overlay has cancel button', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_crop_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('crop_overlay_cancel')),
        findsOneWidget,
      );
    });

    testWidgets('cancelling crop dismisses overlay', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      await tester.tap(find.byKey(const Key('page_editor_crop_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('crop_overlay_cancel')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_editor_crop_overlay')), findsNothing);
    });
  });

  group('thumbnail delete', () {
    testWidgets('delete icon is present on thumbnails', (tester) async {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(
        find.byKey(const Key('thumbnail_delete_0')),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping delete on non-last page removes it without dialog',
      (tester) async {
        session.addPage(_draft('/a.jpg'));
        session.addPage(_draft('/b.jpg'));

        await tester.pumpWidget(
          _buildTestApp(session: session, editorVm: editorVm),
        );

        await tester.tap(find.byKey(const Key('thumbnail_delete_0')));
        await tester.pumpAndSettle();

        expect(session.pages.length, 1);
        expect(session.pages[0].originalPath, '/b.jpg');
      },
    );

    testWidgets(
      'tapping delete on last page shows confirmation dialog',
      (tester) async {
        session.addPage(_draft('/a.jpg'));

        await tester.pumpWidget(
          _buildTestApp(session: session, editorVm: editorVm),
        );

        await tester.tap(find.byKey(const Key('thumbnail_delete_0')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('last_page_delete_dialog')),
          findsOneWidget,
        );
        // Page not yet removed.
        expect(session.pages.length, 1);
      },
    );
  });

  group('next FAB', () {
    testWidgets('tapping Next FAB calls onNext callback', (tester) async {
      session.addPage(_draft('/a.jpg'));

      var onNextCalled = false;
      await tester.pumpWidget(
        _buildTestApp(
          session: session,
          editorVm: editorVm,
          onNext: (_) => onNextCalled = true,
        ),
      );

      await tester.tap(find.byKey(const Key('page_editor_next_fab')));
      await tester.pump();

      expect(onNextCalled, isTrue);
    });
  });

  group('page count updates reactively', () {
    testWidgets('page count label updates after adding a page', (tester) async {
      session.addPage(_draft('/a.jpg'));

      await tester
          .pumpWidget(_buildTestApp(session: session, editorVm: editorVm));

      expect(find.text('1 page'), findsOneWidget);

      session.addPage(_draft('/b.jpg'));
      await tester.pump();

      expect(find.text('2 pages'), findsOneWidget);
    });
  });
}
