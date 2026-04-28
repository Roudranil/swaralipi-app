// TrashScreen — screen for managing soft-deleted notations.
//
// Route: /settings/trash
//
// The screen observes [TrashViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (notation list), or
// error. Each row shows the notation title and deletion date. Swipe-to-
// restore restores the notation; long-pressing opens a context menu with a
// "Delete Permanently" option (with confirmation). The AppBar action
// "Empty Trash" purges all trashed notations after confirmation.
//
// Auto-purge (TrashRepository.autoPurgeExpired) is called at app startup
// from main.dart, not from this screen.
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<TrashViewModel>(
//     create: (_) => TrashViewModel(trashRepository),
//     child: const TrashScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/trash/viewmodels/trash_view_model.dart';
import 'package:swaralipi/shared/models/notation.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Horizontal and vertical padding for the trash list.
const EdgeInsets _kListPadding =
    EdgeInsets.symmetric(horizontal: 0, vertical: 4);

/// Padding around the icon in the swipe background.
const EdgeInsets _kSwipeIconPadding = EdgeInsets.symmetric(horizontal: 24);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen for managing soft-deleted notations (Trash).
///
/// Reads [TrashViewModel] from the widget tree via [ChangeNotifierProvider].
/// Calls [TrashViewModel.init] after the first frame so the Provider is
/// available.
class TrashScreen extends StatefulWidget {
  /// Creates a [TrashScreen].
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TrashViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TrashViewModel>();
    final hasItems = vm.state is TrashStateSuccess &&
        (vm.state as TrashStateSuccess).notations.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (hasItems)
            Semantics(
              label: 'Empty Trash',
              button: true,
              child: TextButton.icon(
                onPressed: () => _confirmEmptyTrash(context),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text('Empty'),
              ),
            ),
        ],
      ),
      body: switch (vm.state) {
        TrashStateIdle() => const SizedBox.shrink(),
        TrashStateLoading() => const _LoadingView(),
        TrashStateSuccess(:final notations) => notations.isEmpty
            ? const _EmptyView()
            : _TrashListView(notations: notations),
        TrashStateError(:final message) => _ErrorView(message: message),
      },
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final vm = context.read<TrashViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'This will permanently delete all items in the Trash. '
          'This action cannot be undone.',
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
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await vm.purgeAll();

    if (!context.mounted) return;
    if (vm.operationError != null) {
      _showErrorSnackBar(context, 'Could not empty trash. Please try again.');
      vm.clearOperationError();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trash emptied.')),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the trash stream is initialising.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state shown when no notations are in the trash.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted notations appear here for 30 days.',
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

/// Error view shown when the trash stream emits an error.
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
              'Failed to load trash',
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

/// Scrollable list of trashed notation rows.
class _TrashListView extends StatelessWidget {
  const _TrashListView({required this.notations});

  final List<Notation> notations;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: notations.length,
      itemBuilder: (context, index) => _TrashRow(notation: notations[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Trash row
// ---------------------------------------------------------------------------

/// A single trash row with swipe-to-restore and long-press-to-purge.
class _TrashRow extends StatelessWidget {
  const _TrashRow({required this.notation});

  final Notation notation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${notation.title}, deleted',
      child: Dismissible(
        key: ValueKey(notation.id),
        direction: DismissDirection.startToEnd,
        background: _SwipeRestoreBackground(),
        confirmDismiss: (_) => _confirmRestore(context),
        onDismissed: (_) {/* restore handled in confirmDismiss */},
        child: _TrashRowContent(notation: notation),
      ),
    );
  }

  Future<bool?> _confirmRestore(BuildContext context) async {
    final vm = context.read<TrashViewModel>();
    await vm.restoreNotation(notation.id);

    if (!context.mounted) return false;
    if (vm.operationError != null) {
      _showErrorSnackBar(
        context,
        'Could not restore "${notation.title}". Please try again.',
      );
      vm.clearOperationError();
      return false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${notation.title}" restored to library.'),
      ),
    );
    return true;
  }
}

/// Content of a single trash row.
class _TrashRowContent extends StatelessWidget {
  const _TrashRowContent({required this.notation});

  final Notation notation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        Icons.music_note_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        notation.title,
        style: Theme.of(context).textTheme.bodyLarge,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: notation.deletedAt != null
          ? _DeletionDateLabel(deletedAt: notation.deletedAt!)
          : null,
      trailing: _PurgeButton(notation: notation),
    );
  }
}

/// Formatted "Deleted X days ago" label.
class _DeletionDateLabel extends StatelessWidget {
  const _DeletionDateLabel({required this.deletedAt});

  final String deletedAt;

  @override
  Widget build(BuildContext context) {
    final daysAgo = _daysAgo(deletedAt);
    final label = daysAgo == 0
        ? 'Deleted today'
        : daysAgo == 1
            ? 'Deleted 1 day ago'
            : 'Deleted $daysAgo days ago';

    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  int _daysAgo(String iso) {
    try {
      final deleted = DateTime.parse(iso).toUtc();
      final now = DateTime.now().toUtc();
      return now.difference(deleted).inDays;
    } on FormatException {
      return 0;
    }
  }
}

/// Icon button that triggers permanent deletion after confirmation.
class _PurgeButton extends StatelessWidget {
  const _PurgeButton({required this.notation});

  final Notation notation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Delete "${notation.title}" permanently',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.delete_forever_outlined),
        color: Theme.of(context).colorScheme.error,
        onPressed: () => _confirmAndPurge(context),
        tooltip: 'Delete permanently',
      ),
    );
  }

  Future<void> _confirmAndPurge(BuildContext context) async {
    final vm = context.read<TrashViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: Text(
          '"${notation.title}" will be permanently deleted from your device. '
          'This action cannot be undone.',
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

    if (confirmed != true) return;
    if (!context.mounted) return;

    await vm.purgeNotation(notation.id);

    if (!context.mounted) return;
    if (vm.operationError != null) {
      _showErrorSnackBar(
        context,
        'Could not delete "${notation.title}". Please try again.',
      );
      vm.clearOperationError();
    }
  }
}

/// Swipe-to-restore background shown when swiping a row to the right.
class _SwipeRestoreBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: _kSwipeIconPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.restore,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                'Restore',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
// Shared helper
// ---------------------------------------------------------------------------

/// Shows a brief error [SnackBar] using the nearest [ScaffoldMessenger].
///
/// Parameters:
/// - [context]: Build context with an active [Scaffold] in its tree.
/// - [message]: The error message to display.
void _showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
