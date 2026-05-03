// NotationDetailScreen — screen showing full details for a single notation.
//
// Route: /notation/:id
//
// The screen observes [NotationDetailViewModel] via [ChangeNotifierProvider]
// and renders one of five states: idle, loading, success, notFound, error.
//
// Delete interaction: the AppBar "Delete" action opens a confirmation dialog.
// On confirmation the notation is soft-deleted, a SnackBar with an "Undo"
// action appears for 5 seconds, and the screen navigates back to the library
// (route '/').
//
// Edit interaction: the AppBar "Edit" action launches [EditNotationScreen]
// via [Navigator.push]. On return the notation detail is reloaded to reflect
// any changes.
//
// Dependencies are injected at the call site:
//   ChangeNotifierProvider<NotationDetailViewModel>(
//     create: (_) => NotationDetailViewModel(
//       notationRepository,
//       trashRepository,
//     ),
//     child: NotationDetailScreen(
//       notationId: id,
//       notationRepository: notationRepository,
//       tagRepository: tagRepository,
//       instrumentRepository: instrumentRepository,
//       customFieldRepository: customFieldRepository,
//       fileStorageService: fileStorageService,
//     ),
//   )

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/edit/screens/edit_notation_screen.dart';
import 'package:swaralipi/features/notation_detail/viewmodels/notation_detail_view_model.dart';
import 'package:swaralipi/features/player/screens/notation_player_screen.dart';
import 'package:swaralipi/features/player/viewmodels/notation_player_view_model.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Duration the "Undo" SnackBar is visible before the deletion is final.
const Duration _kUndoDuration = Duration(seconds: 5);

/// Horizontal padding for detail content sections.
const EdgeInsets _kContentPadding =
    EdgeInsets.symmetric(horizontal: 16, vertical: 8);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Detail screen for a single notation.
///
/// Reads [NotationDetailViewModel] from the widget tree. Calls
/// [NotationDetailViewModel.loadNotation] after the first frame.
///
/// When the edit dependencies are provided the AppBar shows an Edit action
/// that launches [EditNotationScreen]. On return the notation is reloaded.
class NotationDetailScreen extends StatefulWidget {
  /// Creates a [NotationDetailScreen] for the notation with [notationId].
  ///
  /// Parameters:
  /// - [notationId]: UUIDv4 of the notation to display.
  /// - [notationRepository]: Passed to [EditNotationScreen] when editing.
  /// - [tagRepository]: Passed to [EditNotationScreen] when editing.
  /// - [instrumentRepository]: Passed to [EditNotationScreen] when editing.
  /// - [customFieldRepository]: Passed to [EditNotationScreen] when editing.
  /// - [fileStorageService]: Passed to [EditNotationScreen] when editing.
  const NotationDetailScreen({
    required this.notationId,
    this.notationRepository,
    this.preferencesRepository,
    this.tagRepository,
    this.instrumentRepository,
    this.customFieldRepository,
    this.fileStorageService,
    super.key,
  });

  /// UUIDv4 of the notation to display.
  final String notationId;

  /// Used by [EditNotationScreen]. When null the Edit action is hidden.
  final NotationRepository? notationRepository;

  /// Used by [NotationPlayerScreen] to persist orientation preferences.
  final PreferencesRepository? preferencesRepository;

  /// Used by [EditNotationScreen] for tag picker.
  final TagRepository? tagRepository;

  /// Used by [EditNotationScreen] for instrument picker.
  final InstrumentRepository? instrumentRepository;

  /// Used by [EditNotationScreen] for custom field inputs.
  final CustomFieldRepository? customFieldRepository;

  /// Used by [EditNotationScreen] to resolve image paths.
  final FileStorageService? fileStorageService;

  @override
  State<NotationDetailScreen> createState() => _NotationDetailScreenState();
}

