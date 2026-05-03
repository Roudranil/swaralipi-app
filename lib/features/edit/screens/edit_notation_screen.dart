// edit_notation_screen.dart — Orchestration screen for the edit-notation flow.
//
// Route: push-only (not registered in GoRouter yet; launched via
//   Navigator.push from LibraryScreen or NotationDetailScreen)
//
// Flow:
//   EditNotationScreen (loads existing notation)
//     → PageEditorScreen (adjust per-page render params)
//       → EditMetadataFormScreen (update metadata)
//         → [pop to NotationDetailScreen]
//
// The screen owns and provides three ViewModels:
//   - [EditNotationViewModel]: loads the notation and persists changes.
//   - [CaptureSessionViewModel]: holds the in-memory page list used by the
//     page editor. Pre-populated from [EditNotationViewModel.existingPages]
//     paths via [FileReader] after load completes.
//   - [PageEditorViewModel]: wraps [CaptureSessionViewModel] for per-page
//     editing (filter, rotate, crop, reorder).
//
// On "Save" from the metadata form, the screen calls
// [EditNotationViewModel.save] with the updated pages from the session and
// navigates back to [NotationDetailScreen] via [Navigator.popUntil].

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/features/capture/models/capture_page_draft.dart';
import 'package:swaralipi/features/capture/viewmodels/capture_session_view_model.dart';
import 'package:swaralipi/features/capture/viewmodels/page_editor_view_model.dart';
import 'package:swaralipi/features/capture/screens/page_editor_screen.dart';
import 'package:swaralipi/features/edit/screens/edit_metadata_form_screen.dart';
import 'package:swaralipi/features/edit/viewmodels/edit_notation_view_model.dart';
import 'package:swaralipi/shared/models/notation_page.dart';
import 'package:swaralipi/shared/models/render_params.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Orchestration screen that drives the edit-notation flow.
///
/// Loads the existing [NotationDetail] via [EditNotationViewModel], then
/// transitions through [PageEditorScreen] and [EditMetadataFormScreen].
/// On completion, pops back to the caller (typically [NotationDetailScreen]).
///
/// Dependencies are injected at the call site via [create] factories in
/// [ChangeNotifierProvider] widgets.
class EditNotationScreen extends StatefulWidget {
  /// Creates an [EditNotationScreen] for the notation with [notationId].
  ///
  /// Parameters:
  /// - [notationId]: UUIDv4 of the notation to edit.
  /// - [notationRepository]: Used to load and update the notation.
  /// - [tagRepository]: Source of truth for tags (needed by metadata form).
  /// - [instrumentRepository]: Source of truth for instruments.
  /// - [customFieldRepository]: Source of truth for custom field definitions.
  /// - [fileStorageService]: Resolves stored relative paths to absolute paths.
  const EditNotationScreen({
    required this.notationId,
    required this.notationRepository,
    required this.tagRepository,
    required this.instrumentRepository,
    required this.customFieldRepository,
    required this.fileStorageService,
    super.key,
  });

  /// UUIDv4 of the notation to edit.
  final String notationId;

  /// Used to load and update the notation.
  final NotationRepository notationRepository;

  /// Source of truth for tags, passed to [EditMetadataFormScreen].
  final TagRepository tagRepository;

  /// Source of truth for instruments, passed to [EditMetadataFormScreen].
  final InstrumentRepository instrumentRepository;

  /// Source of truth for custom field definitions.
  final CustomFieldRepository customFieldRepository;

  /// Resolves stored relative paths to absolute paths for the page editor.
  final FileStorageService fileStorageService;

  @override
  State<EditNotationScreen> createState() => _EditNotationScreenState();
}

class _EditNotationScreenState extends State<EditNotationScreen> {
  late final EditNotationViewModel _editVm;
  late final CaptureSessionViewModel _sessionVm;
  late final PageEditorViewModel _pageEditorVm;

