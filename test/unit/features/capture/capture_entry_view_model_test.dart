// capture_entry_view_model_test.dart — unit tests for CaptureEntryViewModel.
//
// Covers:
//   - Permission states: granted, denied, permanentlyDenied
//   - Camera launch: records launchTimestamp and fires camera via CameraService
//   - MediaStore query: returns images after camera session
//   - Empty result after camera session
//   - Gallery launch delegates to CameraService.pickFromGallery

import 'package:flutter_test/flutter_test.dart';

import 'package:swaralipi/features/capture/data/camera_service.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_entry_view_model.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Fake [CameraService] for unit testing [CaptureEntryViewModel].
class FakeCameraService implements CameraService {
  /// Whether [requestCameraPermission] should return granted.
  bool permissionGranted = true;

  /// Whether [requestCameraPermission] should return permanently denied.
  bool permissionPermanentlyDenied = false;

  /// Images returned by [queryMediaStoreAfterTimestamp].
  List<String> mediaStoreImages = [];

  /// Images returned by [pickFromGallery].
  List<String> galleryImages = [];

  /// Whether [launchCamera] was called.
  bool cameraLaunched = false;

  /// The timestamp passed to [queryMediaStoreAfterTimestamp].
  DateTime? queriedTimestamp;

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    if (permissionPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (permissionGranted) return CameraPermissionStatus.granted;
    return CameraPermissionStatus.denied;
  }

  @override
  Future<void> launchCamera() async {
    cameraLaunched = true;
  }

  @override
  Future<List<String>> queryMediaStoreAfterTimestamp(
    DateTime timestamp,
  ) async {
    queriedTimestamp = timestamp;
    return mediaStoreImages;
  }

  @override
  Future<List<String>> pickFromGallery() async => galleryImages;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeCameraService fakeService;
  late CaptureEntryViewModel viewModel;

  setUp(() {
    fakeService = FakeCameraService();
    viewModel = CaptureEntryViewModel(fakeService);
  });

  tearDown(() => viewModel.dispose());

  group('requestCameraAndLaunch', () {
    test(
      'transitions to cameraDone with images when permission granted',
      () async {
        fakeService.mediaStoreImages = [
          '/storage/img1.jpg',
          '/storage/img2.jpg'
        ];

        await viewModel.requestCameraAndLaunch();

        expect(
          viewModel.state,
          isA<CaptureEntryStateCameraDone>(),
        );
        final done = viewModel.state as CaptureEntryStateCameraDone;
        expect(done.imagePaths, hasLength(2));
        expect(fakeService.cameraLaunched, isTrue);
        expect(fakeService.queriedTimestamp, isNotNull);
      },
    );

    test(
      'transitions to cameraEmpty when no images found after camera',
      () async {
        fakeService.mediaStoreImages = [];

        await viewModel.requestCameraAndLaunch();

        expect(viewModel.state, isA<CaptureEntryStateCameraEmpty>());
        expect(fakeService.cameraLaunched, isTrue);
      },
    );

    test(
      'transitions to permissionDenied when permission is denied',
      () async {
        fakeService.permissionGranted = false;

        await viewModel.requestCameraAndLaunch();

        expect(viewModel.state, isA<CaptureEntryStatePermissionDenied>());
        expect(fakeService.cameraLaunched, isFalse);
      },
    );

    test(
      'transitions to permissionPermanentlyDenied when permanently denied',
      () async {
        fakeService.permissionPermanentlyDenied = true;

        await viewModel.requestCameraAndLaunch();

        expect(
          viewModel.state,
          isA<CaptureEntryStatePermissionPermanentlyDenied>(),
        );
        expect(fakeService.cameraLaunched, isFalse);
      },
    );

    test('records timestamp before camera launch', () async {
      final before = DateTime.now();
      fakeService.mediaStoreImages = ['/storage/img.jpg'];

      await viewModel.requestCameraAndLaunch();

      final after = DateTime.now();
      expect(fakeService.queriedTimestamp, isNotNull);
      expect(
        fakeService.queriedTimestamp!.isAfter(
          before.subtract(const Duration(seconds: 1)),
        ),
        isTrue,
      );
      expect(
        fakeService.queriedTimestamp!.isBefore(
          after.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });

    test(
      'transitions to loading then resolves — notifies listeners',
      () async {
        final states = <CaptureEntryState>[];
        viewModel.addListener(() => states.add(viewModel.state));
        fakeService.mediaStoreImages = ['/img.jpg'];

        await viewModel.requestCameraAndLaunch();

        // First notification must be loading
        expect(states.first, isA<CaptureEntryStateLoading>());
        // Final notification must be cameraDone
        expect(states.last, isA<CaptureEntryStateCameraDone>());
      },
    );
  });

  group('launchGallery', () {
    test('transitions to galleryDone with selected images', () async {
      fakeService.galleryImages = ['/storage/gallery1.jpg'];

      await viewModel.launchGallery();

      expect(viewModel.state, isA<CaptureEntryStateGalleryDone>());
      final done = viewModel.state as CaptureEntryStateGalleryDone;
      expect(done.imagePaths, equals(['/storage/gallery1.jpg']));
    });

    test('transitions to galleryDone with empty list when user cancels',
        () async {
      fakeService.galleryImages = [];

      await viewModel.launchGallery();

      expect(viewModel.state, isA<CaptureEntryStateGalleryDone>());
      final done = viewModel.state as CaptureEntryStateGalleryDone;
      expect(done.imagePaths, isEmpty);
    });
  });

  group('reset', () {
    test('returns state to idle', () async {
      fakeService.mediaStoreImages = ['/img.jpg'];
      await viewModel.requestCameraAndLaunch();
      expect(viewModel.state, isA<CaptureEntryStateCameraDone>());

      viewModel.reset();

      expect(viewModel.state, isA<CaptureEntryStateIdle>());
    });
  });
}