class _NotationDetailScreenState extends State<NotationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotationDetailViewModel>().loadNotation(widget.notationId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotationDetailViewModel>();
    final canEdit = vm.state is NotationDetailStateSuccess &&
        widget.notationRepository != null &&
        widget.tagRepository != null &&
        widget.instrumentRepository != null &&
        widget.customFieldRepository != null &&
        widget.fileStorageService != null;

    return Scaffold(
      appBar: AppBar(
        title: _AppBarTitle(state: vm.state),
        actions: [
          if (canEdit)
            Semantics(
              label: 'Edit notation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
                onPressed: () => _openEdit(context, vm),
              ),
            ),
          if (vm.state is NotationDetailStateSuccess)
            Semantics(
              label: 'Duplicate notation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.copy_outlined),
                tooltip: 'Duplicate',
                onPressed: () => _duplicate(context, vm),
              ),
            ),
          if (vm.state is NotationDetailStateSuccess)
            Semantics(
              label: 'Open notation player',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.play_circle_outline),
                tooltip: 'Play',
                onPressed: () => _openPlayer(context),
              ),
            ),
          if (vm.state is NotationDetailStateSuccess)
            Semantics(
              label: 'Delete notation',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, vm, widget.notationId),
              ),
            ),
        ],
      ),
      body: switch (vm.state) {
        NotationDetailStateIdle() => const SizedBox.shrink(),
        NotationDetailStateLoading() => const _LoadingView(),
        NotationDetailStateSuccess(:final detail) =>
          _DetailContent(detail: detail),
        NotationDetailStateNotFound() => const _NotFoundView(),
        NotationDetailStateError(:final message) =>
          _ErrorView(message: message),
      },
    );
  }

  Future<void> _openPlayer(BuildContext context) async {
    final notationRepository = widget.notationRepository;
    if (notationRepository == null) return;

    final prefsRepo =
        widget.preferencesRepository ?? const _NoOpPreferencesRepository();

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ChangeNotifierProvider<NotationPlayerViewModel>(
          create: (_) => NotationPlayerViewModel(
            notationRepository,
            preferencesRepository: prefsRepo,
            notationId: widget.notationId,
          ),
          child: const NotationPlayerScreen(),
        ),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context,
    NotationDetailViewModel vm,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EditNotationScreen(
          notationId: widget.notationId,
          notationRepository: widget.notationRepository!,
          tagRepository: widget.tagRepository!,
          instrumentRepository: widget.instrumentRepository!,
          customFieldRepository: widget.customFieldRepository!,
          fileStorageService: widget.fileStorageService!,
        ),
      ),
    );
    if (!context.mounted) return;
    // Reload so the detail view reflects any saved changes.
    vm.loadNotation(widget.notationId);
  }

  Future<void> _duplicate(
    BuildContext context,
    NotationDetailViewModel vm,
  ) async {
    await vm.duplicate(widget.notationId);

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

    final newId = vm.lastDuplicatedId;
    vm.clearLastDuplicatedId();

    if (newId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notation duplicated.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    NotationDetailViewModel vm,
    String id,
  ) async {
    final title = vm.state is NotationDetailStateSuccess
        ? (vm.state as NotationDetailStateSuccess).detail.notation.title
        : 'this notation';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move to Trash?'),
        content: Text(
          '"$title" will be moved to Trash. '
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

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Navigate back and show the undo SnackBar from the library context.
    // The onDeleted callback fires after softDelete succeeds.
    await vm.softDelete(
      id,
      onDeleted: () {
        if (!context.mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showUndoSnackBar(context, vm, id, title);
      },
    );

    if (!context.mounted) return;

    if (vm.operationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete notation. Please try again.'),
        ),
      );
      vm.clearOperationError();
    }
  }

  void _showUndoSnackBar(
    BuildContext context,
    NotationDetailViewModel vm,
    String id,
    String title,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"$title" moved to Trash.'),
          duration: _kUndoDuration,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => vm.undoDelete(id),
          ),
        ),
      );
  }
}

// ---------------------------------------------------------------------------
// AppBar title
// ---------------------------------------------------------------------------

/// Adaptive title widget for the detail AppBar.
///
/// Shows the notation title once loaded, or a placeholder otherwise.
class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({required this.state});

  final NotationDetailState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NotationDetailStateSuccess(:final detail) =>
        Text(detail.notation.title, overflow: TextOverflow.ellipsis),
      _ => const Text('Notation'),
    };
  }
}

// ---------------------------------------------------------------------------
// Private state views
// ---------------------------------------------------------------------------

/// Loading indicator while the notation is being fetched.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Shown when the notation id does not exist in the repository.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Notation not found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when loading fails with an exception.
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
              'Failed to load notation',
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
// Detail content
// ---------------------------------------------------------------------------

/// Main content for a successfully loaded notation.
class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail});

  final NotationDetail detail;

  @override
  Widget build(BuildContext context) {
    final n = detail.notation;
    return SingleChildScrollView(
      padding: _kContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: n.title),
          const SizedBox(height: 8),
          if (n.artists.isNotEmpty) ...[
            _MetadataRow(
              icon: Icons.person_outline,
              label: n.artists.join(', '),
            ),
            const SizedBox(height: 4),
          ],
          if (n.languages.isNotEmpty) ...[
            _MetadataRow(
              icon: Icons.language_outlined,
              label: n.languages.join(', '),
            ),
            const SizedBox(height: 4),
          ],
          if (n.timeSig != null) ...[
            _MetadataRow(
              icon: Icons.access_time_outlined,
              label: n.timeSig!,
            ),
            const SizedBox(height: 4),
          ],
          if (n.keySig != null) ...[
            _MetadataRow(
              icon: Icons.music_note_outlined,
              label: n.keySig!,
            ),
            const SizedBox(height: 4),
          ],
          if (n.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              n.notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),
          if (detail.pages.isNotEmpty) ...[
            Text(
              'Pages (${detail.pages.length})',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Large title for the notation.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }
}

/// A row showing an icon and a metadata label.
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// No-op PreferencesRepository fallback
// ---------------------------------------------------------------------------

/// A no-op [PreferencesRepository] used when no real implementation is
/// injected into [NotationDetailScreen].
///
/// All write methods are no-ops. [getPreferences] returns a default singleton.
final class _NoOpPreferencesRepository implements PreferencesRepository {
  const _NoOpPreferencesRepository();

  @override
  Future<UserPreferences> getPreferences() async => const UserPreferences(
        userName: 'Musician',
        themeMode: AppThemeMode.system,
        colorSchemeMode: ColorSchemeMode.catppuccin,
        defaultSort: SortOrder.createdAtDesc,
        defaultView: ViewMode.list,
      );

  @override
  Future<void> updatePreferences(UserPreferences preferences) async {}

  @override
  Future<void> updateThemeMode(AppThemeMode mode) async {}

  @override
  Future<void> updateColorSchemeMode(ColorSchemeMode mode) async {}

  @override
  Future<void> updateSeedColor(String? colorHex) async {}

  @override
  Future<void> updateTagsSeeded({required bool value}) async {}

  @override
  Future<void> updatePlayerOrientation(PlayerOrientation orientation) async {}

  @override
  Future<void> updateAutoScrollSpeed(double speed) async {}
}
