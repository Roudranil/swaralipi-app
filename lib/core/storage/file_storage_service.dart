// FileStorageService — manages JPEG image files for notation pages.
//
// Writes original images under <appDocDir>/notations/<notationId>/ and
// exposes helpers to resolve, delete, and clean up those files. Only relative
// paths are stored in the database; all resolution to absolute paths happens
// at runtime via [getAbsolutePath].
//
// The [dirProvider] constructor parameter defaults to
// [getApplicationDocumentsDirectory] from `path_provider` and can be
// overridden in unit tests to inject a temporary directory without touching
// the real file system.

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The sub-directory under `appDocDir` where notation images are stored.
const String _kNotationsDir = 'notations';

/// Suffix appended to every original page file name.
const String _kOriginalSuffix = '_original.jpg';

/// Manages JPEG image files for notation pages under `appDocDir`.
///
/// All public methods operate on relative paths (e.g.
/// `notations/<notationId>/page_0_original.jpg`) that are safe to persist in
/// the database. Absolute path resolution always happens at call-time so that
/// paths remain valid if the device's `appDocDir` changes between app
/// versions.
///
/// Inject [dirProvider] in tests to replace the real [getApplicationDocumentsDirectory]
/// with a temporary directory.
class FileStorageService {
  /// Creates a [FileStorageService].
  ///
  /// Parameters:
  /// - [dirProvider]: Async factory that returns the root application
  ///   documents directory. Defaults to [getApplicationDocumentsDirectory].
  ///   Override in unit tests to provide a temporary directory.
  FileStorageService({
    Future<Directory> Function()? dirProvider,
  }) : _dirProvider = dirProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _dirProvider;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Writes [bytes] as a JPEG file for [notationId] at [pageIndex].
  ///
  /// The file is placed at
  /// `<appDocDir>/notations/<notationId>/page_<pageIndex>_original.jpg`.
  /// Parent directories are created automatically. If a file already exists
  /// at that path it is overwritten.
  ///
  /// Returns the relative path from `appDocDir` to the written file
  /// (e.g. `notations/abc-123/page_0_original.jpg`). Store this value in the
  /// database and resolve it later with [getAbsolutePath].
  ///
  /// Parameters:
  /// - [bytes]: The raw JPEG bytes to persist.
  /// - [notationId]: The UUIDv4 identifier of the owning notation.
  /// - [pageIndex]: The zero-based page index used to build the file name.
  Future<String> saveImage(
    Uint8List bytes,
    String notationId,
    int pageIndex,
  ) async {
    final relativePath = _buildRelativePath(notationId, pageIndex);
    final absPath = await _resolveAbsolute(relativePath);
    final file = File(absPath);

    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);

    log(
      'FileStorageService: saved ${bytes.length} bytes → $relativePath',
      name: 'FileStorageService',
    );

