// CustomFieldsScreen — screen for managing user-defined custom metadata field
// definitions.
//
// Route: /settings/custom-fields
//
// The screen observes [CustomFieldsViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (definition list), or
// error. Each definition row shows the key name and a type badge. Tapping the
// FAB opens [CustomFieldFormSheet] for creation. A long-press or swipe
// reveals a delete action with a confirmation dialog (warns that values will
// be lost).
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<CustomFieldsViewModel>(
//     create: (_) => CustomFieldsViewModel(repository)..init(),
//     child: const CustomFieldsScreen(),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/custom_fields/viewmodels/custom_fields_view_model.dart';
import 'package:swaralipi/features/custom_fields/widgets/custom_field_form_sheet.dart';
import 'package:swaralipi/shared/models/custom_field_definition.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Minimum touch target height for each definition row.
const double _kRowMinHeight = 56.0;

/// Horizontal and vertical padding for the definitions list.
const EdgeInsets _kListPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 8);

/// Border radius for the type badge chip.
const BorderRadius _kBadgeRadius = BorderRadius.all(Radius.circular(8));

/// Shape for the bottom sheet.
const RoundedRectangleBorder _kSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen for managing user-defined custom metadata field definitions.
///
/// Reads [CustomFieldsViewModel] from the widget tree via
/// [ChangeNotifierProvider]. Calls [CustomFieldsViewModel.init] after the
/// first frame so the Provider is available.
class CustomFieldsScreen extends StatefulWidget {
  /// Creates a [CustomFieldsScreen].
  const CustomFieldsScreen({super.key});

  @override
  State<CustomFieldsScreen> createState() => _CustomFieldsScreenState();
}

class _CustomFieldsScreenState extends State<CustomFieldsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomFieldsViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CustomFieldsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Fields'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        tooltip: 'Add custom field',
        child: const Icon(Icons.add),
      ),
      body: switch (vm.state) {
        CustomFieldsStateIdle() => const SizedBox.shrink(),
        CustomFieldsStateLoading() => const _LoadingView(),
        CustomFieldsStateSuccess(:final definitions) => definitions.isEmpty
            ? const _EmptyView()
            : _DefinitionListView(definitions: definitions),
        CustomFieldsStateError(:final message) => _ErrorView(message: message),
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final vm = context.read<CustomFieldsViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => CustomFieldFormSheet(
        onSave: (keyName, fieldType) async {
          await vm.createDefinition(keyName, fieldType);
        },
      ),
    );

    if (!mounted) return;
    if (vm.createError != null) {
      _showErrorSnackBar(context, 'Could not create field. Please try again.');
      vm.clearCreateError();
    }
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the definitions stream is initializing.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state view shown when no custom fields have been defined yet.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tune_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No custom fields yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to define your first field.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error view shown when the definitions stream emits an error.
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
              'Failed to load custom fields',
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

/// Scrollable list of custom field definition rows.
class _DefinitionListView extends StatelessWidget {
  const _DefinitionListView({required this.definitions});

  final List<CustomFieldDefinition> definitions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: definitions.length,
      itemBuilder: (context, index) =>
          _DefinitionRow(definition: definitions[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Definition row
// ---------------------------------------------------------------------------

/// A single definition row with key name, type badge, edit and delete actions.
///
/// Supports swipe-to-dismiss for deletion.
class _DefinitionRow extends StatelessWidget {
  const _DefinitionRow({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${definition.keyName}, ${definition.fieldType.name} field',
      child: Dismissible(
        key: ValueKey(definition.id),
        direction: DismissDirection.endToStart,
        background: _SwipeDismissBackground(),
        confirmDismiss: (_) => _confirmDelete(context),
        onDismissed: (_) => _deleteDefinition(context),
        child: SizedBox(
          height: _kRowMinHeight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  definition.keyName,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _TypeBadge(fieldType: definition.fieldType),
              _EditButton(definition: definition),
              _DeleteButton(definition: definition),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete field?'),
        content: Text(
          'Deleting "${definition.keyName}" will permanently remove it and '
          'all its values from every notation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDefinition(BuildContext context) async {
    final vm = context.read<CustomFieldsViewModel>();
    await vm.deleteDefinition(definition.id);
    if (!context.mounted) return;
    if (vm.deleteError != null) {
      _showErrorSnackBar(
        context,
        'Could not delete field. Please try again.',
      );
      vm.clearDeleteError();
    }
  }
}

/// Red swipe-to-dismiss background shown when dragging left.
class _SwipeDismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.error,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(
        Icons.delete_outline,
        color: Theme.of(context).colorScheme.onError,
      ),
    );
  }
}

/// Tonal chip badge showing the field type.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.fieldType});

  final CustomFieldType fieldType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: _kBadgeRadius,
      ),
      child: Text(
        fieldType.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
      ),
    );
  }
}

/// Edit icon button that opens the form sheet pre-filled with the definition.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit ${definition.keyName}',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _openEditSheet(context),
        tooltip: 'Edit',
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final vm = context.read<CustomFieldsViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: _kSheetShape,
      builder: (_) => CustomFieldFormSheet(
        initialKeyName: definition.keyName,
        initialFieldType: definition.fieldType.name,
        onSave: (keyName, fieldType) async {
          await vm.updateDefinition(
            definition.id,
            keyName: keyName,
            fieldType: fieldType,
          );
        },
      ),
    );

    if (!context.mounted) return;
    if (vm.updateError != null) {
      _showErrorSnackBar(context, 'Could not update field. Please try again.');
      vm.clearUpdateError();
    }
  }
}

/// Delete icon button that shows a confirmation dialog before deleting.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.definition});

  final CustomFieldDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Delete ${definition.keyName}',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmAndDelete(context),
        tooltip: 'Delete',
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final vm = context.read<CustomFieldsViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete field?'),
        content: Text(
          'Deleting "${definition.keyName}" will permanently remove it and '
          'all its values from every notation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await vm.deleteDefinition(definition.id);

    if (!context.mounted) return;
    if (vm.deleteError != null) {
      _showErrorSnackBar(context, 'Could not delete field. Please try again.');
      vm.clearDeleteError();
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
