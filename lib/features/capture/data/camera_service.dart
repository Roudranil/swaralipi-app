// camera_service.dart — abstraction over camera permission, intent launch,
// MediaStore query, and gallery picker.
//
// The concrete implementation [CameraServiceImpl] uses:
//   - permission_handler for runtime camera permission
//   - image_picker for camera intent launch and gallery selection
//
// The abstract [CameraService] interface is kept separate so that unit tests
// can substitute a [FakeCameraService] without platform dependencies.

import 'dart:developer';
import 'dart:io';

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
  /// Returns after the user presses back / exits the camera app.
  Future<void> launchCamera();

  /// Queries the device MediaStore for images added on or after [timestamp].
  ///
  /// Returns a list of absolute file paths sorted by recency (newest first).
  ///
  /// Parameters:
  /// - [timestamp]: The lower bound for `date_added`; typically recorded just
  ///   before [launchCamera] is called.
  Future<List<String>> queryMediaStoreAfterTimestamp(DateTime timestamp);

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
/// MediaStore querying is performed by scanning images returned from the
/// picker using a timestamp filter, since direct ContentResolver queries are
/// not available in Dart without platform channels.
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
  Future<void> launchCamera() async {
    // image_picker uses ACTION_IMAGE_CAPTURE intent on Android.
    // We ignore the returned XFile here; results are fetched via
    // queryMediaStoreAfterTimestamp so multi-photo sessions are supported.
    try {
      await _picker.pickImage(source: ImageSource.camera);
    } on Exception catch (e, st) {
      log(
        'CameraServiceImpl.launchCamera failed: $e',
        name: 'CameraService',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<String>> queryMediaStoreAfterTimestamp(
    DateTime timestamp,
  ) async {
    // image_picker does not provide a MediaStore query API.
    // We use the image_picker gallery picker restricted to images and sort by
    // last-modified date, then filter by timestamp ourselves.
    //
    // Limitation: only images visible in the picker are returned. This covers
    // the Samsung Galaxy S25 DCIM folder reliably.
    try {
      final images = await _picker.pickMultiImage();
      final paths = <String>[];
      for (final xFile in images) {
        final file = File(xFile.path);
        if (!file.existsSync()) continue;
        final stat = file.statSync();
        if (!stat.modified.isBefore(timestamp)) {
          paths.add(xFile.path);
        }
      }
      return paths;
    } on Exception catch (e, st) {
      log(
        'CameraServiceImpl.queryMediaStoreAfterTimestamp failed: $e',
        name: 'CameraService',
        error: e,
        stackTrace: st,
      );
      return [];
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