    return relativePath;
  }

  /// Resolves [relativePath] to the absolute path under the current
  /// `appDocDir`.
  ///
  /// Re-root is performed at call-time so the result is always valid even
  /// after app updates that may change `appDocDir` on some platforms.
  ///
  /// Parameters:
  /// - [relativePath]: A path relative to `appDocDir` as returned by
  ///   [saveImage].
  Future<String> getAbsolutePath(String relativePath) {
    return _resolveAbsolute(relativePath);
  }

  /// Deletes the file at [relativePath].
  ///
  /// If the file does not exist the call is a no-op (idempotent). Other
  /// [FileSystemException] variants are re-thrown so callers can handle
  /// unexpected errors.
  ///
  /// Parameters:
  /// - [relativePath]: A path relative to `appDocDir` as returned by
  ///   [saveImage].
  Future<void> deletePageFile(String relativePath) async {
    final absPath = await _resolveAbsolute(relativePath);
    final file = File(absPath);

    if (!file.existsSync()) {
      log(
        'FileStorageService: deletePageFile — file not found, skipping: '
        '$relativePath',
        name: 'FileStorageService',
      );
      return;
    }

    await file.delete();
    log(
      'FileStorageService: deleted page file $relativePath',
      name: 'FileStorageService',
    );
  }

  /// Returns the relative paths of all JPEG files under
  /// `appDocDir/notations/` that are not present in [knownRelativePaths].
  ///
  /// The scan walks the entire `notations/` subtree and collects every file
  /// whose name ends with `.jpg`. A file is considered an orphan when its
  /// relative path (relative to `appDocDir`) is not contained in
  /// [knownRelativePaths].
  ///
  /// Returns an empty list when the `notations/` directory does not exist, or
  /// when all discovered JPEG files are known.
  ///
  /// Parameters:
  /// - [knownRelativePaths]: The complete set of relative paths currently
  ///   referenced by the database (e.g. from [NotationPageDao.getAllImagePaths]).
  Future<List<String>> scanOrphans(
    List<String> knownRelativePaths,
  ) async {
    final appDocDir = await _dirProvider();
    final notationsDir = Directory(
      p.join(appDocDir.path, _kNotationsDir),
    );

    if (!notationsDir.existsSync()) {
      log(
        'FileStorageService.scanOrphans: notations directory not found, '
        'no orphans to report',
        name: 'FileStorageService',
      );
      return [];
    }

    final knownSet = Set<String>.unmodifiable(knownRelativePaths);
    final orphans = <String>[];

    await for (final entity in notationsDir.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.jpg')) continue;

      final relativePath = p.relative(entity.path, from: appDocDir.path);
      if (!knownSet.contains(relativePath)) {
        orphans.add(relativePath);
      }
    }

    log(
      'FileStorageService.scanOrphans: found ${orphans.length} orphan(s)',
      name: 'FileStorageService',
    );
    return List.unmodifiable(orphans);
  }

  /// Deletes every file listed in [orphanPaths].
  ///
  /// Each path is resolved to an absolute path via [getAbsolutePath] and then
  /// deleted. If a file is already absent the call is silently skipped
  /// (idempotent). Unexpected [FileSystemException] types are re-thrown so
  /// callers can handle them.
  ///
  /// Parameters:
  /// - [orphanPaths]: Relative paths returned by [scanOrphans].
  Future<void> purgeOrphans(List<String> orphanPaths) async {
    if (orphanPaths.isEmpty) return;

    for (final relativePath in orphanPaths) {
      await deletePageFile(relativePath);
    }

    log(
      'FileStorageService.purgeOrphans: purged ${orphanPaths.length} '
      'orphan file(s)',
      name: 'FileStorageService',
    );
  }

  /// Deletes the entire `notations/<notationId>/` directory and all its
  /// contents.
  ///
  /// If the directory does not exist the call is a no-op (idempotent). Other
  /// [FileSystemException] variants are re-thrown.
  ///
  /// Parameters:
  /// - [notationId]: The UUIDv4 identifier of the notation whose directory
  ///   should be removed.
  Future<void> deleteNotationDirectory(String notationId) async {
    final appDocDir = await _dirProvider();
    final dirPath = p.join(appDocDir.path, _kNotationsDir, notationId);
    final dir = Directory(dirPath);

    if (!dir.existsSync()) {
      log(
        'FileStorageService: deleteNotationDirectory — directory not found, '
        'skipping: $notationId',
        name: 'FileStorageService',
      );
      return;
    }

    await dir.delete(recursive: true);
    log(
      'FileStorageService: deleted notation directory for $notationId',
      name: 'FileStorageService',
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Builds the relative path for a page image.
  ///
  /// Returns [relativePath]:
  ///   `notations/<notationId>/page_<pageIndex>_original.jpg`
  String _buildRelativePath(String notationId, int pageIndex) {
    return p.join(
      _kNotationsDir,
      notationId,
      'page_$pageIndex$_kOriginalSuffix',
    );
  }

  /// Joins [relativePath] with the current `appDocDir` to produce an absolute
  /// path.
  Future<String> _resolveAbsolute(String relativePath) async {
    final appDocDir = await _dirProvider();
    return p.join(appDocDir.path, relativePath);
  }
}
