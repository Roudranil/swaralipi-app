// page_editor_screen.dart — full per-page editor for captured notation pages.
//
// Route: /capture/editor
//
// Shows:
//   - A main preview area for the active page with live filter applied via
//     [ColorFiltered] (GPU — no compute isolate needed for filter-only changes).
//   - A draggable thumbnail strip (ReorderableListView) at the bottom.
//   - A per-page toolbar: filter chips, rotate CW/CCW, crop, reset.
//   - A "Next" FAB that calls [onNext] to navigate to MetadataFormScreen.
//
// Architecture:
//   This screen is purely presentational. All state mutations are delegated to
//   [PageEditorViewModel] which in turn delegates to [CaptureSessionViewModel].
//
// Dependency injection:
//   Both [CaptureSessionViewModel] and [PageEditorViewModel] must be provided
//   above this screen via [ChangeNotifierProvider].

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/page_editor_view_model.dart';
import 'package:swaralipi/shared/models/render_params.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Height of the reorderable thumbnail strip.
const double _kThumbnailStripHeight = 88.0;

/// Width/height of individual thumbnail tiles.
const double _kThumbnailSize = 72.0;

/// Horizontal padding inside the thumbnail strip.
const EdgeInsets _kStripPadding =
    EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0);

/// Height of the per-page action toolbar.
const double _kToolbarHeight = 56.0;

/// Spacing between toolbar action buttons.
const double _kToolbarSpacing = 4.0;

/// Width of the expanded animated filter side panel.
const double _kFilterPanelWidth = 180.0;

/// Animation duration for the filter side panel open/close.
const Duration _kFilterPanelDuration = Duration(milliseconds: 250);

/// Corner radius for the left edge of the filter side panel.
const double _kFilterPanelRadius = 12.0;

/// Border radius for thumbnail tiles.
const double _kThumbnailRadius = 8.0;

/// Size of delete icon buttons on thumbnails.
const double _kDeleteButtonSize = 28.0;

/// Minimum vertical fraction of the crop area (prevents zero-height crops).
const double _kMinCropFraction = 0.05;

// ---------------------------------------------------------------------------
// ColorMatrix filter definitions
// ---------------------------------------------------------------------------

/// Maps [NotationFilter] values to a 4×5 RGBA color matrix for use with
/// [ColorFiltered]. Matrices are sourced from standard image-processing
/// references.
const Map<NotationFilter, List<double>> _kFilterMatrices = {
  NotationFilter.none: [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    0, 0, 0, 1, 0,
  ],
  NotationFilter.grayscale: [
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ],
  NotationFilter.blackAndWhite: [
    1.5, 1.5, 1.5, 0, -1.0 * 255 * 0.75, //
    1.5, 1.5, 1.5, 0, -1.0 * 255 * 0.75,
    1.5, 1.5, 1.5, 0, -1.0 * 255 * 0.75,
    0, 0, 0, 1, 0,
  ],
  NotationFilter.tintWarm: [
    1.2, 0, 0, 0, 10, //
    0, 1.0, 0, 0, 0,
    0, 0, 0.8, 0, -10,
    0, 0, 0, 1, 0,
  ],
  NotationFilter.tintCool: [
    0.8, 0, 0, 0, -10, //
    0, 1.0, 0, 0, 0,
    0, 0, 1.2, 0, 10,
    0, 0, 0, 1, 0,
  ],
};

/// Display label for each [NotationFilter].
const Map<NotationFilter, String> _kFilterLabels = {
  NotationFilter.none: 'Original',
  NotationFilter.grayscale: 'Grayscale',
  NotationFilter.blackAndWhite: 'B&W',
  NotationFilter.tintWarm: 'Warm',
  NotationFilter.tintCool: 'Cool',
};

