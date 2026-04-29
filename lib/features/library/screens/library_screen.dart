// LibraryScreen — main screen showing all active (non-deleted) notations.
//
// Route: /
//
// The screen observes [LibraryViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (notation list), or
// error.
//
// Delete interaction: each list item can be swiped from right-to-left to
// reveal a delete background, which triggers a confirmation dialog. On
// confirmation the notation is soft-deleted and a SnackBar with an "Undo"
// action appears for 5 seconds. Tapping "Undo" calls
// [LibraryViewModel.undoDelete].
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<LibraryViewModel>(
//     create: (_) => LibraryViewModel(notationRepository, trashRepository),
//     child: const LibraryScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Duration the "Undo" SnackBar is visible before the deletion is final.
const Duration _kUndoDuration = Duration(seconds: 5);

/// Vertical padding for the notation list.
const EdgeInsets _kListPadding = EdgeInsets.symmetric(vertical: 4);

/// Padding around the delete icon in the swipe background.
const EdgeInsets _kSwipeIconPadding = EdgeInsets.symmetric(horizontal: 24);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Main screen for browsing all active notations.
///
/// Reads [LibraryViewModel] from the widget tree via [ChangeNotifierProvider].
/// Calls [LibraryViewModel.init] after the first frame.
class LibraryScreen extends StatefulWidget {
  /// Creates a [LibraryScreen].
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
      ),
      body: switch (vm.state) {
        LibraryStateIdle() => const SizedBox.shrink(),
        LibraryStateLoading() => const _LoadingView(),
        LibraryStateSuccess(:final notations) => notations.isEmpty
            ? const _EmptyView()
            : _NotationListView(notations: notations),
        LibraryStateError(:final message) => _ErrorView(message: message),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the notation stream is initialising.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state shown when there are no active notations.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No notations yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture a new notation to get started.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Error view shown when the notation stream emits an error.
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Failed to load library',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Scrollable list of active notation rows.
class _NotationListView extends StatelessWidget {
  const _NotationListView({required this.notations});

  final List<Notation> notations;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: notations.length,
      itemBuilder: (context, index) => _NotationRow(notation: notations[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Notation row
// ---------------------------------------------------------------------------

/// A single library row with swipe-to-delete and an undo SnackBar.
class _NotationRow extends StatelessWidget {
  const _NotationRow({required this.notation});

  final Notation notation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: notation.title,
      child: Dismissible(
        key: ValueKey(notation.id),
        direction: DismissDirection.endToStart,
        background: const _SwipeDeleteBackground(),
        confirmDismiss: (_) => _confirmDelete(context),
        // Removal from list is driven by the stream; no local state needed.
        onDismissed: (_) {},
        child: _NotationRowContent(notation: notation),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text(
          '"${notation.title}" will be moved to Trash. '
          'You can restore it within 30 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;
    if (!context.mounted) return false;

    final vm = context.read<LibraryViewModel>();
    await vm.softDelete(notation.id);

    if (!context.mounted) return true;

    if (vm.operationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not delete notation. Please try again.'),
        ),
      );
      vm.clearOperationError();
      return false;
    }

    _showUndoSnackBar(context, vm);
    return true;
  }

  void _showUndoSnackBar(BuildContext context, LibraryViewModel vm) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${notation.title}" moved to Trash.'),
          duration: _kUndoDuration,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => vm.undoDelete(notation.id),
          ),
        ),
      );
  }
}

/// Content of a single library row.
class _NotationRowContent extends StatelessWidget {
  const _NotationRowContent({required this.notation});

  final Notation notation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.music_note_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(
        notation.title,
        style: Theme.of(context).textTheme.bodyLarge,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: notation.artists.isNotEmpty
          ? Text(
              notation.artists.join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Swipe-to-delete background shown when swiping a row from right-to-left.
class _SwipeDeleteBackground extends StatelessWidget {
  const _SwipeDeleteBackground();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: _kSwipeIconPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
