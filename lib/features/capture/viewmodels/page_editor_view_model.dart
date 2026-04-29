// page_editor_view_model.dart — ChangeNotifier ViewModel for PageEditorScreen.
//
// Wraps [CaptureSessionViewModel] to add per-page editing state:
// active page selection, filter changes, rotate, reset, crop, and reorder.
//
// Architecture:
//   PageEditorScreen → PageEditorViewModel → CaptureSessionViewModel
//
// [PageEditorViewModel] listens to [CaptureSessionViewModel] and re-notifies
// its own listeners whenever the session changes, so the screen only needs to
// observe one ChangeNotifier.
//
// Lifecycle:
//   Must be disposed before its [CaptureSessionViewModel] is disposed.

import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Valid rotation step in degrees for CW / CCW operations.
const int _kRotationStep = 90;

/// Number of degrees in a full rotation.
const int _kFullRotation = 360;

// ---------------------------------------------------------------------------
// ViewModel
// ---------------------------------------------------------------------------

/// ChangeNotifier ViewModel that manages per-page editing for
/// [PageEditorScreen].
///
/// Delegates page-list mutations to [CaptureSessionViewModel] and owns the
/// [activePageIndex] selection state. Consumers observe this ViewModel; they
/// do not need to observe [CaptureSessionViewModel] directly.
class PageEditorViewModel extends ChangeNotifier {
  /// Creates a [PageEditorViewModel].
  ///
  /// Parameters:
  /// - [session]: The [CaptureSessionViewModel] that owns the page list.
  PageEditorViewModel({required CaptureSessionViewModel session})
      : _session = session {
    _session.addListener(_onSessionChanged);
  }

  final CaptureSessionViewModel _session;

  int _activePageIndex = 0;

  // -------------------------------------------------------------------------
  // Read-only state
  // -------------------------------------------------------------------------

  /// The current ordered list of page drafts, delegated from [session].
  List<CapturePageDraft> get pages => _session.pages;

  /// 0-based index of the currently selected page in the editor.
  int get activePageIndex => _activePageIndex;

  /// The currently active [CapturePageDraft], or `null` if the session is
  /// empty.
  CapturePageDraft? get activePage =>
      pages.isEmpty ? null : pages[_activePageIndex];

  // -------------------------------------------------------------------------
  // Page selection
  // -------------------------------------------------------------------------