/// Semantic key suffix for each [NotationFilter] chip.
const Map<NotationFilter, String> _kFilterKeyNames = {
  NotationFilter.none: 'none',
  NotationFilter.grayscale: 'grayscale',
  NotationFilter.blackAndWhite: 'black_and_white',
  NotationFilter.tintWarm: 'tint_warm',
  NotationFilter.tintCool: 'tint_cool',
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-page editor screen for reviewing and adjusting captured notation pages.
///
/// Observes [PageEditorViewModel] for page list, active page, and render
/// params. All user interactions delegate to the ViewModel.
///
/// The [onNext] callback is invoked when the user taps the "Next" FAB and
/// should navigate to [MetadataFormScreen].
class PageEditorScreen extends StatelessWidget {
  /// Creates a [PageEditorScreen].
  ///
  /// Parameters:
  /// - [onNext]: Callback invoked with the current [BuildContext] when the
  ///   user confirms the page set and wants to proceed to metadata entry.
  const PageEditorScreen({
    super.key,
    required this.onNext,
  });

  /// Called when the user taps "Next".
  final void Function(BuildContext context) onNext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Editor'),
        centerTitle: false,
      ),
      floatingActionButton: Consumer<PageEditorViewModel>(
        builder: (context, vm, _) {
          if (vm.pages.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            key: const Key('page_editor_next_fab'),
            onPressed: () => onNext(context),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          );
        },
      ),
      body: Consumer<PageEditorViewModel>(
        builder: (context, vm, _) {
          if (vm.pages.isEmpty) {
            return const _EmptyState();
          }
          return _EditorBody(vm: vm);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      key: const Key('page_editor_empty_state'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64.0,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16.0),
          Text(
            'No pages selected',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Go back and select images from the gallery or camera.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor body
// ---------------------------------------------------------------------------

class _EditorBody extends StatefulWidget {
  const _EditorBody({required this.vm});

  final PageEditorViewModel vm;

  @override
  State<_EditorBody> createState() => _EditorBodyState();
}

class _EditorBodyState extends State<_EditorBody> {
  /// Whether the filter side panel is currently open.
  bool _filtersExpanded = false;

  void _toggleFilters() {
    setState(() => _filtersExpanded = !_filtersExpanded);
  }

  void _collapseFilters() {
    if (_filtersExpanded) {
      setState(() => _filtersExpanded = false);
    }
  }

  void _applyFilterAndCollapse(NotationFilter filter) {
    widget.vm.setFilter(filter);
    setState(() => _filtersExpanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final pageCount = widget.vm.pages.length;
    final countLabel = pageCount == 1 ? '1 page' : '$pageCount pages';

    return Column(
      children: [
        // Page count label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(countLabel, style: textTheme.labelLarge),
          ),
        ),
        // Active page preview with animated filter panel overlay
        Expanded(
          child: Stack(
            children: [
              // Image preview — tap outside to collapse filters
              GestureDetector(
                key: const Key('page_editor_image_preview'),
                onTap: _collapseFilters,
                behavior: HitTestBehavior.opaque,
                child: _ActivePagePreview(vm: widget.vm),
              ),
              // Animated filter panel sliding in from the right
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: _kFilterPanelDuration,
                  curve: Curves.easeInOut,
                  width: _filtersExpanded ? _kFilterPanelWidth : 0,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(_kFilterPanelRadius),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _filtersExpanded
                      ? _FilterPanel(
                          vm: widget.vm,
                          onFilterSelected: _applyFilterAndCollapse,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
        // Per-page action toolbar — includes Filters toggle button
        _PageActionBar(vm: widget.vm, onToggleFilters: _toggleFilters),
        // Thumbnail strip at bottom
        _ThumbnailStrip(vm: widget.vm),
        // Safe-area padding for FAB overlap
        const SizedBox(height: 72.0),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Active page preview
// ---------------------------------------------------------------------------

/// Renders the active page with its [RenderParams] applied.
///
/// Filters are applied via [ColorFiltered] for zero-cost GPU preview.
/// Rotation is applied via [RotatedBox].
class _ActivePagePreview extends StatelessWidget {
  const _ActivePagePreview({required this.vm});

  final PageEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final draft = vm.activePage;

    if (draft == null) return const SizedBox.shrink();

    final params = draft.renderParams;
    final matrix = _kFilterMatrices[params.filter] ??
        _kFilterMatrices[NotationFilter.none]!;
    final quarterTurns = params.rotationDegrees ~/ 90;

    Widget image = Image.memory(
      draft.originalBytes,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.broken_image_outlined,
        size: 64.0,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    // Apply crop as a fractional ClipRect if a cropRect is set.
    if (params.cropRect != null) {
      final crop = params.cropRect!;
      image = FractionallySizedBox(
        widthFactor: crop.right - crop.left,
        heightFactor: crop.bottom - crop.top,
        child: OverflowBox(
          alignment: Alignment(
            (crop.left + crop.right) - 1.0,
            (crop.top + crop.bottom) - 1.0,
          ),
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          child: image,
        ),
      );
    }

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(matrix),
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: SizedBox.expand(child: Center(child: image)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter panel (vertical list in side panel)
// ---------------------------------------------------------------------------

/// Vertical list of filter options shown inside the animated side panel.
///
/// Renders one [ListTile] per [NotationFilter] value. Tapping a tile calls
/// [onFilterSelected] which applies the filter and collapses the panel.
class _FilterPanel extends StatelessWidget {
  /// Creates a [_FilterPanel].
  ///
  /// Parameters:
  /// - [vm]: The [PageEditorViewModel] supplying the active filter.
  /// - [onFilterSelected]: Called when the user taps a filter option.
  const _FilterPanel({
    required this.vm,
    required this.onFilterSelected,
  });

  /// The [PageEditorViewModel] for reading the currently active filter.
  final PageEditorViewModel vm;

  /// Callback invoked with the chosen [NotationFilter].
  final void Function(NotationFilter) onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final activeFilter =
        vm.activePage?.renderParams.filter ?? NotationFilter.none;

    return ListView(
      key: const Key('page_editor_filter_panel'),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      children: NotationFilter.values.map((filter) {
        final label = _kFilterLabels[filter] ?? filter.name;
        final keyName = _kFilterKeyNames[filter] ?? filter.name;
        final isActive = activeFilter == filter;
        return ListTile(
          key: Key('filter_panel_item_$keyName'),
          dense: true,
          title: Text(label),
          selected: isActive,
          onTap: () => onFilterSelected(filter),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-page action bar
// ---------------------------------------------------------------------------

/// Toolbar row with Filters, crop, rotate CW/CCW, and reset action buttons.
class _PageActionBar extends StatelessWidget {
  /// Creates a [_PageActionBar].
  ///
  /// Parameters:
  /// - [vm]: The [PageEditorViewModel] for action delegates.
  /// - [onToggleFilters]: Called when the Filters icon button is tapped.
  const _PageActionBar({
    required this.vm,
    required this.onToggleFilters,
  });

  /// The [PageEditorViewModel] for action delegates.
  final PageEditorViewModel vm;

  /// Called when the Filters toggle button is tapped.
  final VoidCallback onToggleFilters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kToolbarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Filters
          Semantics(
            label: 'Toggle filters panel',
            button: true,
            child: IconButton(
              key: const Key('page_editor_filters_button'),
              tooltip: 'Filters',
              icon: const Icon(Icons.tune_outlined),
              onPressed: onToggleFilters,
            ),
          ),
          const SizedBox(width: _kToolbarSpacing),
          // Crop
          Semantics(
            label: 'Crop page',
            button: true,
            child: IconButton(
              key: const Key('page_editor_crop_button'),
              tooltip: 'Crop',
              icon: const Icon(Icons.crop),
              onPressed: () => _showCropOverlay(context, vm),
            ),
          ),
          const SizedBox(width: _kToolbarSpacing),
          // Rotate CCW
          Semantics(
            label: 'Rotate counter-clockwise',
            button: true,
            child: IconButton(
              key: const Key('page_editor_rotate_ccw'),
              tooltip: 'Rotate left',
              icon: const Icon(Icons.rotate_left),
              onPressed: vm.rotateCounterClockwise,
            ),
          ),
          const SizedBox(width: _kToolbarSpacing),
          // Rotate CW
          Semantics(
            label: 'Rotate clockwise',
            button: true,
            child: IconButton(
              key: const Key('page_editor_rotate_cw'),
              tooltip: 'Rotate right',
              icon: const Icon(Icons.rotate_right),
              onPressed: vm.rotateClockwise,
            ),
          ),
          const SizedBox(width: _kToolbarSpacing),
          // Reset
          Semantics(
            label: 'Reset page adjustments',
            button: true,
            child: IconButton(
              key: const Key('page_editor_reset'),
              tooltip: 'Reset',
              icon: const Icon(Icons.refresh),
              onPressed: vm.resetRenderParams,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCropOverlay(
    BuildContext context,
    PageEditorViewModel vm,
  ) async {
    final draft = vm.activePage;
    if (draft == null) return;

    final result = await Navigator.of(context).push<CropRect?>(
      MaterialPageRoute<CropRect?>(
        fullscreenDialog: true,
        builder: (_) => _CropOverlayScreen(
          imageBytes: draft.originalBytes,
          initialCrop: draft.renderParams.cropRect,
        ),
      ),
    );

    if (!context.mounted) return;
    if (result != null) {
      vm.setCropRect(result);
    }
  }
}

// ---------------------------------------------------------------------------
// Thumbnail strip
// ---------------------------------------------------------------------------

/// Horizontally reorderable thumbnail strip.
///
/// Tapping a thumbnail activates it in [PageEditorViewModel]. Long-pressing
/// enables drag-to-reorder via [ReorderableListView].
class _ThumbnailStrip extends StatelessWidget {
  const _ThumbnailStrip({required this.vm});

  final PageEditorViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const Key('page_editor_thumbnail_strip'),
      height: _kThumbnailStripHeight,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: _kStripPadding,
        buildDefaultDragHandles: false,
        onReorder: vm.reorderPages,
        itemCount: vm.pages.length,
        itemBuilder: (context, index) {
          final draft = vm.pages[index];
          final isActive = index == vm.activePageIndex;
          return ReorderableDragStartListener(
            key: ValueKey(draft.originalPath),
            index: index,
            child: _ThumbnailTile(
              draft: draft,
              index: index,
              isActive: isActive,
              onTap: () => vm.setActivePage(index),
              onDelete: () => _confirmDelete(context, vm, index),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PageEditorViewModel vm,
    int index,
  ) async {
    if (vm.pages.length == 1) {
      // Last page — show confirmation dialog.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _LastPageDeleteDialog(),
      );
      if (!context.mounted) return;
      if (confirmed == true) vm.removePage(index);
    } else {
      vm.removePage(index);
    }
  }
}

// ---------------------------------------------------------------------------
// Thumbnail tile
// ---------------------------------------------------------------------------

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({
    required this.draft,
    required this.index,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  final CapturePageDraft draft;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Page ${index + 1}${isActive ? ", active" : ""}',
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            children: [
              Container(
                width: _kThumbnailSize,
                height: _kThumbnailSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_kThumbnailRadius),
                  border: isActive
                      ? Border.all(
                          color: colorScheme.primary,
                          width: 2.5,
                        )
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: _ThumbnailImage(bytes: draft.originalBytes),
              ),
              // Delete button overlay
              Positioned(
                top: 0,
                right: 0,
                child: Semantics(
                  label: 'Delete page ${index + 1}',
                  button: true,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      key: Key('thumbnail_delete_$index'),
                      width: _kDeleteButtonSize,
                      height: _kDeleteButtonSize,
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16.0,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Thumbnail image
// ---------------------------------------------------------------------------

class _ThumbnailImage extends StatelessWidget {
  const _ThumbnailImage({required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return bytes.isNotEmpty
        ? Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: _kThumbnailSize,
            height: _kThumbnailSize,
            errorBuilder: (_, __, ___) => _placeholder(colorScheme),
          )
        : _placeholder(colorScheme);
  }

  Widget _placeholder(ColorScheme colorScheme) => ColoredBox(
        color: colorScheme.surfaceContainerHigh,
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      );
}

// ---------------------------------------------------------------------------
// Last page delete dialog
// ---------------------------------------------------------------------------

/// Confirmation dialog shown when the user attempts to delete the last page.
class _LastPageDeleteDialog extends StatelessWidget {
  const _LastPageDeleteDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('last_page_delete_dialog'),
      title: const Text('Delete last page?'),
      content: const Text(
        'Removing the last page will clear the current session.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Crop overlay screen
// ---------------------------------------------------------------------------

/// Full-screen crop UI with draggable corner handles painted over the image.
///
/// Returns the confirmed [CropRect] via [Navigator.pop], or `null` if
/// cancelled.
class _CropOverlayScreen extends StatefulWidget {
  /// Creates a [_CropOverlayScreen].
  ///
  /// Parameters:
  /// - [imageBytes]: Raw bytes of the image to crop.
  /// - [initialCrop]: Pre-existing crop to start from; defaults to full image.
  const _CropOverlayScreen({
    required this.imageBytes,
    this.initialCrop,
  });

  final Uint8List imageBytes;
  final CropRect? initialCrop;

  @override
  State<_CropOverlayScreen> createState() => _CropOverlayScreenState();
}

class _CropOverlayScreenState extends State<_CropOverlayScreen> {
  late CropRect _crop;

  @override
  void initState() {
    super.initState();
    _crop = widget.initialCrop ??
        const CropRect(left: 0.0, top: 0.0, right: 1.0, bottom: 1.0);
  }

  void _onHandleDrag(
    _CropHandle handle,
    DragUpdateDetails details,
    BoxConstraints constraints,
  ) {
    final dx = details.delta.dx / constraints.maxWidth;
    final dy = details.delta.dy / constraints.maxHeight;

    setState(() {
      switch (handle) {
        case _CropHandle.topLeft:
          _crop = CropRect(
            left: (_crop.left + dx).clamp(0.0, _crop.right - _kMinCropFraction),
            top: (_crop.top + dy).clamp(0.0, _crop.bottom - _kMinCropFraction),
            right: _crop.right,
            bottom: _crop.bottom,
          );
        case _CropHandle.topRight:
          _crop = CropRect(
            left: _crop.left,
            top: (_crop.top + dy).clamp(0.0, _crop.bottom - _kMinCropFraction),
            right:
                (_crop.right + dx).clamp(_crop.left + _kMinCropFraction, 1.0),
            bottom: _crop.bottom,
          );
        case _CropHandle.bottomLeft:
          _crop = CropRect(
            left: (_crop.left + dx).clamp(0.0, _crop.right - _kMinCropFraction),
            top: _crop.top,
            right: _crop.right,
            bottom:
                (_crop.bottom + dy).clamp(_crop.top + _kMinCropFraction, 1.0),
          );
        case _CropHandle.bottomRight:
          _crop = CropRect(
            left: _crop.left,
            top: _crop.top,
            right:
                (_crop.right + dx).clamp(_crop.left + _kMinCropFraction, 1.0),
            bottom:
                (_crop.bottom + dy).clamp(_crop.top + _kMinCropFraction, 1.0),
          );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop'),
        actions: [
          Semantics(
            label: 'Confirm crop',
            button: true,
            child: TextButton(
              key: const Key('crop_overlay_confirm'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(_crop),
              child: const Text('Done'),
            ),
          ),
        ],
        leading: Semantics(
          label: 'Cancel crop',
          button: true,
          child: IconButton(
            key: const Key('crop_overlay_cancel'),
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(null),
          ),
        ),
      ),
      body: KeyedSubtree(
        key: const Key('page_editor_crop_overlay'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Image background
                Center(
                  child: Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.broken_image_outlined,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Crop overlay painter
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _CropOverlayPainter(crop: _crop),
                ),
                // Drag handles
                ..._CropHandle.values.map(
                  (handle) => _buildHandle(context, handle, constraints),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHandle(
    BuildContext context,
    _CropHandle handle,
    BoxConstraints constraints,
  ) {
    const double handleSize = 28.0;
    final w = constraints.maxWidth;
    final h = constraints.maxHeight;

    final (double left, double top) = switch (handle) {
      _CropHandle.topLeft => (
          _crop.left * w - handleSize / 2,
          _crop.top * h - handleSize / 2,
        ),
      _CropHandle.topRight => (
          _crop.right * w - handleSize / 2,
          _crop.top * h - handleSize / 2,
        ),
      _CropHandle.bottomLeft => (
          _crop.left * w - handleSize / 2,
          _crop.bottom * h - handleSize / 2,
        ),
      _CropHandle.bottomRight => (
          _crop.right * w - handleSize / 2,
          _crop.bottom * h - handleSize / 2,
        ),
    };

    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (d) => _onHandleDrag(handle, d, constraints),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary, width: 2.0),
          ),
        ),
      ),
    );
  }
}

/// The four draggable corner handles of the crop rectangle.
enum _CropHandle { topLeft, topRight, bottomLeft, bottomRight }

// ---------------------------------------------------------------------------
// Crop overlay painter
// ---------------------------------------------------------------------------

/// [CustomPainter] that draws a semi-transparent dark mask outside the crop
/// rect, and a bright border around the crop rect.
class _CropOverlayPainter extends CustomPainter {
  /// Creates a [_CropOverlayPainter].
  ///
  /// Parameters:
  /// - [crop]: Normalized [CropRect] defining the visible region.
  const _CropOverlayPainter({required this.crop});

  /// Normalized crop region to highlight.
  final CropRect crop;

  @override
  void paint(Canvas canvas, Size size) {
    final maskPaint = Paint()..color = Colors.black54;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cropRect = Rect.fromLTRB(
      crop.left * size.width,
      crop.top * size.height,
      crop.right * size.width,
      crop.bottom * size.height,
    );

    // Mask regions outside crop rect.
    final fullRect = Offset.zero & size;
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, maskPaint);
    canvas.drawRect(cropRect, borderPaint);
  }

  @override
  bool shouldRepaint(_CropOverlayPainter old) => old.crop != crop;
}
