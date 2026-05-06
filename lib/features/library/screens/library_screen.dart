// library_screen.dart — main screen showing all active (non-deleted) notations.
//
// Route: /  (rendered inside the app shell's ShellRoute)
//
// The screen observes [LibraryViewModel] via [ChangeNotifierProvider] and
// renders one of four states: idle, loading, success (notation list), or
// error.
//
// Layout:
//   CustomScrollView
//     SliverAppBar (pinned)  — greeting title + sort icon action
//     SliverToBoxAdapter     — SearchBar
//     SliverToBoxAdapter     — TagFilterRow (conditional)
//     SliverToBoxAdapter     — recently-played carousel (conditional)
//     SliverPadding          — SliverList.builder (notation rows)
//     SliverFillRemaining    — empty / loading / error states
//
// Sort: triggered by the sort IconButton in AppBar actions; opens a
// [SortBottomSheet] as a modal bottom sheet.
//
// Delete interaction: each list item can be swiped from right-to-left to
// reveal a delete background, which triggers a confirmation dialog. On
// confirmation the notation is soft-deleted and a SnackBar with an "Undo"
// action appears for 5 seconds. Tapping "Undo" calls
// [LibraryViewModel.undoDelete].
//
// Edit interaction: long-pressing a notation row opens a popup menu with an
// "Edit" option that launches [EditNotationScreen] via [Navigator.push].
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<LibraryViewModel>(
//     create: (_) => LibraryViewModel(notationRepository, trashRepository),
//     child: LibraryScreen(
//       notationRepository: notationRepository,
//       tagRepository: tagRepository,
//       instrumentRepository: instrumentRepository,
//       customFieldRepository: customFieldRepository,
//       fileStorageService: fileStorageService,
//       preferencesRepository: preferencesRepository,
//     ),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/edit/screens/edit_notation_screen.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/features/library/widgets/notation_card.dart';
import 'package:swaralipi/features/library/widgets/recently_played_carousel.dart';
import 'package:swaralipi/features/library/widgets/sort_bottom_sheet.dart';
import 'package:swaralipi/features/library/widgets/tag_filter_row.dart';
import 'package:swaralipi/shared/models/notation.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Duration the "Undo" SnackBar is visible before the deletion is final.
const Duration _kUndoDuration = Duration(seconds: 5);

/// Vertical padding for the notation list.
const EdgeInsets _kListPadding = EdgeInsets.symmetric(vertical: 4);

/// Padding around the delete icon in the swipe background.
const EdgeInsets _kSwipeIconPadding = EdgeInsets.symmetric(horizontal: 24);

/// Horizontal and vertical padding around the search bar.
const EdgeInsets _kSearchBarPadding = EdgeInsets.fromLTRB(16, 8, 16, 4);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Main screen for browsing all active notations.
///
/// Reads [LibraryViewModel] from the widget tree via [ChangeNotifierProvider].
/// Calls [LibraryViewModel.init] after the first frame.
///
/// Displays a recently-played carousel at the top (hidden when no notations
/// have been played) above the full notation list.
///
/// When the edit dependencies are provided, long-pressing a notation row
/// reveals a popup menu with an "Edit" option that launches
/// [EditNotationScreen].
///
/// When [onNotationTap] is provided, tapping a carousel card or a notation
/// row calls [onNotationTap] with the notation id. Callers use this to
/// navigate to [NotationDetailScreen].
class LibraryScreen extends StatefulWidget {
  /// Creates a [LibraryScreen].
  ///
  /// Parameters:
  /// - [notationRepository]: Passed to [EditNotationScreen] when editing.
  /// - [tagRepository]: Passed to [EditNotationScreen] for the tag picker.
  /// - [instrumentRepository]: Passed to [EditNotationScreen] for instruments.
  /// - [customFieldRepository]: Passed to [EditNotationScreen] for custom fields.
  /// - [fileStorageService]: Passed to [EditNotationScreen] to resolve paths.
  /// - [preferencesRepository]: Used to load the user's display name for the
  ///   greeting. When null, "Hi there" is displayed.
  /// - [onNotationTap]: Called with a notation id when a notation is tapped
  ///   (carousel card or list row). When null, tapping is a no-op.
  const LibraryScreen({
    this.notationRepository,
    this.tagRepository,
    this.instrumentRepository,
    this.customFieldRepository,
    this.fileStorageService,
    this.preferencesRepository,
    this.onNotationTap,
    super.key,
  });

  /// Used by [EditNotationScreen]. When null the Edit action is hidden.
  final NotationRepository? notationRepository;

  /// Used by [EditNotationScreen] for the tag picker.
  final TagRepository? tagRepository;

  /// Used by [EditNotationScreen] for the instrument picker.
  final InstrumentRepository? instrumentRepository;

  /// Used by [EditNotationScreen] for custom field inputs.
  final CustomFieldRepository? customFieldRepository;

  /// Used by [EditNotationScreen] to resolve image paths.
  final FileStorageService? fileStorageService;

  /// Used to load the user's display name for the AppBar greeting.
  ///
  /// When null or when the name is empty, "Hi there" is displayed.
  final PreferencesRepository? preferencesRepository;

  /// Called with the notation id when a carousel card or list row is tapped.
  ///
  /// When null, tapping navigates using [Navigator.push] if the platform
  /// dependencies are injected; otherwise tapping is a no-op.
  final ValueChanged<String>? onNotationTap;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final SearchController _searchController = SearchController();
  String _greeting = 'Hi there';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<LibraryViewModel>().init();
      _loadGreeting();
    });
  }

  Future<void> _loadGreeting() async {
    final repo = widget.preferencesRepository;
    if (repo == null) return;
    final prefs = await repo.getPreferences();
    if (!mounted) return;
    final name = prefs.userName.trim();
    if (name.isEmpty) {
      await _promptForName(repo);
      return;
    }
    setState(() {
      _greeting = 'Hi, $name';
    });
  }

  /// Shows a blocking dialog that asks the user for their name on first launch.
  ///
  /// The dialog cannot be dismissed without entering a name. On save, persists
  /// the name via [repo] and updates the greeting immediately.
  ///
  /// Parameters:
  /// - [repo]: The [PreferencesRepository] used to persist the entered name.
  Future<void> _promptForName(PreferencesRepository repo) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _NamePromptDialog(
        controller: controller,
        onSave: (name) async {
          Navigator.of(dialogContext).pop();
          await repo.updateUserName(name);
          if (!mounted) return;
          setState(() {
            _greeting = 'Hi, $name';
          });
        },
      ),
    );
    controller.dispose();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSortSheet(BuildContext context) {
    final vm = context.read<LibraryViewModel>();
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SortBottomSheet(
        current: vm.sort,
        onChanged: (sort) {
          vm.setSort(sort);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LibraryViewModel>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ---------------------------------------------------------------
          // SliverAppBar — pinned, greeting title, sort action
          // ---------------------------------------------------------------
          SliverAppBar(
            pinned: true,
            floating: false,
            title: Text(
              _greeting,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              Semantics(
                label: 'Sort notations',
                child: IconButton(
                  icon: const Icon(Icons.sort_outlined),
                  tooltip: 'Sort',
                  onPressed: () => _openSortSheet(context),
                ),
              ),
            ],
          ),
          // ---------------------------------------------------------------
          // Search bar
          // ---------------------------------------------------------------
          SliverToBoxAdapter(
            child: _LibrarySearchBar(
              controller: _searchController,
              onChanged: vm.setSearchQuery,
              onClear: vm.clearSearch,
            ),
          ),
          // ---------------------------------------------------------------
          // Tag filter row (conditional)
          // ---------------------------------------------------------------
          if (vm.availableTags.isNotEmpty)
            SliverToBoxAdapter(
              child: TagFilterRow(
                tags: vm.availableTags,
                selectedTagIds: vm.selectedTagIds,
                onToggle: vm.toggleTag,
              ),
            ),
          // ---------------------------------------------------------------
          // Main content (loading / error / success / idle)
          // ---------------------------------------------------------------
          ..._buildContentSlivers(context, vm),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers(
    BuildContext context,
    LibraryViewModel vm,
  ) {
    return switch (vm.state) {
      LibraryStateIdle() => const [
          SliverFillRemaining(child: SizedBox.shrink()),
        ],
      LibraryStateLoading() => const [
          SliverFillRemaining(child: _LoadingView()),
        ],
      LibraryStateSuccess(:final notations) => _buildSuccessSlivers(
          context: context,
          vm: vm,
          notations: notations,
        ),
      LibraryStateError(:final message) => [
          SliverFillRemaining(child: _ErrorView(message: message)),
        ],
    };
  }

  List<Widget> _buildSuccessSlivers({
    required BuildContext context,
    required LibraryViewModel vm,
    required List<Notation> notations,
  }) {
    final recent = switch (vm.recentlyPlayedState) {
      RecentlyPlayedStateSuccess(:final notations) => notations,
      RecentlyPlayedStateIdle() => const <Notation>[],
    };

    final hasContent = notations.isNotEmpty || recent.isNotEmpty;
    if (!hasContent) {
      return const [SliverFillRemaining(child: _EmptyView())];
    }

    return [
      if (recent.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: RecentlyPlayedCarousel(
              notations: recent,
              onTap: widget.onNotationTap ?? (_) {},
            ),
          ),
        ),
      if (notations.isEmpty)
        const SliverFillRemaining(child: _EmptyView())
      else
        SliverPadding(
          padding: _kListPadding,
          sliver: SliverList.builder(
            itemCount: notations.length,
            itemBuilder: (context, index) => _NotationRow(
              notation: notations[index],
              screen: widget,
            ),
          ),
        ),
    ];
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

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

/// Inline [SearchBar] for live fuzzy-search of the notation list.
///
/// Text changes are forwarded to [onChanged] so the ViewModel can debounce
/// and execute the search. The clear (X) button appears when the [controller]
/// has non-empty text and resets the query via [onClear].
///
/// Uses [ListenableBuilder] to rebuild the trailing icon whenever [controller]
/// changes, ensuring the button appears and disappears reactively.
class _LibrarySearchBar extends StatelessWidget {
  const _LibrarySearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  /// Controls the text shown in the search bar.
  final SearchController controller;

  /// Called on each text change with the new query string.
  final ValueChanged<String> onChanged;

  /// Called when the user taps the clear button.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _kSearchBarPadding,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SearchBar(
          controller: controller,
          hintText: 'Search notations…',
          leading: const Icon(Icons.search_outlined),
          trailing: [
            if (controller.text.isNotEmpty)
              Semantics(
                label: 'Clear search',
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    controller.clear();
                    onClear();
                  },
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notation row
// ---------------------------------------------------------------------------

/// A single library row with swipe-to-delete, undo SnackBar, and long-press
/// edit menu.
class _NotationRow extends StatelessWidget {
  const _NotationRow({required this.notation, required this.screen});

  final Notation notation;
  final LibraryScreen screen;

  @override
  Widget build(BuildContext context) {
    final canEdit = screen.notationRepository != null &&
        screen.tagRepository != null &&
        screen.instrumentRepository != null &&
        screen.customFieldRepository != null &&
        screen.fileStorageService != null;

    return Dismissible(
      key: ValueKey(notation.id),
      direction: DismissDirection.endToStart,
      background: const _SwipeDeleteBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      // Removal from list is driven by the stream; no local state needed.
      onDismissed: (_) {},
      child: Semantics(
        label: notation.title,
        child: canEdit
            ? GestureDetector(
                onLongPress: () => _showContextMenu(context),
                child: NotationCard(
                  notation: notation,
                  onTap: screen.onNotationTap != null
                      ? () => screen.onNotationTap!(notation.id)
                      : null,
                ),
              )
            : NotationCard(
                notation: notation,
                onTap: screen.onNotationTap != null
                    ? () => screen.onNotationTap!(notation.id)
                    : null,
              ),
      ),
    );
  }

  Future<void> _showContextMenu(BuildContext context) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height,
    );

    final choice = await showMenu<String>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(
                Icons.copy_outlined,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 12),
              const Text('Duplicate'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted) return;

    if (choice == 'edit') {
      await _openEdit(context);
    } else if (choice == 'duplicate') {
      await _duplicate(context);
    }
  }

  Future<void> _openEdit(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditNotationScreen(
          notationId: notation.id,
          notationRepository: screen.notationRepository!,
          tagRepository: screen.tagRepository!,
          instrumentRepository: screen.instrumentRepository!,
          customFieldRepository: screen.customFieldRepository!,
          fileStorageService: screen.fileStorageService!,
        ),
      ),
    );
    // No reload needed — LibraryViewModel observes the notation stream.
  }

  Future<void> _duplicate(BuildContext context) async {
    final vm = context.read<LibraryViewModel>();
    await vm.duplicate(notation.id);

    if (!context.mounted) return;

    if (vm.operationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not duplicate notation. Please try again.'),
        ),
      );
      vm.clearOperationError();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${notation.title} (copy)" created.'),
      ),
    );
    vm.clearLastDuplicatedId();
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
        const SnackBar(
          content: Text('Could not delete notation. Please try again.'),
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

// ---------------------------------------------------------------------------
// _NamePromptDialog
// ---------------------------------------------------------------------------

/// Blocking first-launch dialog that asks the user for their display name.
///
/// The dialog cannot be dismissed without entering a non-empty name. The
/// [FilledButton] is disabled while the text field is empty. On save, [onSave]
/// is called with the trimmed name.
class _NamePromptDialog extends StatefulWidget {
  /// Creates a [_NamePromptDialog].
  ///
  /// Parameters:
  /// - [controller]: The [TextEditingController] for the name input.
  /// - [onSave]: Called with the trimmed name when the user taps "Save".
  const _NamePromptDialog({
    required this.controller,
    required this.onSave,
  });

  /// Shared controller so the caller can dispose after the dialog closes.
  final TextEditingController controller;

  /// Invoked with the trimmed, non-empty name on save.
  final void Function(String name) onSave;

  @override
  State<_NamePromptDialog> createState() => _NamePromptDialogState();
}

class _NamePromptDialogState extends State<_NamePromptDialog> {
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final empty = widget.controller.text.trim().isEmpty;
    if (empty != _isEmpty) {
      setState(() => _isEmpty = empty);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("What's your name?"),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: _isEmpty
            ? null
            : (_) => widget.onSave(widget.controller.text.trim()),
        decoration: const InputDecoration(
          hintText: 'Enter your name',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: _isEmpty
              ? null
              : () => widget.onSave(widget.controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
