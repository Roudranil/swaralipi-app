// sort_bottom_sheet.dart — Modal bottom sheet for choosing notation sort order.
//
// Shows a list of sort options (Title, Date written, Date added, Play count,
// Last played) each with an ASC/DESC variant. The active option is highlighted
// with [ListTile.selected]; tapping it again toggles the direction.
//
// Usage:
//   showModalBottomSheet(
//     context: context,
//     builder: (_) => SortBottomSheet(
//       current: vm.sort,
//       onChanged: vm.setSort,
//     ),
//   );

import 'package:flutter/material.dart';

import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Vertical padding around the sheet title.
const EdgeInsets _kTitlePadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 12);

// ---------------------------------------------------------------------------
// Data — sort group definitions
// ---------------------------------------------------------------------------

/// A pair of [LibrarySort] values representing the ascending and descending
/// direction for a single sort category.
class _SortGroup {
  /// Creates a [_SortGroup] with the given label and ASC/DESC sort values.
  ///
  /// Parameters:
  /// - [label]: Human-readable category name (e.g. "Title").
  /// - [asc]: Sort value for the ascending direction.
  /// - [desc]: Sort value for the descending direction.
  /// - [ascLabel]: Short direction label when [asc] is active.
  /// - [descLabel]: Short direction label when [desc] is active.
  const _SortGroup({
    required this.label,
    required this.asc,
    required this.desc,
    required this.ascLabel,
    required this.descLabel,
  });

  /// Human-readable category name.
  final String label;

  /// Sort value for the ascending direction.
  final LibrarySort asc;

  /// Sort value for the descending direction.
  final LibrarySort desc;

  /// Direction label shown when [asc] is active.
  final String ascLabel;

  /// Direction label shown when [desc] is active.
  final String descLabel;
}

/// All sort groups, in display order.
const List<_SortGroup> _kSortGroups = [
  _SortGroup(
    label: 'Title',
    asc: LibrarySort.titleAsc,
    desc: LibrarySort.titleDesc,
    ascLabel: 'A-Z',
    descLabel: 'Z-A',
  ),
  _SortGroup(
    label: 'Date written',
    asc: LibrarySort.dateWrittenAsc,
    desc: LibrarySort.dateWrittenDesc,
    ascLabel: 'Oldest first',
    descLabel: 'Newest first',
  ),
  _SortGroup(
    label: 'Date added',
    asc: LibrarySort.dateAsc,
    desc: LibrarySort.dateDesc,
    ascLabel: 'Oldest first',
    descLabel: 'Newest first',
  ),
  _SortGroup(
    label: 'Play count',
    asc: LibrarySort.playCountAsc,
    desc: LibrarySort.playCountDesc,
    ascLabel: 'Least first',
    descLabel: 'Most first',
  ),
  _SortGroup(
    label: 'Last played',
    asc: LibrarySort.lastPlayedAsc,
    desc: LibrarySort.lastPlayedDesc,
    ascLabel: 'Least recent',
    descLabel: 'Most recent',
  ),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Modal bottom sheet for selecting the notation list sort order.
///
/// Renders a drag handle, a "Sort by" heading, a divider, and a [ListView] of
/// sort options. The active option is highlighted via [ListTile.selected]; a
/// trailing arrow icon indicates the current direction. Tapping the active
/// option toggles the direction; tapping a different option activates it in its
/// default descending direction.
class SortBottomSheet extends StatelessWidget {
  /// Creates a [SortBottomSheet].
  ///
  /// Parameters:
  /// - [current]: The currently active sort value.
  /// - [onChanged]: Callback invoked with the new [LibrarySort] value when the
  ///   user selects an option.
  const SortBottomSheet({
    required this.current,
    required this.onChanged,
    super.key,
  });

  /// The currently active sort value.
  final LibrarySort current;

  /// Called with the new [LibrarySort] when the user makes a selection.
  final ValueChanged<LibrarySort> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withAlpha(102),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Title
        Padding(
          padding: _kTitlePadding,
          child: Text(
            'Sort by',
            style: textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        // Options list — scrollable so it fits any bottom-sheet height.
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _kSortGroups.length,
            itemBuilder: (context, index) {
              final group = _kSortGroups[index];
              return _SortOptionTile(
                group: group,
                current: current,
                onChanged: onChanged,
              );
            },
          ),
        ),
        // Bottom safe-area inset so content clears the gesture bar.
        SizedBox(height: MediaQuery.of(context).padding.bottom),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Private tile widget
// ---------------------------------------------------------------------------

/// A single sort option row inside [SortBottomSheet].
///
/// Highlights when [current] matches either [group.asc] or [group.desc].
/// Shows a direction icon (arrow up / arrow down) as trailing when active.
/// Tapping the active option toggles the direction; tapping an inactive option
/// activates it in its default (descending) direction.
class _SortOptionTile extends StatelessWidget {
  const _SortOptionTile({
    required this.group,
    required this.current,
    required this.onChanged,
  });

  final _SortGroup group;
  final LibrarySort current;
  final ValueChanged<LibrarySort> onChanged;

  bool get _isAscActive => current == group.asc;
  bool get _isDescActive => current == group.desc;
  bool get _isActive => _isAscActive || _isDescActive;

  String get _directionLabel {
    if (_isAscActive) return group.ascLabel;
    if (_isDescActive) return group.descLabel;
    return group.descLabel;
  }

  IconData get _directionIcon {
    if (_isAscActive) return Icons.arrow_upward;
    return Icons.arrow_downward;
  }

  void _handleTap() {
    if (!_isActive) {
      // Activate in default (descending) direction.
      onChanged(group.desc);
    } else if (_isDescActive) {
      // Toggle to ascending.
      onChanged(group.asc);
    } else {
      // Toggle to descending.
      onChanged(group.desc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: '${group.label}, $_directionLabel${_isActive ? ', selected' : ''}',
      button: true,
      child: ListTile(
        title: Text(group.label),
        subtitle: _isActive ? Text(_directionLabel) : null,
        selected: _isActive,
        selectedColor: colorScheme.primary,
        trailing:
            _isActive ? Icon(_directionIcon, color: colorScheme.primary) : null,
        onTap: _handleTap,
      ),
    );
  }
}