  @override
  void initState() {
    super.initState();
    _editVm = EditNotationViewModel(
      notationRepository: widget.notationRepository,
    );
    _sessionVm = CaptureSessionViewModel();
    _pageEditorVm = PageEditorViewModel(session: _sessionVm);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadNotation();
    });
  }

  Future<void> _loadNotation() async {
    await _editVm.loadNotation(widget.notationId);
    if (!mounted) return;

    if (_editVm.state is EditNotationStateSuccess) {
      await _populateSession(_editVm.existingPages);
    }
  }

  /// Reads each existing page's image bytes from disk and loads them into
  /// [_sessionVm] so [PageEditorScreen] can render them.
  ///
  /// Uses [FileStorageService.getAbsolutePath] to resolve relative paths.
  Future<void> _populateSession(List<NotationPage> pages) async {
    final drafts = <CapturePageDraft>[];
    for (final page in pages) {
      try {
        final absPath =
            await widget.fileStorageService.getAbsolutePath(page.imagePath);
        final bytes = await File(absPath).readAsBytes();
        final renderParams = _parseRenderParams(page.renderParams);
        drafts.add(
          CapturePageDraft(
            originalPath: absPath,
            originalBytes: bytes,
            renderParams: renderParams,
          ),
        );
      } on Exception catch (e, st) {
        log(
          'EditNotationScreen: could not load page "${page.id}": $e',
          name: 'EditNotationScreen',
          error: e,
          stackTrace: st,
        );
      }
    }
    _sessionVm.replacePages(drafts);
  }

  RenderParams _parseRenderParams(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        return RenderParams.fromJson(decoded);
      }
    } on FormatException catch (e) {
      log(
        'EditNotationScreen: failed to parse renderParams "$json": $e',
        name: 'EditNotationScreen',
      );
    }
    return RenderParams.identity;
  }

  @override
  void dispose() {
    _pageEditorVm.dispose();
    _sessionVm.dispose();
    _editVm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EditNotationViewModel>.value(value: _editVm),
        ChangeNotifierProvider<CaptureSessionViewModel>.value(
            value: _sessionVm),
        ChangeNotifierProvider<PageEditorViewModel>.value(value: _pageEditorVm),
      ],
      child: const _EditNotationBody(),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

/// Renders the correct state for the edit flow.
class _EditNotationBody extends StatelessWidget {
  const _EditNotationBody();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditNotationViewModel>();

    return switch (vm.state) {
      EditNotationStateIdle() ||
      EditNotationStateLoading() =>
        const _LoadingScaffold(),
      EditNotationStateNotFound() => const _NotFoundScaffold(),
      EditNotationStateError(:final message) =>
        _ErrorScaffold(message: message),
      EditNotationStateSuccess() => _EditFlowScaffold(editVm: vm),
    };
  }
}

// ---------------------------------------------------------------------------
// Edit flow scaffold
// ---------------------------------------------------------------------------

/// Main scaffold once the notation is loaded.
///
/// Presents [PageEditorScreen]; on "Next", navigates to
/// [EditMetadataFormScreen].
class _EditFlowScaffold extends StatelessWidget {
  const _EditFlowScaffold({required this.editVm});

  final EditNotationViewModel editVm;

  @override
  Widget build(BuildContext context) {
    return PageEditorScreen(
      onNext: (context) => _navigateToMetadataForm(context),
    );
  }

  void _navigateToMetadataForm(BuildContext context) {
    final editVmLocal = context.read<EditNotationViewModel>();
    final sessionVm = context.read<CaptureSessionViewModel>();
    final screen = context.findAncestorWidgetOfExactType<EditNotationScreen>();
    if (screen == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<EditNotationViewModel>.value(
              value: editVmLocal,
            ),
            ChangeNotifierProvider<CaptureSessionViewModel>.value(
              value: sessionVm,
            ),
          ],
          child: EditMetadataFormScreen(
            notationId: editVmLocal.state is EditNotationStateSuccess
                ? (editVmLocal.state as EditNotationStateSuccess).notationId
                : '',
            tagRepository: screen.tagRepository,
            instrumentRepository: screen.instrumentRepository,
            customFieldRepository: screen.customFieldRepository,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading / error / not-found scaffolds
// ---------------------------------------------------------------------------

/// Loading scaffold shown while the notation is being fetched.
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Notation')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Scaffold shown when the notation id does not exist.
class _NotFoundScaffold extends StatelessWidget {
  const _NotFoundScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Notation')),
      body: Center(
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
      ),
    );
  }
}

/// Scaffold shown when loading fails with an exception.
class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Notation')),
      body: Center(
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
      ),
    );
  }
}
