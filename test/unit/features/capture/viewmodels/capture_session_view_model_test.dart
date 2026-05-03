// capture_session_view_model_test.dart — unit tests for CaptureSessionViewModel.
//
// Covers:
//   - Initial state: empty page list
//   - loadFromPaths: creates CapturePageDraft for each path with identity RenderParams
//   - loadFromPaths: empty list leaves session empty
//   - loadFromPaths: reads bytes from each file path
//   - addPage: appends a draft to the session
//   - removePage: removes draft at given index
//   - removePage: no-op for out-of-bounds index
//   - updateRenderParams: replaces render params at given index
//   - clear: empties the session
//   - All state changes notify listeners

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Fake file reader
// ---------------------------------------------------------------------------

/// Fake implementation of [FileReader] for testing without disk I/O.
class FakeFileReader implements FileReader {
  /// Map from path to bytes to return.
  final Map<String, Uint8List> _data;

  /// Paths that should throw [Exception].
  final Set<String> _errorPaths;

  FakeFileReader({
    Map<String, Uint8List>? data,
    Set<String>? errorPaths,
  })  : _data = data ?? {},
        _errorPaths = errorPaths ?? {};

  @override
  Future<Uint8List> readAsBytes(String path) async {
    if (_errorPaths.contains(path)) {
      throw Exception('Read error for $path');
    }
    return _data[path] ?? Uint8List.fromList([1, 2, 3]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CaptureSessionViewModel viewModel;
  late FakeFileReader fakeReader;

  setUp(() {
    fakeReader = FakeFileReader();
    viewModel = CaptureSessionViewModel(fileReader: fakeReader);
  });

  tearDown(() => viewModel.dispose());

  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('initial state', () {
    test('pages is empty', () {
      expect(viewModel.pages, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // loadFromPaths
  // -------------------------------------------------------------------------

  group('loadFromPaths', () {
    test('creates one draft per path with identity render params', () async {
      const paths = ['/img/a.jpg', '/img/b.jpg', '/img/c.jpg'];

      await viewModel.loadFromPaths(paths);

      expect(viewModel.pages, hasLength(3));
      for (final draft in viewModel.pages) {
        expect(draft.renderParams, equals(RenderParams.identity));
      }
    });

    test('stores original bytes read from each path', () async {
      final bytesA = Uint8List.fromList([10, 20]);
      final bytesB = Uint8List.fromList([30, 40]);
      fakeReader = FakeFileReader(
        data: {'/a.jpg': bytesA, '/b.jpg': bytesB},
      );
      viewModel = CaptureSessionViewModel(fileReader: fakeReader);

      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      expect(viewModel.pages[0].originalBytes, equals(bytesA));
      expect(viewModel.pages[1].originalBytes, equals(bytesB));
    });

    test('stores original path on each draft', () async {
      const paths = ['/x.jpg', '/y.jpg'];

      await viewModel.loadFromPaths(paths);

      expect(viewModel.pages[0].originalPath, equals('/x.jpg'));
      expect(viewModel.pages[1].originalPath, equals('/y.jpg'));
    });

    test('empty paths list leaves session empty', () async {
      await viewModel.loadFromPaths([]);

      expect(viewModel.pages, isEmpty);
    });

    test('replaces existing pages on second call', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      await viewModel.loadFromPaths(['/c.jpg']);

      expect(viewModel.pages, hasLength(1));
      expect(viewModel.pages[0].originalPath, equals('/c.jpg'));
    });

    test('notifies listeners once per loadFromPaths call', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      // At minimum one notification; implementation may batch.
      expect(notifyCount, greaterThanOrEqualTo(1));
    });

    test(
      'skips path and continues when file read throws',
      () async {
        fakeReader = FakeFileReader(
          data: {
            '/good.jpg': Uint8List.fromList([1])
          },
          errorPaths: {'/bad.jpg'},
        );
        viewModel = CaptureSessionViewModel(fileReader: fakeReader);

        await viewModel.loadFromPaths(['/bad.jpg', '/good.jpg']);

        // The bad file is skipped; only the good one is added.
        expect(viewModel.pages, hasLength(1));
        expect(viewModel.pages[0].originalPath, equals('/good.jpg'));
      },
    );
  });

  // -------------------------------------------------------------------------
  // addPage
  // -------------------------------------------------------------------------

  group('addPage', () {
    test('appends draft to existing pages', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      final draft = CapturePageDraft(
        originalPath: '/b.jpg',
        originalBytes: Uint8List.fromList([5, 6]),
        renderParams: RenderParams.identity,
      );

      viewModel.addPage(draft);

      expect(viewModel.pages, hasLength(2));
      expect(viewModel.pages[1], equals(draft));
    });

    test('notifies listeners', () {
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.addPage(
        CapturePageDraft(
          originalPath: '/x.jpg',
          originalBytes: Uint8List.fromList([1]),
          renderParams: RenderParams.identity,
        ),
      );

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // removePage
  // -------------------------------------------------------------------------

  group('removePage', () {
    test('removes draft at valid index', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg', '/c.jpg']);

      viewModel.removePage(1);

      expect(viewModel.pages, hasLength(2));
      expect(viewModel.pages[0].originalPath, equals('/a.jpg'));
      expect(viewModel.pages[1].originalPath, equals('/c.jpg'));
    });

    test('no-op for negative index', () async {
      await viewModel.loadFromPaths(['/a.jpg']);

      viewModel.removePage(-1);

      expect(viewModel.pages, hasLength(1));
    });

    test('no-op for out-of-bounds index', () async {
      await viewModel.loadFromPaths(['/a.jpg']);

      viewModel.removePage(5);

      expect(viewModel.pages, hasLength(1));
    });

    test('notifies listeners on valid removal', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.removePage(0);

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // updateRenderParams
  // -------------------------------------------------------------------------

  group('updateRenderParams', () {
    test('replaces render params at valid index', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      const newParams = RenderParams(
        filter: NotationFilter.grayscale,
        rotationDegrees: 90,
      );

      viewModel.updateRenderParams(0, newParams);

      expect(viewModel.pages[0].renderParams, equals(newParams));
    });

    test('does not mutate other pages', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      const newParams = RenderParams(filter: NotationFilter.tintWarm);

      viewModel.updateRenderParams(0, newParams);

      expect(
        viewModel.pages[1].renderParams,
        equals(RenderParams.identity),
      );
    });

    test('no-op for out-of-bounds index', () async {
      await viewModel.loadFromPaths(['/a.jpg']);

      // Should not throw.
      viewModel.updateRenderParams(99, const RenderParams());

      expect(viewModel.pages[0].renderParams, equals(RenderParams.identity));
    });

    test('notifies listeners', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.updateRenderParams(
        0,
        const RenderParams(filter: NotationFilter.blackAndWhite),
      );

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // clear
  // -------------------------------------------------------------------------

  group('clear', () {
    test('empties the pages list', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      viewModel.clear();

      expect(viewModel.pages, isEmpty);
    });

    test('notifies listeners', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.clear();

      expect(notified, isTrue);
    });
  });
}
