// capture_entry_view_model.dart — ChangeNotifier ViewModel for the capture
// entry sheet.
//
// Manages the camera permission request flow, device camera intent launch,
// and gallery picker delegation.
//
// State hierarchy (sealed):
//   CaptureEntryStateIdle                — initial, no operation in progress
//   CaptureEntryStateLoading             — async operation in flight
//   CaptureEntryStatePermissionDenied    — user denied camera permission
//   CaptureEntryStatePermissionPermanentlyDenied — needs Settings deep-link
//   CaptureEntryStateCameraDone          — camera session complete; images ready
//   CaptureEntryStateCameraEmpty         — camera session complete; no images
//   CaptureEntryStateGalleryDone         — gallery pick complete; paths ready
//
// Usage:
//   final vm = CaptureEntryViewModel(CameraServiceImpl());
//   vm.addListener(() { ... });
//   await vm.requestCameraAndLaunch();

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/capture/data/camera_service.dart';

// ---------------------------------------------------------------------------
// State hierarchy
// ---------------------------------------------------------------------------

/// Sealed base for all [CaptureEntryViewModel] states.
sealed class CaptureEntryState {
  const CaptureEntryState();
}

/// The initial state; no operation in progress.
final class CaptureEntryStateIdle extends CaptureEntryState {
  const CaptureEntryStateIdle();
}

/// An async operation (permission request, camera launch, or gallery pick)
/// is in progress.
final class CaptureEntryStateLoading extends CaptureEntryState {
  const CaptureEntryStateLoading();
}

/// Camera permission was denied by the user; the app can re-prompt.
final class CaptureEntryStatePermissionDenied extends CaptureEntryState {
  const CaptureEntryStatePermissionDenied();
}

/// Camera permission was permanently denied; Settings is required to re-enable.
final class CaptureEntryStatePermissionPermanentlyDenied
    extends CaptureEntryState {
  const CaptureEntryStatePermissionPermanentlyDenied();
}

/// The camera session completed and at least one image was found.
final class CaptureEntryStateCameraDone extends CaptureEntryState {
  /// Creates a [CaptureEntryStateCameraDone].
  ///
  /// Parameters:
  /// - [imagePaths]: Absolute file paths of images captured in this session.
  const CaptureEntryStateCameraDone(this.imagePaths);

  /// Absolute file paths of images captured in this session.
  final List<String> imagePaths;
}

/// The camera session completed but no images were found in MediaStore.
final class CaptureEntryStateCameraEmpty extends CaptureEntryState {
  const CaptureEntryStateCameraEmpty();
}

/// The gallery picker completed; [imagePaths] may be empty if the user
/// cancelled.
final class CaptureEntryStateGalleryDone extends CaptureEntryState {
  /// Creates a [CaptureEntryStateGalleryDone].
  ///
  /// Parameters:
  /// - [imagePaths]: Absolute file paths selected from the gallery.
  const CaptureEntryStateGalleryDone(this.imagePaths);

  /// Absolute file paths selected from the gallery.
  final List<String> imagePaths;
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ChangeNotifier ViewModel for the capture entry sheet.
///
/// Drives permission handling, camera intent launch, MediaStore query, and
/// gallery selection. Consumers observe [state] for UI updates.
class CaptureEntryViewModel extends ChangeNotifier {
  /// Creates a [CaptureEntryViewModel].
  ///
  /// Parameters:
  /// - [cameraService]: The [CameraService] used for all platform operations.
  CaptureEntryViewModel(this._cameraService);

  final CameraService _cameraService;

  CaptureEntryState _state = const CaptureEntryStateIdle();

  /// The current state of the capture entry flow.
  CaptureEntryState get state => _state;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Requests the CAMERA permission, then launches the device camera.
  ///
  /// The returned path from [CameraService.launchCamera] is used directly —
  /// no secondary gallery query is needed.
  ///
  /// State transitions:
  ///   idle → loading → permissionDenied | permissionPermanentlyDenied |
  ///                    cameraDone | cameraEmpty
  Future<void> requestCameraAndLaunch() async {
    _setState(const CaptureEntryStateLoading());

    final permissionStatus = await _cameraService.requestCameraPermission();

    switch (permissionStatus) {
      case CameraPermissionStatus.denied:
        _setState(const CaptureEntryStatePermissionDenied());
        return;
      case CameraPermissionStatus.permanentlyDenied:
        _setState(const CaptureEntryStatePermissionPermanentlyDenied());
        return;
      case CameraPermissionStatus.granted:
        break;
    }

    final String? path;
    try {
      path = await _cameraService.launchCamera();
    } on Exception catch (e, st) {
      log(
        'CaptureEntryViewModel: camera launch error: $e',
        name: 'CaptureEntryViewModel',
        error: e,
        stackTrace: st,
      );
      _setState(const CaptureEntryStateCameraEmpty());
      return;
    }

    if (path == null) {
      _setState(const CaptureEntryStateCameraEmpty());
    } else {
      _setState(CaptureEntryStateCameraDone([path]));
    }
  }

  /// Opens the system gallery picker and collects selected image paths.
  ///
  /// State transitions: idle → loading → galleryDone
  Future<void> launchGallery() async {
    _setState(const CaptureEntryStateLoading());
    final paths = await _cameraService.pickFromGallery();
    _setState(CaptureEntryStateGalleryDone(paths));
  }

  /// Resets the state back to [CaptureEntryStateIdle].
  ///
  /// Call this after the caller has consumed the result state.
  void reset() => _setState(const CaptureEntryStateIdle());

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  void _setState(CaptureEntryState newState) {
    _state = newState;
    notifyListeners();
  }
}