  /// Sets the active page to [index].
  ///
  /// No-op if [index] is out of bounds for the current page list.
  ///
  /// Parameters:
  /// - [index]: 0-based position to activate.
  void setActivePage(int index) {
    if (index < 0 || index >= pages.length) return;
    if (_activePageIndex == index) return;
    _activePageIndex = index;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Filter
  // -------------------------------------------------------------------------

  /// Applies [filter] to the active page's [RenderParams].
  ///
  /// No-op when the session is empty.
  ///
  /// Parameters:
  /// - [filter]: The [NotationFilter] to apply.
  void setFilter(NotationFilter filter) {
    if (pages.isEmpty) return;
    final current = pages[_activePageIndex].renderParams;
    _session.updateRenderParams(
      _activePageIndex,
      current.copyWith(filter: filter),
    );
  }

  // -------------------------------------------------------------------------
  // Rotation
  // -------------------------------------------------------------------------

  /// Rotates the active page 90° clockwise.
  ///
  /// Wraps from 270° back to 0°. No-op when the session is empty.
  void rotateClockwise() {
    if (pages.isEmpty) return;
    final current = pages[_activePageIndex].renderParams;
    final newDegrees =
        (current.rotationDegrees + _kRotationStep) % _kFullRotation;
    _session.updateRenderParams(
      _activePageIndex,
      current.copyWith(rotationDegrees: newDegrees),
    );
  }

  /// Rotates the active page 90° counter-clockwise.
  ///
  /// Wraps from 0° to 270°. No-op when the session is empty.
  void rotateCounterClockwise() {
    if (pages.isEmpty) return;
    final current = pages[_activePageIndex].renderParams;
    final newDegrees =
        (current.rotationDegrees - _kRotationStep + _kFullRotation) %
            _kFullRotation;
    _session.updateRenderParams(
      _activePageIndex,
      current.copyWith(rotationDegrees: newDegrees),
    );
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /// Resets the active page's [RenderParams] to [RenderParams.identity].
  ///
  /// No-op when the session is empty.
  void resetRenderParams() {
    if (pages.isEmpty) return;
    _session.updateRenderParams(_activePageIndex, RenderParams.identity);
  }

  // -------------------------------------------------------------------------
  // Crop
  // -------------------------------------------------------------------------

  /// Updates the crop region for the active page.
  ///
  /// Pass `null` to clear any existing crop (full image).
  ///
  /// Parameters:
  /// - [cropRect]: Normalized [CropRect], or `null` to clear the crop.
  void setCropRect(CropRect? cropRect) {
    if (pages.isEmpty) return;
    final current = pages[_activePageIndex].renderParams;
    _session.updateRenderParams(
      _activePageIndex,
      cropRect != null
          ? current.copyWith(cropRect: cropRect)
          : current.copyWith(clearCropRect: true),
    );
  }

  // -------------------------------------------------------------------------
  // Reorder
  // -------------------------------------------------------------------------

  /// Moves the page at [oldIndex] to [newIndex].
  ///
  /// Uses [ReorderableListView]'s convention: if [newIndex] > [oldIndex], the
  /// caller must subtract 1 before passing here (the Flutter framework passes
  /// the post-removal index). This method performs the subtraction internally
  /// to keep callers simple.
  ///
  /// Parameters:
  /// - [oldIndex]: Source position.
  /// - [newIndex]: Destination position (raw value from
  ///   [ReorderableListView.onReorder]).
  void reorderPages(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= pages.length) return;
    // Flutter's ReorderableListView passes newIndex after removal of the item,
    // so subtract 1 when the item moved forward.
    final adjustedNew = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjustedNew < 0 || adjustedNew >= pages.length) return;

    // Track active page to follow the moved item.
    final String activePath = pages[_activePageIndex].originalPath;

    final mutable = List<CapturePageDraft>.from(pages);
    final moved = mutable.removeAt(oldIndex);
    mutable.insert(adjustedNew, moved);

    _session.replacePages(mutable);
    // _onSessionChanged fires synchronously via replacePages → notifyListeners.

    // Re-anchor active index to the same page after reorder.
    final newActiveIndex =
        mutable.indexWhere((d) => d.originalPath == activePath);
    if (newActiveIndex >= 0 && newActiveIndex != _activePageIndex) {
      _activePageIndex = newActiveIndex;
      notifyListeners();
    }

    log(
      'PageEditorViewModel: reordered page $oldIndex → $adjustedNew',
      name: 'PageEditorViewModel',
    );
  }

  // -------------------------------------------------------------------------
  // Remove
  // -------------------------------------------------------------------------

  /// Removes the page at [index] from the session.
  ///
  /// Adjusts [activePageIndex] so it remains in bounds after removal.
  ///
  /// Parameters:
  /// - [index]: 0-based position to remove.
  void removePage(int index) {
    if (index < 0 || index >= pages.length) return;
    _session.removePage(index);
    // After removal, clamp or adjust activePageIndex.
    // _onSessionChanged fires via session listener and calls notifyListeners.
    if (pages.isEmpty) {
      _activePageIndex = 0;
    } else if (index <= _activePageIndex && _activePageIndex > 0) {
      // Active page was removed (index == _activePageIndex) or was after the
      // removed item (index < _activePageIndex): shift down by one.
      _activePageIndex = _activePageIndex - 1;
    } else if (_activePageIndex >= pages.length) {
      _activePageIndex = pages.length - 1;
    }
  }

  // -------------------------------------------------------------------------
  // Private
  // -------------------------------------------------------------------------

  void _onSessionChanged() {
    // Clamp active index if pages were removed externally.
    if (pages.isNotEmpty && _activePageIndex >= pages.length) {
      _activePageIndex = pages.length - 1;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }
}
