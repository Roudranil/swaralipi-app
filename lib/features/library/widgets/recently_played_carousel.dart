// RecentlyPlayedCarousel — horizontal carousel showing the last 5 played
// notations.
//
// This widget is purely presentational; it receives the notation list and
// an onTap callback from LibraryScreen. It does not read the ViewModel
// itself.
//
// Hidden entirely when [notations] is empty.

import 'package:flutter/material.dart';

import 'package:swaralipi/shared/models/notation.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Height of the carousel section including the header.
const double _kCarouselHeight = 180.0;

/// Width of each notation card in the carousel.
const double _kCardWidth = 120.0;

/// Height of the card's label area at the bottom.
const double _kLabelHeight = 48.0;

/// Horizontal padding inside each card's label area.
const EdgeInsets _kLabelPadding =
    EdgeInsets.symmetric(horizontal: 8, vertical: 6);

/// Left/right padding of the list view itself.
const EdgeInsets _kListPadding = EdgeInsets.symmetric(horizontal: 16);

/// Gap between consecutive cards.
const double _kCardSpacing = 10.0;

/// Corner radius for each card.
const double _kCardRadius = 12.0;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Horizontal carousel of the most-recently-played notations.
///
/// Renders a header row ("Recently Played") and a horizontally-scrollable
/// row of [_RecentlyPlayedCard] widgets. Hidden when [notations] is empty.
///
/// Tapping a card calls [onTap] with the notation's id.
class RecentlyPlayedCarousel extends StatelessWidget {
  /// Creates a [RecentlyPlayedCarousel].
  ///
  /// Parameters:
  /// - [notations]: Ordered list of recently-played notations (≤ 5).
  /// - [onTap]: Called when a card is tapped; receives the notation id.
  const RecentlyPlayedCarousel({
    required this.notations,
    required this.onTap,
    super.key,
  });

  /// Recently-played notations to display.
  final List<Notation> notations;

  /// Callback invoked with the tapped notation's id.
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (notations.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      key: const Key('recently_played_carousel'),
      height: _kCarouselHeight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: _kListPadding,
            child: Text(
              'Recently Played',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: _kListPadding,
              itemCount: notations.length,
              separatorBuilder: (_, __) => const SizedBox(width: _kCardSpacing),
              itemBuilder: (context, index) => _RecentlyPlayedCard(
                notation: notations[index],
                onTap: () => onTap(notations[index].id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Card
// ---------------------------------------------------------------------------

/// A single card in the [RecentlyPlayedCarousel].
///
/// Shows a thumbnail placeholder and the notation title. Tapping calls
/// [onTap].
class _RecentlyPlayedCard extends StatelessWidget {
  const _RecentlyPlayedCard({
    required this.notation,
    required this.onTap,
  });

  final Notation notation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Semantics(
      label: notation.title,
      button: true,
      child: GestureDetector(
        key: const Key('recently_played_card'),
        onTap: onTap,
        child: SizedBox(
          width: _kCardWidth,
          child: Material(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(_kCardRadius),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ThumbnailPlaceholder(
                    color: cs.surfaceContainer,
                    iconColor: cs.onSurfaceVariant,
                  ),
                ),
                Container(
                  height: _kLabelHeight,
                  color: cs.surfaceContainerHigh,
                  padding: _kLabelPadding,
                  child: Text(
                    notation.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurface,
                    ),
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

/// Placeholder shown when no thumbnail image is available.
class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder({
    required this.color,
    required this.iconColor,
  });

  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: color,
      child: Center(
        child: Icon(
          Icons.music_note_outlined,
          color: iconColor,
          size: 28,
        ),
      ),
    );
  }
}
