// TagFilterRow — horizontally-scrollable row of FilterChip widgets for
// selecting one or more tag filters on the Library screen.
//
// The row is hidden when [tags] is empty. Each chip shows the tag name and
// colour. Selected chips (ids in [selectedTagIds]) appear with a filled
// surface. Tapping any chip calls [onToggle] with the tag id, which the
// ViewModel uses to add/remove the id from its [selectedTagIds] set.

import 'package:flutter/material.dart';

import 'package:swaralipi/shared/models/tag.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Horizontal padding around the chip row.
const EdgeInsets _kRowPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 4,
);

/// Gap between adjacent chips.
const double _kChipSpacing = 8;

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A horizontally-scrollable row of [FilterChip]s for tag-based filtering.
///
/// Shows one chip per entry in [tags]. Chips whose id is present in
/// [selectedTagIds] are rendered in their selected state. Tapping a chip
/// calls [onToggle] with the tag's id; the caller is responsible for updating
/// [selectedTagIds].
///
/// The widget renders nothing ([SizedBox.shrink]) when [tags] is empty.
class TagFilterRow extends StatelessWidget {
  /// Creates a [TagFilterRow].
  ///
  /// Parameters:
  /// - [tags]: All available tags to display as filter chips.
  /// - [selectedTagIds]: Set of tag ids whose chips are currently selected.
  /// - [onToggle]: Called with a tag id when a chip is tapped.
  const TagFilterRow({
    required this.tags,
    required this.selectedTagIds,
    required this.onToggle,
    super.key,
  });

  /// All tags available for selection.
  final List<Tag> tags;

  /// The ids of currently-selected tags.
  final Set<String> selectedTagIds;

  /// Callback invoked with the tag id when a chip is tapped.
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: _kRowPadding,
      child: Row(
        children: [
          for (final tag in tags) ...[
            _TagChip(
              tag: tag,
              selected: selectedTagIds.contains(tag.id),
              onToggle: onToggle,
            ),
            const SizedBox(width: _kChipSpacing),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private chip widget
// ---------------------------------------------------------------------------

/// A single [FilterChip] representing one [Tag] in the filter row.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.tag,
    required this.selected,
    required this.onToggle,
  });

  final Tag tag;
  final bool selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${tag.name} filter${selected ? ', selected' : ''}',
      child: FilterChip(
        label: Text(tag.name),
        selected: selected,
        onSelected: (_) => onToggle(tag.id),
        selectedColor: Theme.of(context).colorScheme.secondaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.onSecondaryContainer,
        labelStyle: selected
            ? Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                )
            : Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
      ),
    );
  }
}
