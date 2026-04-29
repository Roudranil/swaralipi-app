// page_editor_view_model_test.dart — unit tests for PageEditorViewModel.
//
// Covers:
//   - Initial state: active page index 0, delegates to CaptureSessionViewModel
//   - setActivePage: updates activePageIndex, notifies listeners
//   - setActivePage: no-op for out-of-bounds index
//   - setFilter: updates RenderParams.filter on active page
//   - rotateClockwise: increments rotationDegrees by 90, wraps at 360
//   - rotateCounterClockwise: decrements rotationDegrees by 90, wraps below 0
//   - resetRenderParams: restores RenderParams.identity on active page
//   - setCropRect: updates cropRect on active page
//   - reorderPages: moves a page to a new index
//   - removePage: removes a page from the session
//   - All state changes notify listeners

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CaptureSessionViewModel session;
  late PageEditorViewModel vm;

  setUp(() {
    session = CaptureSessionViewModel();
    vm = PageEditorViewModel(session: session);
  });

  tearDown(() {
    vm.dispose();
    session.dispose();
  });

  group('initial state', () {
    test('activePageIndex is 0 when session is empty', () {
      expect(vm.activePageIndex, 0);
    });

    test('pages delegates to session.pages', () {
      session.addPage(_draft('/a.jpg'));
      expect(vm.pages, equals(session.pages));
    });
  });

  group('setActivePage', () {
    test('updates activePageIndex for valid index', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));

      vm.setActivePage(1);
      expect(vm.activePageIndex, 1);
    });

    test('notifies listeners on valid setActivePage', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));

      var notified = false;
      vm.addListener(() => notified = true);

      vm.setActivePage(1);
      expect(notified, isTrue);
    });

    test('no-op for negative index', () {
      session.addPage(_draft('/a.jpg'));

      vm.setActivePage(-1);
      expect(vm.activePageIndex, 0);
    });

    test('no-op for index equal to page count', () {
      session.addPage(_draft('/a.jpg'));

      vm.setActivePage(1);
      expect(vm.activePageIndex, 0);
    });

    test('clamps activePageIndex when active page is removed', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      vm.setActivePage(1);

      vm.removePage(1);
      expect(vm.activePageIndex, 0);
    });
  });

  group('setFilter', () {
    test('updates filter on active page via session', () {
      session.addPage(_draft('/a.jpg'));

      vm.setFilter(NotationFilter.grayscale);

      expect(vm.pages[0].renderParams.filter, NotationFilter.grayscale);
    });

    test('no-op when session is empty', () {
      expect(() => vm.setFilter(NotationFilter.blackAndWhite), returnsNormally);
    });

    test('notifies listeners after setFilter', () {
      session.addPage(_draft('/a.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.setFilter(NotationFilter.tintWarm);
      expect(notified, isTrue);
    });
  });

  group('rotateClockwise', () {
    test('increments rotation by 90 degrees', () {
      session.addPage(_draft('/a.jpg'));

      vm.rotateClockwise();
      expect(vm.pages[0].renderParams.rotationDegrees, 90);
    });

    test('wraps from 270 back to 0', () {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(rotationDegrees: 270),
        ),
      );

      vm.rotateClockwise();
      expect(vm.pages[0].renderParams.rotationDegrees, 0);
    });

    test('notifies listeners after rotateClockwise', () {
      session.addPage(_draft('/a.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.rotateClockwise();
      expect(notified, isTrue);
    });
  });

  group('rotateCounterClockwise', () {
    test('decrements rotation by 90 degrees', () {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(rotationDegrees: 90),
        ),
      );

      vm.rotateCounterClockwise();
      expect(vm.pages[0].renderParams.rotationDegrees, 0);
    });

    test('wraps from 0 to 270', () {
      session.addPage(_draft('/a.jpg'));

      vm.rotateCounterClockwise();
      expect(vm.pages[0].renderParams.rotationDegrees, 270);
    });

    test('notifies listeners after rotateCounterClockwise', () {
      session.addPage(_draft('/a.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.rotateCounterClockwise();
      expect(notified, isTrue);
    });
  });

  group('resetRenderParams', () {
    test('resets to RenderParams.identity on active page', () {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(
            filter: NotationFilter.grayscale,
            rotationDegrees: 180,
          ),
        ),
      );

      vm.resetRenderParams();
      expect(vm.pages[0].renderParams, RenderParams.identity);
    });

    test('no-op when session is empty', () {
      expect(() => vm.resetRenderParams(), returnsNormally);
    });

    test('notifies listeners after reset', () {
      session.addPage(_draft('/a.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.resetRenderParams();
      expect(notified, isTrue);
    });
  });

  group('setCropRect', () {
    test('updates cropRect on active page', () {
      session.addPage(_draft('/a.jpg'));
      const crop = CropRect(left: 0.1, top: 0.1, right: 0.9, bottom: 0.9);

      vm.setCropRect(crop);
      expect(vm.pages[0].renderParams.cropRect, crop);
    });

    test('clearing cropRect (null) resets crop on active page', () {
      session.addPage(
        _draft('/a.jpg').copyWith(
          renderParams: const RenderParams(
            cropRect: CropRect(
              left: 0.1,
              top: 0.1,
              right: 0.9,
              bottom: 0.9,
            ),
          ),
        ),
      );

      vm.setCropRect(null);
      expect(vm.pages[0].renderParams.cropRect, isNull);
    });

    test('no-op when session is empty', () {
      const crop = CropRect(left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);
      expect(() => vm.setCropRect(crop), returnsNormally);
    });
  });

  group('reorderPages', () {
    test('moves page from oldIndex to newIndex', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      session.addPage(_draft('/c.jpg'));

      // Move index 0 (/a.jpg) to index 2 (/c.jpg position)
      vm.reorderPages(0, 2);

      expect(vm.pages[0].originalPath, '/b.jpg');
      expect(vm.pages[1].originalPath, '/a.jpg');
      expect(vm.pages[2].originalPath, '/c.jpg');
    });

    test('notifies listeners after reorder', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.reorderPages(0, 1);
      expect(notified, isTrue);
    });

    test('updates activePageIndex to follow moved page', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      session.addPage(_draft('/c.jpg'));
      vm.setActivePage(0);

      vm.reorderPages(0, 2);
      // Active page (/a.jpg) moved to index 1 after reorder
      expect(vm.pages[vm.activePageIndex].originalPath, '/a.jpg');
    });
  });

  group('removePage', () {
    test('removes page at given index from session', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));

      vm.removePage(0);
      expect(vm.pages.length, 1);
      expect(vm.pages[0].originalPath, '/b.jpg');
    });

    test('notifies listeners after remove', () {
      session.addPage(_draft('/a.jpg'));
      var notified = false;
      vm.addListener(() => notified = true);

      vm.removePage(0);
      expect(notified, isTrue);
    });

    test('adjusts activePageIndex when active page is removed mid-list', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      session.addPage(_draft('/c.jpg'));
      vm.setActivePage(1);

      vm.removePage(1);
      expect(vm.activePageIndex, 0);
    });

    test('no-op for out-of-bounds index', () {
      session.addPage(_draft('/a.jpg'));
      vm.removePage(5);
      expect(vm.pages.length, 1);
    });
  });

  group('activePage', () {
    test('returns null when pages is empty', () {
      expect(vm.activePage, isNull);
    });

    test('returns active CapturePageDraft when pages non-empty', () {
      session.addPage(_draft('/a.jpg'));
      session.addPage(_draft('/b.jpg'));
      vm.setActivePage(1);

      expect(vm.activePage?.originalPath, '/b.jpg');
    });
  });
}
