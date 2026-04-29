// render_params_map_test.dart — unit tests for the renderParamsMap pipeline
// integration on CaptureSessionViewModel.
//
// Covers:
//   - renderParamsMap: empty when session has no pages
//   - renderParamsMap: populated with identity params after loadFromPaths
//   - renderParamsMap: keys are 0-based page indices
//   - renderParamsMap: updated immutably on updateRenderParams
//   - renderParamsMap: does not mutate other page entries on update
//   - renderParamsMap: reverts to identity after resetRenderParamsAt
//   - renderParamsMap: entry removed on removePage; remaining indices stable
//   - renderParamsMap: fully cleared on clear
//   - renderParamsMap: rebuilt from new paths on loadFromPaths call
//   - All operations notify listeners

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Fake file reader (reused from capture_session_view_model_test)
// ---------------------------------------------------------------------------

/// Fake implementation of [FileReader] for testing without disk I/O.
class _FakeFileReader implements FileReader {
  final Map<String, Uint8List> _data;

  _FakeFileReader({Map<String, Uint8List>? data}) : _data = data ?? {};

  @override
  Future<Uint8List> readAsBytes(String path) async =>
      _data[path] ?? Uint8List.fromList([1, 2, 3]);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CaptureSessionViewModel viewModel;
  late _FakeFileReader fakeReader;

  setUp(() {
    fakeReader = _FakeFileReader();
    viewModel = CaptureSessionViewModel(fileReader: fakeReader);
  });

  tearDown(() => viewModel.dispose());

  // -------------------------------------------------------------------------
  // renderParamsMap — initial state
  // -------------------------------------------------------------------------

  group('renderParamsMap — initial state', () {
    test('is empty when no pages are loaded', () {
      expect(viewModel.renderParamsMap, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // renderParamsMap — after loadFromPaths
  // -------------------------------------------------------------------------

  group('renderParamsMap — after loadFromPaths', () {
    test('has one entry per loaded path', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg', '/c.jpg']);

      expect(viewModel.renderParamsMap, hasLength(3));
    });

    test('keys are 0-based indices', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      expect(viewModel.renderParamsMap.containsKey(0), isTrue);
      expect(viewModel.renderParamsMap.containsKey(1), isTrue);
      expect(viewModel.renderParamsMap.containsKey(2), isFalse);
    });

    test('all values are identity RenderParams', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      for (final entry in viewModel.renderParamsMap.entries) {
        expect(entry.value, equals(RenderParams.identity));
      }
    });

    test('rebuilds map when loadFromPaths is called again', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      await viewModel.loadFromPaths(['/c.jpg']);

      expect(viewModel.renderParamsMap, hasLength(1));
      expect(viewModel.renderParamsMap[0], equals(RenderParams.identity));
    });
  });

  // -------------------------------------------------------------------------
  // renderParamsMap — updateRenderParams
  // -------------------------------------------------------------------------

  group('renderParamsMap — updateRenderParams', () {
    test('updated entry reflects new RenderParams', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      const newParams = RenderParams(
        filter: NotationFilter.grayscale,
        rotationDegrees: 90,
      );

      viewModel.updateRenderParams(0, newParams);

      expect(viewModel.renderParamsMap[0], equals(newParams));
    });

    test('does not affect other entries', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      const newParams = RenderParams(filter: NotationFilter.tintWarm);

      viewModel.updateRenderParams(0, newParams);

      expect(viewModel.renderParamsMap[1], equals(RenderParams.identity));
    });

    test('map is unmodifiable — direct assignment throws', () async {
      await viewModel.loadFromPaths(['/a.jpg']);

      expect(
        () => viewModel.renderParamsMap[0] = const RenderParams(),
        throwsUnsupportedError,
      );
    });

    test('notifies listeners on update', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.updateRenderParams(0, const RenderParams(rotationDegrees: 180));

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // renderParamsMap — resetRenderParamsAt
  // -------------------------------------------------------------------------

  group('renderParamsMap — resetRenderParamsAt', () {
    test('reverts entry to identity after previous modification', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      viewModel.updateRenderParams(
        0,
        const RenderParams(filter: NotationFilter.blackAndWhite),
      );

      viewModel.resetRenderParamsAt(0);

      expect(viewModel.renderParamsMap[0], equals(RenderParams.identity));
    });

    test('does not affect other entries', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);
      viewModel.updateRenderParams(
        1,
        const RenderParams(filter: NotationFilter.grayscale),
      );
      viewModel.updateRenderParams(
        0,
        const RenderParams(filter: NotationFilter.tintCool),
      );

      viewModel.resetRenderParamsAt(0);

      expect(
        viewModel.renderParamsMap[1],
        equals(const RenderParams(filter: NotationFilter.grayscale)),
      );
    });

    test('no-op for out-of-bounds index', () async {
      await viewModel.loadFromPaths(['/a.jpg']);

      // Should not throw.
      viewModel.resetRenderParamsAt(99);

      expect(viewModel.renderParamsMap[0], equals(RenderParams.identity));
    });

    test('notifies listeners', () async {
      await viewModel.loadFromPaths(['/a.jpg']);
      viewModel.updateRenderParams(
        0,
        const RenderParams(filter: NotationFilter.grayscale),
      );
      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.resetRenderParamsAt(0);

      expect(notified, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // renderParamsMap — removePage
  // -------------------------------------------------------------------------

  group('renderParamsMap — removePage', () {
    test('entry removed; remaining entries re-indexed from 0', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg', '/c.jpg']);
      viewModel.updateRenderParams(
        2,
        const RenderParams(filter: NotationFilter.tintWarm),
      );

      viewModel.removePage(1);

      // Page at index 1 (/b.jpg) removed; /c.jpg is now at index 1.
      expect(viewModel.renderParamsMap, hasLength(2));
      expect(viewModel.renderParamsMap[0], equals(RenderParams.identity));
      expect(
        viewModel.renderParamsMap[1],
        equals(const RenderParams(filter: NotationFilter.tintWarm)),
      );
    });
  });

  // -------------------------------------------------------------------------
  // renderParamsMap — clear
  // -------------------------------------------------------------------------

  group('renderParamsMap — clear', () {
    test('is empty after clear', () async {
      await viewModel.loadFromPaths(['/a.jpg', '/b.jpg']);

      viewModel.clear();

      expect(viewModel.renderParamsMap, isEmpty);
    });
  });
}
