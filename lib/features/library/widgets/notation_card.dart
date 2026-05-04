// NotationCard — list-item card for a single notation in LibraryScreen.
//
// Displays title, first-page thumbnail (or placeholder), artist(s), date
// written, and tag chips. Intended to be used inside a SliverList.builder
// in [LibraryScreen].
//
// The thumbnail is loaded from the file system using [Image.file]; when no
// pages exist or the path is absent, a placeholder icon is shown instead.
//
// Tag data is supplied by the caller as a list of [NotationTagChip] values so
// the card stays pure (no repository calls inside the widget).

import 'dart:io';

import 'package:flutter/material.dart';

import 'package:swaralipi/shared/models/notation.dart';

// ---------------------------------------------------------------------------
// Data DTOs
// ---------------------------------------------------------------------------

/// Lightweight DTO carrying the data a tag chip needs to render.
///
/// Decouples [NotationCard] from the [Tag] domain model so the widget can be
/// used in tests without depending on the full tag infrastructure.
class NotationTagChip {
  /// Creates a [NotationTagChip].
  ///
  /// Parameters:
  /// - [label]: Display name of the tag.
  /// - [colorHex]: Catppuccin hex color string, e.g. `'#f38ba8'`. Used as the
  ///   chip background color. When null or unparseable the chip falls back to
  ///   the theme's secondary container color.
  const NotationTagChip({
    required this.label,
    this.colorHex,
  });

  /// Display name shown inside the chip.
  final String label;

  /// Hex color string for the chip background; nullable.
  final String? colorHex;
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Width and height of the thumbnail area on the left of the card.
const double _kThumbnailSize = 56.0;

/// Radius for the thumbnail and card corners.
const double _kCardRadius = 12.0;

/// Maximum number of tag chips shown before overflow is hidden.
const int _kMaxVisibleTags = 3;

/// Horizontal padding inside the card content area.
const double _kContentPaddingH = 12.0;

/// Vertical padding inside the card content area.
const double _kContentPaddingV = 12.0;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A card widget representing a single notation in the library list.
///
/// Shows:
/// - A square thumbnail (first page image or placeholder icon).
/// - Title in [TextTheme.bodyLarge].
/// - Artist list in [TextTheme.bodySmall] (hidden when empty).
/// - Date written in [TextTheme.labelSmall] (hidden when null).
/// - Up to [_kMaxVisibleTags] tag chips.
///
/// Wrap in a [Semantics] widget with a tap handler in the parent when
/// navigation is required; this widget itself is purely presentational.
class NotationCard extends StatelessWidget {
  /// Creates a [NotationCard].
  ///
  /// Parameters:
  /// - [notation]: The notation whose data is rendered.
  /// - [thumbnailPath]: Absolute path to the first-page image file. When null
  ///   or the file does not exist, a placeholder icon is shown.
  /// - [tags]: Tag chips to display below the metadata row.
  /// - [onTap]: Called when the card is tapped.
  const NotationCard({
    required this.notation,
    this.thumbnailPath,
    this.tags = const [],
    this.onTap,
    super.key,
  });

  /// The notation to display.
  final Notation notation;

  /// Absolute path to the first-page image file; nullable.
  final String? thumbnailPath;

  /// Tag chips to display; defaults to an empty list.
  final List<NotationTagChip> tags;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: notation.title,
      button: onTap != null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kCardRadius),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_kCardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _kContentPaddingH,
              vertical: _kContentPaddingV,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Thumbnail(path: thumbnailPath),
                const SizedBox(width: 12),
                Expanded(
                  child: _CardContent(
                    notation: notation,
                    tags: tags,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

/// Square thumbnail showing the first page image or a placeholder icon.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    final resolvedPath = path;
    final hasFile = resolvedPath != null && File(resolvedPath).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: _kThumbnailSize,
        child: hasFile
            ? Image.file(
                File(resolvedPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _ThumbnailPlaceholder(),
              )
            : const _ThumbnailPlaceholder(),
      ),
    );
  }
}

/// Placeholder shown when no thumbnail image is available.
class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_outlined,
        size: 28,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Title, artists, date, and tag chips column.
class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.notation,
    required this.tags,
  });

  final Notation notation;
  final List<NotationTagChip> tags;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          notation.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (notation.artists.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            notation.artists.join(', '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (notation.dateWritten != null) ...[
          const SizedBox(height: 2),
          Text(
            notation.dateWritten!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          _TagChipRow(tags: tags),
        ],
      ],
    );
  }
}

/// A horizontal row of up to [_kMaxVisibleTags] tag chips.
class _TagChipRow extends StatelessWidget {
  const _TagChipRow({required this.tags});

  final List<NotationTagChip> tags;

  /// Parses a CSS hex color string (e.g. `'#f38ba8'`) to a [Color].
  ///
  /// Returns null when [hex] is null or cannot be parsed.
  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value != null ? Color(value) : null;
  }

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(_kMaxVisibleTags).toList();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: visible.map((tag) {
        final bg = _parseHex(tag.colorHex) ??
            Theme.of(context).colorScheme.secondaryContainer;
        // Determine readable foreground color based on luminance.
        final fg = bg.computeLuminance() > 0.4
            ? Colors.black87
            : Theme.of(context).colorScheme.onSecondaryContainer;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            tag.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                ),
          ),
        );
      }).toList(),
    );
  }
}
