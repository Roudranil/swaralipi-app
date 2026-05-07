// page_editor_next_navigation_test.dart — tests for Task 3: PageEditorScreen
// "Next" button wires to MetadataFormScreen via the onNext callback.
//
// Covers:
//   - onNext callback is invoked when Next FAB is tapped
//   - Callback receives the correct BuildContext (non-null)

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
  required void Function(BuildContext) onNext,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<CaptureSessionViewModel>.value(value: session),
        ChangeNotifierProvider<PageEditorViewModel>.value(value: editorVm),
      ],
      child: PageEditorScreen(onNext: onNext),
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

  group('Next FAB callback', () {
    testWidgets('onNext callback is invoked when Next FAB is tapped',
        (tester) async {
      session.addPage(_draft('/a.jpg'));

      var callbackInvoked = false;
      await tester.pumpWidget(
        _buildTestApp(
          session: session,
          editorVm: editorVm,
          onNext: (_) => callbackInvoked = true,
        ),
      );

      await tester.tap(find.byKey(const Key('page_editor_next_fab')));
      await tester.pump();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('onNext callback receives non-null BuildContext', (tester) async {
      session.addPage(_draft('/a.jpg'));

      BuildContext? receivedContext;
      await tester.pumpWidget(
        _buildTestApp(
          session: session,
          editorVm: editorVm,
          onNext: (ctx) => receivedContext = ctx,
        ),
      );

      await tester.tap(find.byKey(const Key('page_editor_next_fab')));
      await tester.pump();

      expect(receivedContext, isNotNull);
    });

    testWidgets('Next FAB is absent when session is empty', (tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          session: session,
          editorVm: editorVm,
          onNext: (_) {},
        ),
      );

      expect(find.byKey(const Key('page_editor_next_fab')), findsNothing);
    });
  });
}
