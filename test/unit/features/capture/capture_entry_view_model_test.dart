// capture_entry_view_model_test.dart — unit tests for CaptureEntryViewModel.
//
// Covers:
//   - Permission states: granted, denied, permanentlyDenied
//   - Camera launch: returns path directly from launchCamera (Task 2 fix)
//   - Non-null path → CaptureEntryStateCameraDone
//   - Null path → CaptureEntryStateCameraEmpty
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

  /// Path returned by [launchCamera]; null simulates user cancellation.
  String? cameraReturnPath;

  /// Images returned by [pickFromGallery].
  List<String> galleryImages = [];

  /// Whether [launchCamera] was called.
  bool cameraLaunched = false;

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    if (permissionPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (permissionGranted) return CameraPermissionStatus.granted;
    return CameraPermissionStatus.denied;
  }

  @override
  Future<String?> launchCamera() async {
    cameraLaunched = true;
    return cameraReturnPath;
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
      'transitions to cameraDone with path when permission granted and '
      'camera returns a path',
      () async {
        fakeService.cameraReturnPath = '/storage/img1.jpg';

        await viewModel.requestCameraAndLaunch();

        expect(viewModel.state, isA<CaptureEntryStateCameraDone>());
        final done = viewModel.state as CaptureEntryStateCameraDone;
        expect(done.imagePaths, equals(['/storage/img1.jpg']));
        expect(fakeService.cameraLaunched, isTrue);
      },
    );

    test(
      'transitions to cameraEmpty when camera returns null (user cancelled)',
      () async {
        fakeService.cameraReturnPath = null;

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

    test(
      'transitions to loading then resolves — notifies listeners',
      () async {
        final states = <CaptureEntryState>[];
        viewModel.addListener(() => states.add(viewModel.state));
        fakeService.cameraReturnPath = '/img.jpg';

        await viewModel.requestCameraAndLaunch();

        // First notification must be loading.
        expect(states.first, isA<CaptureEntryStateLoading>());
        // Final notification must be cameraDone.
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

    test(
      'transitions to galleryDone with empty list when user cancels',
      () async {
        fakeService.galleryImages = [];

        await viewModel.launchGallery();

        expect(viewModel.state, isA<CaptureEntryStateGalleryDone>());
        final done = viewModel.state as CaptureEntryStateGalleryDone;
        expect(done.imagePaths, isEmpty);
      },
    );
  });

  group('reset', () {
    test('returns state to idle', () async {
      fakeService.cameraReturnPath = '/img.jpg';
      await viewModel.requestCameraAndLaunch();
      expect(viewModel.state, isA<CaptureEntryStateCameraDone>());

      viewModel.reset();

      expect(viewModel.state, isA<CaptureEntryStateIdle>());
    });
  });
}
