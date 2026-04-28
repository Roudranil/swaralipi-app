// InstrumentClassesScreen — screen for managing instrument class definitions.
//
// Route: /settings/instruments
//
// The screen observes [InstrumentClassesViewModel] via
// [ChangeNotifierProvider] and renders one of four states: idle, loading,
// success (class list), or error. Each class row shows its name. Tapping the
// FAB opens [InstrumentClassFormSheet] to create a new class. Tapping the
// edit icon on a row opens the form sheet pre-filled for editing.
// Swipe-to-archive triggers a confirmation dialog before calling
// [InstrumentClassesViewModel.archiveClass].
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<InstrumentClassesViewModel>(
//     create: (_) => InstrumentClassesViewModel(repository)..init(),
//     child: const InstrumentClassesScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/instruments/viewmodels/instrument_classes_view_model.dart';
import 'package:swaralipi/features/instruments/widgets/instrument_class_form_sheet.dart';
import 'package:swaralipi/shared/models/instrument_class.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Minimum touch target height for each class row.
const double _kRowMinHeight = 56.0;

/// Horizontal and vertical padding for the class list.
const EdgeInsets _kListPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 8);

/// Shape for the bottom sheet modal.
const RoundedRectangleBorder _kSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen for managing user-defined instrument class definitions.
///
/// Reads [InstrumentClassesViewModel] from the widget tree via
/// [ChangeNotifierProvider]. Calls [InstrumentClassesViewModel.init] after
/// the first frame so the Provider is available.
class InstrumentClassesScreen extends StatefulWidget {
  /// Creates an [InstrumentClassesScreen].
  const InstrumentClassesScreen({super.key});

  @override
  State<InstrumentClassesScreen> createState() =>
      _InstrumentClassesScreenState();
}

class _InstrumentClassesScreenState extends State<InstrumentClassesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<InstrumentClassesViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<InstrumentClassesViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instruments'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        tooltip: 'Add instrument class',
        child: const Icon(Icons.add),
      ),
      body: switch (vm.state) {
        InstrumentClassesStateIdle() => const SizedBox.shrink(),
        InstrumentClassesStateLoading() => const _LoadingView(),
        InstrumentClassesStateSuccess(:final classes) => classes.isEmpty
            ? const _EmptyView()
            : _ClassListView(classes: classes),
        InstrumentClassesStateError(:final message) =>
          _ErrorView(message: message),
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final vm = context.read<InstrumentClassesViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => InstrumentClassFormSheet(
        onSave: (name) async {
          await vm.createClass(name);
        },
      ),
    );

    if (!mounted) return;
    if (vm.createError != null) {
      _showErrorSnackBar(context, 'Could not create class. Please try again.');
      vm.clearCreateError();
    }
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the class stream is initializing.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state view shown when no instrument classes have been defined yet.
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
            'No instrument classes yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first class.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error view shown when the class stream emits an error.
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
              'Failed to load instrument classes',
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

/// Scrollable list of instrument class rows.
class _ClassListView extends StatelessWidget {
  const _ClassListView({required this.classes});

  final List<InstrumentClass> classes;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: classes.length,
      itemBuilder: (context, index) =>
          _ClassRow(instrumentClass: classes[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Class row
// ---------------------------------------------------------------------------

/// A single instrument class row with name, edit action, and swipe-to-archive.
///
/// Supports swipe-to-dismiss for archiving with a confirmation dialog.
class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.instrumentClass});

  final InstrumentClass instrumentClass;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Instrument class: ${instrumentClass.name}',
      child: Dismissible(
        key: ValueKey(instrumentClass.id),
        direction: DismissDirection.endToStart,
        background: const _SwipeArchiveBackground(),
        confirmDismiss: (_) => _confirmArchive(context),
        onDismissed: (_) => _archiveClass(context),
        child: SizedBox(
          height: _kRowMinHeight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  instrumentClass.name,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _EditButton(instrumentClass: instrumentClass),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmArchive(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive class?'),
        content: Text(
          'Archiving "${instrumentClass.name}" will hide it from active lists. '
          'Instances already added to notations will remain visible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
  }

  Future<void> _archiveClass(BuildContext context) async {
    final vm = context.read<InstrumentClassesViewModel>();
    await vm.archiveClass(instrumentClass.id);
    if (!context.mounted) return;
    if (vm.archiveError != null) {
      _showErrorSnackBar(
        context,
        'Could not archive class. Please try again.',
      );
      vm.clearArchiveError();
    }
  }
}

/// Amber swipe-to-dismiss background shown when dragging left.
class _SwipeArchiveBackground extends StatelessWidget {
  const _SwipeArchiveBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.archive_outlined,
        color: Theme.of(context).colorScheme.onTertiaryContainer,
      ),
    );
  }
}

/// Edit icon button that opens the form sheet pre-filled with the class name.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.instrumentClass});

  final InstrumentClass instrumentClass;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit ${instrumentClass.name}',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _openEditSheet(context),
        tooltip: 'Edit',
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final vm = context.read<InstrumentClassesViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => InstrumentClassFormSheet(
        initialName: instrumentClass.name,
        onSave: (name) async {
          await vm.updateClass(instrumentClass.id, name);
        },
      ),
    );

    if (!context.mounted) return;
    if (vm.updateError != null) {
      _showErrorSnackBar(
        context,
        'Could not update class. Please try again.',
      );
      vm.clearUpdateError();
    }
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
