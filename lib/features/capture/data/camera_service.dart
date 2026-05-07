// camera_service.dart — abstraction over camera permission, intent launch,
// and gallery picker.
//
// The concrete implementation [CameraServiceImpl] uses:
//   - permission_handler for runtime camera permission
//   - image_picker for camera intent launch and gallery selection
//
// The abstract [CameraService] interface is kept separate so that unit tests
// can substitute a [FakeCameraService] without platform dependencies.
//
// Change from initial design: [launchCamera] now returns the captured image
// path directly (Task 2 fix). The defunct
// [queryMediaStoreAfterTimestamp] has been removed — it opened the gallery
// picker a second time, which was the original bug.

import 'dart:developer';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

// ---------------------------------------------------------------------------
// Permission status enum
// ---------------------------------------------------------------------------

/// The result of requesting the camera permission.
enum CameraPermissionStatus {
  /// The user granted the camera permission.
  granted,

  /// The user denied the camera permission (can re-prompt).
  denied,

  /// The user permanently denied the permission; only Settings can re-enable.
  permanentlyDenied,
}

// ---------------------------------------------------------------------------
// Abstract interface
// ---------------------------------------------------------------------------

/// Abstracts camera permission, device camera launch, MediaStore queries, and
/// gallery selection.
///
/// Implementations must be injected; never instantiated directly by UI code.
abstract interface class CameraService {
  /// Requests the CAMERA runtime permission and returns its current status.
  Future<CameraPermissionStatus> requestCameraPermission();

  /// Launches the device camera activity via an intent.
  ///
  /// Returns the absolute file path of the captured image, or `null` when the
  /// user cancels without taking a photo.
  Future<String?> launchCamera();

  /// Opens the system gallery picker and returns selected image paths.
  ///
  /// Returns an empty list when the user cancels without selecting.
  Future<List<String>> pickFromGallery();
}

// ---------------------------------------------------------------------------
// Concrete implementation
// ---------------------------------------------------------------------------

/// Production implementation of [CameraService] backed by [ImagePicker] and
/// [permission_handler].
///
/// [launchCamera] uses `pickImage(source: ImageSource.camera)` and returns the
/// captured file path directly — no secondary gallery picker is needed.
class CameraServiceImpl implements CameraService {
  /// Creates a [CameraServiceImpl].
  ///
  /// Parameters:
  /// - [imagePicker]: The [ImagePicker] instance to use. Defaults to a new
  ///   instance.
  CameraServiceImpl({ImagePicker? imagePicker})
      : _picker = imagePicker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<CameraPermissionStatus> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return switch (status) {
      PermissionStatus.granted ||
      PermissionStatus.limited =>
        CameraPermissionStatus.granted,
      PermissionStatus.permanentlyDenied =>
        CameraPermissionStatus.permanentlyDenied,
      _ => CameraPermissionStatus.denied,
    };
  }

  @override
  Future<String?> launchCamera() async {
    // image_picker uses ACTION_IMAGE_CAPTURE intent on Android.
    // Returns the XFile path directly so callers do not need a second
    // gallery-picker round-trip (which was the original bug).
    try {
      final xFile = await _picker.pickImage(source: ImageSource.camera);
      return xFile?.path;
    } on Exception catch (e, st) {
      log(
        'CameraServiceImpl.launchCamera failed: $e',
        name: 'CameraService',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<List<String>> pickFromGallery() async {
    try {
      final images = await _picker.pickMultiImage();
      return images.map((x) => x.path).toList();
    } on Exception catch (e, st) {
      log(
        'CameraServiceImpl.pickFromGallery failed: $e',
        name: 'CameraService',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }
}
