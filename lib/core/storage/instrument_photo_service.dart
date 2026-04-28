// InstrumentPhotoService — manages photo files for instrument instances.
//
// Saves incoming photos (from image_picker) to a dedicated subdirectory
// under appDocDir:
//
//   <appDocDir>/instruments/<instanceId>/photo.jpg
//
// Only relative paths are stored in the database; resolution to absolute
// paths happens at call-time via [getAbsolutePath].
//
// The [dirProvider] can be overridden in tests to avoid touching the real
// file system.

import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Sub-directory under `appDocDir` where instrument photos are stored.
const String _kInstrumentsDir = 'instruments';

/// Fixed file name for the instrument photo within its instance directory.
const String _kPhotoFileName = 'photo.jpg';

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Manages JPEG photo files for instrument instances under `appDocDir`.
///
/// All public methods operate on relative paths (e.g.
/// `instruments/<instanceId>/photo.jpg`) that are safe to persist in the
/// database. Absolute path resolution always happens at call-time.
///
/// Inject [dirProvider] in tests to replace [getApplicationDocumentsDirectory]
/// with a temporary directory.
class InstrumentPhotoService {
  /// Creates an [InstrumentPhotoService].
  ///
  /// Parameters:
  /// - [dirProvider]: Async factory that returns the root application
  ///   documents directory. Defaults to [getApplicationDocumentsDirectory].
  InstrumentPhotoService({
    Future<Directory> Function()? dirProvider,
  }) : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Copies the file at [sourcePath] to the instrument photo location for
  /// [instanceId] and returns the relative path.
  ///
  /// The file is placed at
  /// `<appDocDir>/instruments/<instanceId>/photo.jpg`. Parent directories
  /// are created automatically. Any existing photo at that path is
  /// overwritten.
  ///
  /// Returns the relative path from `appDocDir`
  /// (e.g. `instruments/abc-123/photo.jpg`). Store this value in the
  /// database.
  ///
  /// Parameters:
  /// - [sourcePath]: Absolute path to the source image (from image_picker).
  /// - [instanceId]: The UUIDv4 of the owning instrument instance.
  Future<String> savePhoto(String sourcePath, String instanceId) async {
    final relativePath = _buildRelativePath(instanceId);
    final absPath = await _resolveAbsolute(relativePath);
    final destFile = File(absPath);

    await destFile.parent.create(recursive: true);
    await File(sourcePath).copy(destFile.path);

    log(
      'InstrumentPhotoService: saved photo → $relativePath',
      name: 'InstrumentPhotoService',
    );

    return relativePath;
  }

  /// Resolves [relativePath] to the absolute path under the current
  /// `appDocDir`.
  ///
  /// Parameters:
  /// - [relativePath]: A path relative to `appDocDir` as returned by
  ///   [savePhoto].
  Future<String> getAbsolutePath(String relativePath) =>
      _resolveAbsolute(relativePath);

  /// Deletes the photo at [relativePath].
  ///
  /// If the file does not exist the call is a no-op (idempotent). Other
  /// [FileSystemException] variants are re-thrown.
  ///
  /// Parameters:
  /// - [relativePath]: A path relative to `appDocDir` as returned by
  ///   [savePhoto].
  Future<void> deletePhoto(String relativePath) async {
    final absPath = await _resolveAbsolute(relativePath);
    final file = File(absPath);

    if (!file.existsSync()) {
      log(
        'InstrumentPhotoService: deletePhoto — not found, skipping: '
        '$relativePath',
        name: 'InstrumentPhotoService',
      );
      return;
    }

    await file.delete();
    log(
      'InstrumentPhotoService: deleted photo $relativePath',
      name: 'InstrumentPhotoService',
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Builds the relative path for an instance photo.
  ///
  /// Returns `instruments/<instanceId>/photo.jpg`.
  String _buildRelativePath(String instanceId) =>
      p.join(_kInstrumentsDir, instanceId, _kPhotoFileName);

  /// Joins [relativePath] with the current `appDocDir` to produce an absolute
  /// path.
  Future<String> _resolveAbsolute(String relativePath) async {
    final appDocDir = await _dirProvider();
    return p.join(appDocDir.path, relativePath);
  }
}
