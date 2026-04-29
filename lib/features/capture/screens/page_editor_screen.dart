// page_editor_screen.dart — screen for reviewing and editing captured pages
// before confirmation.
//
// Route: /capture/editor
//
// Displays the list of [CapturePageDraft] objects held by
// [CaptureSessionViewModel]. The user can review pages, remove unwanted ones,
// and proceed to the metadata form.
//
// This is an initial implementation that renders a thumbnail list. Per-page
// editing (crop, rotate, filter) is deferred to a later task.
//
// Dependency injection:
//   ChangeNotifierProvider<CaptureSessionViewModel> must be in the widget tree
//   above this screen (provided at the route level).

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Padding around the page list content.
const EdgeInsets _kContentPadding = EdgeInsets.symmetric(
  horizontal: 16.0,
  vertical: 12.0,
);

/// Vertical gap between section header and list.
const double _kSectionGap = 8.0;

/// Height of each page thumbnail card.
const double _kCardHeight = 120.0;

/// Border radius for page thumbnail cards.
const double _kCardRadius = 12.0;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen that displays the pages in the current capture session for review.
///
/// Observes [CaptureSessionViewModel] via [ChangeNotifierProvider] and
/// re-renders whenever the session changes.
class PageEditorScreen extends StatelessWidget {
  /// Creates a [PageEditorScreen].
  const PageEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Editor'),
      ),
      body: Consumer<CaptureSessionViewModel>(
        builder: (context, vm, _) {
          if (vm.pages.isEmpty) {
            return const _EmptyState();
          }
          return _PageList(pages: vm.pages);
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
// Page list
// ---------------------------------------------------------------------------

class _PageList extends StatelessWidget {
  const _PageList({required this.pages});

  final List<CapturePageDraft> pages;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pageCount = pages.length;
    final countLabel = pageCount == 1 ? '1 page' : '$pageCount pages';

    return Padding(
      padding: _kContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(countLabel, style: textTheme.labelLarge),
          const SizedBox(height: _kSectionGap),
          Expanded(
            child: ListView.separated(
              itemCount: pages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12.0),
              itemBuilder: (context, index) =>
                  _PageCard(draft: pages[index], index: index),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page card
// ---------------------------------------------------------------------------

class _PageCard extends StatelessWidget {
  const _PageCard({required this.draft, required this.index});

  final CapturePageDraft draft;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: 'Page ${index + 1}',
      child: Card(
        key: const Key('page_editor_page_card'),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        child: SizedBox(
          height: _kCardHeight,
          child: Row(
            children: [
              _ThumbnailImage(bytes: draft.originalBytes),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(
                  'Page ${index + 1}',
                  style: textTheme.bodyMedium,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.read<CaptureSessionViewModel>().removePage(index);
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                ),
                tooltip: 'Remove page ${index + 1}',
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

    return SizedBox(
      width: _kCardHeight,
      height: _kCardHeight,
      child: bytes.isNotEmpty
          ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(colorScheme),
            )
          : _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) => ColoredBox(
        color: colorScheme.surfaceContainerHigh,
        child: Icon(
          Icons.image_outlined,
          color: colorScheme.onSurfaceVariant,
        ),
      );
}
