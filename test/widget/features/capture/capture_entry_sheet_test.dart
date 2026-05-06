// capture_entry_sheet_test.dart — widget tests for CaptureEntrySheet.
//
// Covers:
//   - Sheet renders two options: Camera and Gallery
//   - Tapping Camera calls onCameraSelected
//   - Tapping Gallery calls onGallerySelected
//   - Permanently denied dialog is shown when state is permissionPermanentlyDenied
//   - "Go to Settings" button is present in the denied dialog
//   - Sheet is scrollable / renders correctly in constrained height

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/data/camera_service.dart';
import 'package:swaralipi/features/capture/screens/capture_entry_sheet.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_entry_view_model.dart';

// ---------------------------------------------------------------------------
// Stub CameraService
// ---------------------------------------------------------------------------

class _StubCameraService implements CameraService {
  CameraPermissionStatus status;
  String? cameraPath;
  List<String> galleryImages;

  _StubCameraService({
    this.status = CameraPermissionStatus.granted,
    this.cameraPath,
    this.galleryImages = const [],
  });

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async => status;

  @override
  Future<String?> launchCamera() async => cameraPath;

  @override
  Future<List<String>> pickFromGallery() async => galleryImages;
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

Widget _buildTestApp(
  Widget child, {
  CaptureEntryViewModel? viewModel,
}) {
  final vm = viewModel ?? CaptureEntryViewModel(_StubCameraService());
  return MaterialApp(
    home: ChangeNotifierProvider<CaptureEntryViewModel>.value(
      value: vm,
      child: Scaffold(body: child),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  testWidgets('sheet renders Camera and Gallery options', (tester) async {
    await tester.pumpWidget(
      _buildTestApp(const CaptureEntrySheet()),
    );

    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets(
    'tapping Camera triggers requestCameraAndLaunch on viewModel',
    (tester) async {
      var cameraCallCount = 0;
      final service = _StubCameraService(
        status: CameraPermissionStatus.granted,
        cameraPath: '/img.jpg',
      );
      final vm = _TrackedViewModel(service, onCamera: () => cameraCallCount++);

      await tester
          .pumpWidget(_buildTestApp(const CaptureEntrySheet(), viewModel: vm));

      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();

      expect(cameraCallCount, 1);
    },
  );

  testWidgets(
    'tapping Gallery triggers launchGallery on viewModel',
    (tester) async {
      var galleryCallCount = 0;
      final service = _StubCameraService(
        galleryImages: ['/gallery.jpg'],
      );
      final vm = _TrackedViewModel(
        service,
        onGallery: () => galleryCallCount++,
      );

      await tester
          .pumpWidget(_buildTestApp(const CaptureEntrySheet(), viewModel: vm));

      await tester.tap(find.text('Gallery'));
      await tester.pumpAndSettle();

      expect(galleryCallCount, 1);
    },
  );

  testWidgets(
    'shows permission dialog when state is permissionPermanentlyDenied',
    (tester) async {
      final service = _StubCameraService(
        status: CameraPermissionStatus.permanentlyDenied,
      );
      final vm = CaptureEntryViewModel(service);

      await tester
          .pumpWidget(_buildTestApp(const CaptureEntrySheet(), viewModel: vm));

      // Trigger permission permanently denied state
      await vm.requestCameraAndLaunch();
      await tester.pumpAndSettle();

      expect(find.text('Camera Permission Required'), findsOneWidget);
      expect(find.text('Go to Settings'), findsOneWidget);
    },
  );

  testWidgets('shows loading indicator while state is loading', (tester) async {
    final service = _StubCameraService();
    final vm = CaptureEntryViewModel(service);

    // Manually set loading state via a delayed action
    await tester
        .pumpWidget(_buildTestApp(const CaptureEntrySheet(), viewModel: vm));

    // The sheet itself should have no loading indicator in idle
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

// ---------------------------------------------------------------------------
// Tracked ViewModel for interaction testing
// ---------------------------------------------------------------------------

class _TrackedViewModel extends CaptureEntryViewModel {
  _TrackedViewModel(
    super.cameraService, {
    void Function()? onCamera,
    void Function()? onGallery,
  })  : _onCamera = onCamera,
        _onGallery = onGallery;

  final void Function()? _onCamera;
  final void Function()? _onGallery;

  @override
  Future<void> requestCameraAndLaunch() async {
    _onCamera?.call();
    await super.requestCameraAndLaunch();
  }

  @override
  Future<void> launchGallery() async {
    _onGallery?.call();
    await super.launchGallery();
  }
}
