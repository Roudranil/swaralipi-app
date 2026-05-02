// NotationPlayerScreen — full-screen notation page viewer.
//
// Route: /notation/:id/player
//
// Behaviour:
//   - PageView.builder swipes between notation pages.
//   - Each page is wrapped in an InteractiveViewer (pinch-zoom, pan).
//   - Page images are loaded as Files via FileStorageService; RenderParams
//     are stored per page but pixel-accurate composite rendering (via
//     ImageProcessingService.apply + compute()) is intentionally out of scope
//     for this task — the raw original image is shown in the player.
//     Non-destructive rendering is handled by the Page Editor flow.
//   - Title + page indicator fade in/out (chrome) on tap after 2 s idle.
//   - Back navigation returns to the previous screen.
//
// The screen reads [NotationPlayerViewModel] from a [ChangeNotifierProvider]
// and calls [loadNotation] in [initState].
//
// Construction (from the route builder in app.dart):
//   ChangeNotifierProvider(
//     create: (_) => NotationPlayerViewModel(repo, notationId: id, startPage: page),
//     child: const NotationPlayerScreen(),
//   )

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/player/viewmodels/notation_player_view_model.dart';
import 'package:swaralipi/shared/models/notation_detail.dart';
import 'package:swaralipi/shared/models/notation_page.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Duration after which the chrome (title + toolbar) fades out.
const Duration _kChromeFadeDuration = Duration(seconds: 2);

/// Animation duration for the chrome fade-in / fade-out.
const Duration _kChromeAnimationDuration = Duration(milliseconds: 300);

/// Minimum scale for [InteractiveViewer] pinch-zoom.
const double _kMinScale = 0.5;

/// Maximum scale for [InteractiveViewer] pinch-zoom.
const double _kMaxScale = 5.0;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Full-screen notation page viewer.
///
/// Reads [NotationPlayerViewModel] from the widget tree via
/// [ChangeNotifierProvider] and renders the appropriate state view.
class NotationPlayerScreen extends StatefulWidget {
  /// Creates a [NotationPlayerScreen].
  const NotationPlayerScreen({super.key});

  @override
  State<NotationPlayerScreen> createState() => _NotationPlayerScreenState();
}

class _NotationPlayerScreenState extends State<NotationPlayerScreen> {
  late PageController _pageController;
  Timer? _chromeFadeTimer;

  @override
  void initState() {
    super.initState();
    final vm = context.read<NotationPlayerViewModel>();
    _pageController = PageController(initialPage: vm.currentPage);
    // Defer load to after the first frame to avoid notifyListeners during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final vm = context.read<NotationPlayerViewModel>();
    await vm.loadNotation();
    if (!mounted) return;
    final vmAfterLoad = context.read<NotationPlayerViewModel>();
    // Sync PageController only when it is attached to a PageView and the
    // current page differs from the controller's page.
    if (vmAfterLoad.pageCount > 0 &&
        _pageController.hasClients &&
        _pageController.page?.round() != vmAfterLoad.currentPage) {
      _pageController.jumpToPage(vmAfterLoad.currentPage);
    }
    // Start the chrome fade timer only after load completes successfully.
    if (vmAfterLoad.state is NotationPlayerStateSuccess) {
      _scheduleFade();
    }
  }

  void _scheduleFade() {
    _chromeFadeTimer?.cancel();
    _chromeFadeTimer = Timer(_kChromeFadeDuration, () {
      if (!mounted) return;
      context.read<NotationPlayerViewModel>().hideChrome();
    });
  }

  void _onTapScreen() {
    final vm = context.read<NotationPlayerViewModel>();
    if (vm.isChromeVisible) {
      vm.hideChrome();
      _chromeFadeTimer?.cancel();
    } else {
      vm.showChrome();
      _scheduleFade();
    }
  }

