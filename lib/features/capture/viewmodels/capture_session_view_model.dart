// capture_session_view_model.dart — ChangeNotifier ViewModel for an active
// capture session.
//
// Manages the in-memory list of [CapturePageDraft] objects created from
// gallery-selected or camera-captured image paths. The session is ephemeral:
// data lives only in memory until the user confirms the session and persists
// it via [NotationRepository].
//
// Architecture note:
//   View → CaptureSessionViewModel → FileReader (I/O abstraction)
//
// [FileReader] is an interface so that tests can substitute a fake without
// touching the filesystem.
//
// State exposed:
//   - [pages]: immutable snapshot list of current [CapturePageDraft] objects.
//
// Usage:
//   final vm = CaptureSessionViewModel();
//   await vm.loadFromPaths(imagePaths);
//   vm.addListener(() { ... });

import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// FileReader abstraction
// ---------------------------------------------------------------------------

/// Abstracts file reading so that [CaptureSessionViewModel] is testable
/// without real disk I/O.
abstract interface class FileReader {
  /// Reads the file at [path] and returns its raw bytes.
  ///
  /// Throws an [Exception] if the file cannot be read.
  Future<Uint8List> readAsBytes(String path);
}

/// Production [FileReader] backed by [dart:io] [File].
class DartIoFileReader implements FileReader {
  /// Creates a [DartIoFileReader].
  const DartIoFileReader();

  @override
  Future<Uint8List> readAsBytes(String path) async => File(path).readAsBytes();
}

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ChangeNotifier ViewModel that owns the in-memory list of
/// [CapturePageDraft] objects for the current capture session.
///
/// Consumers observe [pages] for UI updates. All mutating operations
/// call [notifyListeners] after updating the list.
class CaptureSessionViewModel extends ChangeNotifier {
  /// Creates a [CaptureSessionViewModel].
  ///
  /// Parameters:
  /// - [fileReader]: The [FileReader] used to read image bytes from disk.
  ///   Defaults to [DartIoFileReader] in production.
  CaptureSessionViewModel({FileReader? fileReader})
      : _fileReader = fileReader ?? const DartIoFileReader();

  final FileReader _fileReader;

  List<CapturePageDraft> _pages = [];

  /// The current ordered list of page drafts in this session.
  ///
  /// Returns an unmodifiable view; mutate via [addPage], [removePage],
  /// [updateRenderParams], [resetRenderParamsAt], [loadFromPaths], or [clear].
  List<CapturePageDraft> get pages => List.unmodifiable(_pages);

  /// A snapshot of every page's [RenderParams] keyed by 0-based page index.
  ///
  /// The returned map is unmodifiable. Keys are always contiguous from `0` to
  /// `pages.length - 1`. Use [updateRenderParams] or [resetRenderParamsAt] to
  /// change values.
  Map<int, RenderParams> get renderParamsMap => Map.unmodifiable({
        for (var i = 0; i < _pages.length; i++) i: _pages[i].renderParams,
      });

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Reads each path in [imagePaths] from disk and replaces the current
  /// session with the resulting [CapturePageDraft] list.
  ///
  /// Paths that cannot be read are skipped and logged; the session is still
  /// notified after all paths are processed.
  ///
  /// Parameters:
  /// - [imagePaths]: Absolute file paths to load.
  Future<void> loadFromPaths(List<String> imagePaths) async {
    final drafts = <CapturePageDraft>[];

    for (final path in imagePaths) {
      try {
        final bytes = await _fileReader.readAsBytes(path);
        drafts.add(
          CapturePageDraft(
            originalPath: path,
            originalBytes: bytes,
            renderParams: RenderParams.identity,
          ),
        );
      } on Exception catch (e, st) {
        log(
          'CaptureSessionViewModel: failed to read "$path": $e',
          name: 'CaptureSessionViewModel',
          error: e,
          stackTrace: st,
        );
      }
    }

    _pages = drafts;
    notifyListeners();
  }

  /// Appends [draft] to the end of the session page list.
  ///
  /// Parameters:
  /// - [draft]: The [CapturePageDraft] to add.
  void addPage(CapturePageDraft draft) {
    _pages = [..._pages, draft];
    notifyListeners();
  }

  /// Removes the draft at [index] from the session.
  ///
  /// No-op if [index] is out of bounds; does not throw.
  ///
  /// Parameters:
  /// - [index]: 0-based position of the draft to remove.
  void removePage(int index) {
    if (index < 0 || index >= _pages.length) return;
    final updated = List<CapturePageDraft>.from(_pages)..removeAt(index);
    _pages = updated;
    notifyListeners();
  }

  /// Replaces the [RenderParams] of the draft at [index].
  ///
  /// No-op if [index] is out of bounds; does not throw.
  ///
  /// Parameters:
  /// - [index]: 0-based position of the target draft.
  /// - [params]: The replacement [RenderParams].
  void updateRenderParams(int index, RenderParams params) {
    if (index < 0 || index >= _pages.length) return;
    final updated = List<CapturePageDraft>.from(_pages);
    updated[index] = _pages[index].copyWith(renderParams: params);
    _pages = updated;
    notifyListeners();
  }

  /// Resets the [RenderParams] of the draft at [index] to [RenderParams.identity].
  ///
  /// No-op if [index] is out of bounds; does not throw.
  ///
  /// Parameters:
  /// - [index]: 0-based position of the target draft.
  void resetRenderParamsAt(int index) {
    if (index < 0 || index >= _pages.length) return;
    updateRenderParams(index, RenderParams.identity);
  }

  /// Replaces the entire page list with [drafts].
  ///
  /// Used by [PageEditorViewModel] when reordering pages. Callers are
  /// responsible for ensuring the list is a valid permutation of the current
  /// session pages.
  ///
  /// Parameters:
  /// - [drafts]: The replacement ordered list of [CapturePageDraft] objects.
  void replacePages(List<CapturePageDraft> drafts) {
    _pages = List<CapturePageDraft>.unmodifiable(drafts);
    notifyListeners();
  }

  /// Clears all drafts from the session.
  void clear() {
    _pages = [];
    notifyListeners();
  }
}
