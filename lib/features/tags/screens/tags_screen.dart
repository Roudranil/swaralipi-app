// TagsScreen — screen for managing user-defined notation tags.
//
// Route: /settings/tags
//
// The screen observes [TagsViewModel] via [ChangeNotifierProvider] and renders
// one of four states: idle, loading, success (tag list), or error. Each tag
// row shows a colored chip swatch, name, an edit icon button, and a delete
// icon button. Tapping the FAB or the edit icon opens [TagFormSheet] as a
// modal bottom sheet. Tapping delete opens a confirmation dialog before
// invoking [TagsViewModel.deleteTag].
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<TagsViewModel>(
//     create: (_) => TagsViewModel(tagRepository)..init(),
//     child: const TagsScreen(),
//   )
//
// Or the screen can be used with an already-provided ViewModel by wrapping
// with ChangeNotifierProvider.value.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/tags/viewmodels/tags_view_model.dart';
import 'package:swaralipi/features/tags/widgets/catppuccin_color_picker.dart';
import 'package:swaralipi/features/tags/widgets/tag_form_sheet.dart';
import 'package:swaralipi/shared/models/tag.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Minimum touch target height for each tag row.
const double _kTagRowMinHeight = 56.0;

/// Diameter of the color swatch chip in the tag row.
const double _kSwatchDiameter = 28.0;

/// Horizontal padding for the tag list.
const EdgeInsets _kListPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 8);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Screen for managing user-defined notation tags.
///
/// Reads [TagsViewModel] from the widget tree via [ChangeNotifierProvider].
/// Calls [TagsViewModel.init] in [initState].
class TagsScreen extends StatefulWidget {
  /// Creates a [TagsScreen].
  const TagsScreen({super.key});

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule after first frame so Provider is available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TagsViewModel>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TagsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tags'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        tooltip: 'Create tag',
        child: const Icon(Icons.add),
      ),
      body: switch (vm.state) {
        TagsStateIdle() => const SizedBox.shrink(),
        TagsStateLoading() => const _LoadingView(),
        TagsStateSuccess(:final tags) =>
          tags.isEmpty ? const _EmptyView() : _TagListView(tags: tags),
        TagsStateError(:final message) => _ErrorView(message: message),
      },
    );
  }

  Future<void> _openCreateSheet(BuildContext context) async {
    final vm = context.read<TagsViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) => TagFormSheet(
        onSave: (name, colorHex) async {
          await vm.createTag(name, colorHex);
        },
      ),
    );

    if (!mounted) return;
    if (vm.createError != null) {
      _showErrorSnackBar(context, 'Could not create tag. Please try again.');
      vm.clearCreateError();
    }
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the tags stream is initializing.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state view shown when the user has no tags yet.
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.label_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No tags yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first tag.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Error view shown when the tags stream emits an error.
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
              'Failed to load tags',
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

/// Scrollable list of tag rows.
class _TagListView extends StatelessWidget {
  const _TagListView({required this.tags});

  final List<Tag> tags;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: _kListPadding,
      itemCount: tags.length,
      itemBuilder: (context, index) => _TagRow(tag: tags[index]),
    );
  }
}

// ---------------------------------------------------------------------------
// Tag row
// ---------------------------------------------------------------------------

/// A single tag row with color swatch, name, edit, and delete controls.
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tag.name,
      child: SizedBox(
        height: _kTagRowMinHeight,
        child: Row(
          children: [
            _ColorSwatch(colorHex: tag.colorHex),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tag.name,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _EditButton(tag: tag),
            _DeleteButton(tag: tag),
          ],
        ),
      ),
    );
  }
}

/// Circular color swatch for a tag row.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.colorHex});

  final String colorHex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kSwatchDiameter,
      height: _kSwatchDiameter,
      decoration: BoxDecoration(
        color: colorFromHex(colorHex),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Edit icon button that opens the tag form sheet pre-filled with the tag.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Edit ${tag.name}',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.edit_outlined),
        onPressed: () => _openEditSheet(context),
        tooltip: 'Edit',
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final vm = context.read<TagsViewModel>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) => TagFormSheet(
        initialName: tag.name,
        initialColorHex: tag.colorHex,
        onSave: (name, colorHex) async {
          await vm.updateTag(tag.id, name: name, colorHex: colorHex);
        },
      ),
    );

    if (!context.mounted) return;
    if (vm.updateError != null) {
      _showErrorSnackBar(context, 'Could not update tag. Please try again.');
      vm.clearUpdateError();
    }
  }
}

/// Delete icon button that shows a confirmation dialog before deleting.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.tag});

  final Tag tag;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Delete ${tag.name}',
      button: true,
      child: IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => _confirmAndDelete(context),
        tooltip: 'Delete',
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final vm = context.read<TagsViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete tag?'),
        content: Text(
          'Removes "${tag.name}" from all notations.',
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

    await vm.deleteTag(tag.id);

    if (!context.mounted) return;
    if (vm.deleteError != null) {
      _showErrorSnackBar(context, 'Could not delete tag. Please try again.');
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