  @override
  void dispose() {
    _chromeFadeTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep status bar hidden for immersive full-screen feel.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final vm = context.watch<NotationPlayerViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (vm.state) {
        NotationPlayerStateIdle() ||
        NotationPlayerStateLoading() =>
          const _LoadingView(),
        NotationPlayerStateNotFound() => const _NotFoundView(),
        NotationPlayerStateError(:final message) => _ErrorView(message),
        NotationPlayerStateSuccess(:final detail) => _PlayerView(
            detail: detail,
            vm: vm,
            pageController: _pageController,
            onTap: _onTapScreen,
          ),
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading view
// ---------------------------------------------------------------------------

/// Displayed while the notation is loading.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

// ---------------------------------------------------------------------------
// Not-found view
// ---------------------------------------------------------------------------

/// Displayed when the notation does not exist.
class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.music_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Notation not found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go back'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error view
// ---------------------------------------------------------------------------

/// Displayed when loading the notation failed.
class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
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
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading notation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Player view — main content
// ---------------------------------------------------------------------------

/// The main player content shown in [NotationPlayerStateSuccess].
class _PlayerView extends StatelessWidget {
  const _PlayerView({
    required this.detail,
    required this.vm,
    required this.pageController,
    required this.onTap,
  });

  final NotationDetail detail;
  final NotationPlayerViewModel vm;
  final PageController pageController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pageCount = detail.pages.length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Page content.
          PageView.builder(
            controller: pageController,
            itemCount: pageCount,
            onPageChanged: (index) => vm.goToPage(index),
            itemBuilder: (context, index) => _PageView(
              page: detail.pages[index],
            ),
          ),

          // Title bar (top chrome).
          _TitleChrome(
            title: detail.notation.title,
            isVisible: vm.isChromeVisible,
          ),

          // Page indicator + bottom toolbar chrome.
          _BottomChrome(
            currentPage: vm.currentPage,
            pageCount: pageCount,
            isVisible: vm.isChromeVisible,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual page — InteractiveViewer + image
// ---------------------------------------------------------------------------

/// Renders a single notation page inside an [InteractiveViewer].
class _PageView extends StatelessWidget {
  const _PageView({required this.page});

  final NotationPage page;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: _kMinScale,
      maxScale: _kMaxScale,
      child: _PageImage(imagePath: page.imagePath),
    );
  }
}

// ---------------------------------------------------------------------------
// Page image — loaded from disk via FileStorageService
// ---------------------------------------------------------------------------

/// Loads and displays a notation page image from the local file system.
class _PageImage extends StatefulWidget {
  const _PageImage({required this.imagePath});

  /// Relative path to the image (as stored in the database).
  final String imagePath;

  @override
  State<_PageImage> createState() => _PageImageState();
}

class _PageImageState extends State<_PageImage> {
  late final Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _resolveFile();
  }

  Future<File> _resolveFile() async {
    final service = FileStorageService();
    final absPath = await service.getAbsolutePath(widget.imagePath);
    return File(absPath);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (snapshot.hasError) {
          log(
            '_PageImageState: failed to load image '
            '${widget.imagePath}: ${snapshot.error}',
            name: '_PageImageState',
          );
          return Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        final file = snapshot.data!;
        return Center(
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (_, error, __) {
              log(
                '_PageImageState: Image.file error for '
                '${widget.imagePath}: $error',
                name: '_PageImageState',
              );
              return Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Title chrome (top)
// ---------------------------------------------------------------------------

/// Animated title bar shown at the top of the player.
class _TitleChrome extends StatelessWidget {
  const _TitleChrome({
    required this.title,
    required this.isVisible,
  });

  final String title;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: _kChromeAnimationDuration,
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom chrome (page indicator)
// ---------------------------------------------------------------------------

/// Animated bottom bar showing the page indicator.
class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.currentPage,
    required this.pageCount,
    required this.isVisible,
  });

  final int currentPage;
  final int pageCount;
  final bool isVisible;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: _kChromeAnimationDuration,
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SafeArea(
            top: false,
            child: Center(
              child: Semantics(
                label: 'Page ${currentPage + 1} of $pageCount',
                child: Text(
                  '${currentPage + 1} / $pageCount',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
