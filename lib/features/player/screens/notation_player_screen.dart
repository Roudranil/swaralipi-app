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
//   - Title + page indicator fade in/out (chrome) on tap after 3 s idle.
//   - Orientation lock toggle (auto / portrait / landscape) in bottom chrome.
//   - Auto-scroll toggle + speed slider shown in bottom chrome when enabled.
//   - Timer.periodic drives smooth scroll; pauses on swipe gesture.
//   - Back navigation returns to the previous screen.
//
// The screen reads [NotationPlayerViewModel] from a [ChangeNotifierProvider]
// and calls [loadNotation] in [initState].
//
// Construction (from the route builder in app.dart):
//   ChangeNotifierProvider(
//     create: (_) => NotationPlayerViewModel(
//       repo,
//       preferencesRepository: prefsRepo,
//       notationId: id,
//       startPage: page,
//     ),
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
import 'package:swaralipi/shared/models/user_preferences.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Animation duration for the chrome fade-in / fade-out.
const Duration _kChromeAnimationDuration = Duration(milliseconds: 300);

/// Minimum scale for [InteractiveViewer] pinch-zoom.
const double _kMinScale = 0.5;

/// Maximum scale for [InteractiveViewer] pinch-zoom.
const double _kMaxScale = 5.0;

/// Slider step increment for the auto-scroll speed control.
const double _kSpeedSliderStep = 0.1;

/// Scroll animation duration per tick — short for smoothness.
const Duration _kScrollAnimationDuration = Duration(milliseconds: 80);

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
  Timer? _autoScrollTimer;

  /// Whether a swipe gesture is currently active (suppresses auto-scroll tick).
  bool _isSwiping = false;

  /// Cached reference to the ViewModel so we can remove the listener in
  /// [dispose] without needing [BuildContext] after unmount.
  late NotationPlayerViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = context.read<NotationPlayerViewModel>();
    _pageController = PageController(initialPage: _vm.currentPage);
    // Listen to ViewModel to sync the auto-scroll timer outside build().
    _vm.addListener(_onViewModelChanged);
    // Defer load to after the first frame to avoid notifyListeners during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// Responds to ViewModel changes to keep the auto-scroll timer in sync.
  ///
  /// Runs outside [build] so Timer management is a side-effect-free listener.
  void _onViewModelChanged() {
    if (!mounted) return;
    if (_vm.autoScrollEnabled) {
      if (_autoScrollTimer == null || !_autoScrollTimer!.isActive) {
        _startAutoScrollTimer(_vm);
      }
    } else {
      if (_autoScrollTimer != null && _autoScrollTimer!.isActive) {
        _cancelAutoScrollTimer();
      }
    }
  }

  Future<void> _load() async {
    await _vm.loadNotation();
    if (!mounted) return;
    // Load the persisted speed preference so the slider starts at the last
    // used value.
    await _vm.loadPersistedSpeed();
    if (!mounted) return;
    // Sync PageController only when it is attached to a PageView and the
    // current page differs from the controller's page.
    if (_vm.pageCount > 0 &&
        _pageController.hasClients &&
        _pageController.page?.round() != _vm.currentPage) {
      _pageController.jumpToPage(_vm.currentPage);
    }
    // Start the chrome fade timer only after load completes successfully.
    if (_vm.state is NotationPlayerStateSuccess) {
      _scheduleFade();
    }
  }

  void _scheduleFade() {
    _chromeFadeTimer?.cancel();
    _chromeFadeTimer = Timer(kChromeFadeDuration, () {
      if (!mounted) return;
      _vm.hideChrome();
    });
  }

  void _onTapScreen() {
    if (_vm.isChromeVisible) {
      _vm.hideChrome();
      _chromeFadeTimer?.cancel();
    } else {
      _vm.showChrome();
      _scheduleFade();
    }
  }

  // ---------------------------------------------------------------------------
  // Auto-scroll
  // ---------------------------------------------------------------------------

  /// Starts or restarts the [Timer.periodic] that drives smooth auto-scroll.
  void _startAutoScrollTimer(NotationPlayerViewModel vm) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: kAutoScrollTickIntervalMs),
      (_) => _onAutoScrollTick(),
    );
  }

  /// Cancels the auto-scroll timer without changing ViewModel state.
  void _cancelAutoScrollTimer() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  /// Advances the scroll position by one step on each timer tick.
  ///
  /// Skips the tick when a swipe is in progress or the controller has no
  /// clients. Stops auto-scroll when the end of the content is reached.
  void _onAutoScrollTick() {
    if (!mounted || _isSwiping) return;
    if (!_pageController.hasClients) return;

    final position = _pageController.position;
    final viewportHeight = position.viewportDimension;
    final step = NotationPlayerViewModel.calculateScrollStep(
      speed: _vm.autoScrollSpeed,
      viewportHeight: viewportHeight,
      tickIntervalMs: kAutoScrollTickIntervalMs,
    );

    final currentOffset = position.pixels;
    final maxOffset = position.maxScrollExtent;

    if (currentOffset >= maxOffset) {
      // Reached the end — stop auto-scroll.
      _vm.stopAutoScroll();
      _cancelAutoScrollTimer();
      return;
    }

    final targetOffset = (currentOffset + step).clamp(0.0, maxOffset);
    _pageController.animateTo(
      targetOffset,
      duration: _kScrollAnimationDuration,
      curve: Curves.linear,
    );
  }

  /// Called when the user starts a drag/swipe gesture.
  void _onScrollStart() {
    _isSwiping = true;
    // Pause auto-scroll while swiping.
    if (_vm.autoScrollEnabled) {
      _cancelAutoScrollTimer();
    }
  }

  /// Called when the user ends a drag/swipe gesture.
  void _onScrollEnd() {
    _isSwiping = false;
    // Resume auto-scroll if still enabled after the swipe.
    if (_vm.autoScrollEnabled) {
      _startAutoScrollTimer(_vm);
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onViewModelChanged);
    _chromeFadeTimer?.cancel();
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    // Restore auto-rotate when leaving the player.
    SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keep status bar hidden for immersive full-screen feel.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final vm = context.watch<NotationPlayerViewModel>();

    // Apply orientation lock whenever it changes.
    _applyOrientationLock(vm.playerOrientation);

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
            onScrollStart: _onScrollStart,
            onScrollEnd: _onScrollEnd,
          ),
      },
    );
  }

  /// Applies the orientation lock via [SystemChrome].
  void _applyOrientationLock(PlayerOrientation orientation) {
    final orientations = switch (orientation) {
      PlayerOrientation.auto => <DeviceOrientation>[],
      PlayerOrientation.portrait => [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ],
      PlayerOrientation.landscape => [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
    };
    SystemChrome.setPreferredOrientations(orientations);
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
    required this.onScrollStart,
    required this.onScrollEnd,
  });

  final NotationDetail detail;
  final NotationPlayerViewModel vm;
  final PageController pageController;
  final VoidCallback onTap;
  final VoidCallback onScrollStart;
  final VoidCallback onScrollEnd;

  @override
  Widget build(BuildContext context) {
    final pageCount = detail.pages.length;

    return GestureDetector(
      onTap: onTap,
      onPanStart: (_) => onScrollStart(),
      onPanEnd: (_) => onScrollEnd(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          // Page content — NotificationListener detects page swipe start/end.
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                onScrollStart();
              } else if (notification is ScrollEndNotification) {
                onScrollEnd();
              }
              return false;
            },
            child: PageView.builder(
              controller: pageController,
              itemCount: pageCount,
              onPageChanged: (index) => vm.goToPage(index),
              itemBuilder: (context, index) => _PageView(
                page: detail.pages[index],
              ),
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
            playerOrientation: vm.playerOrientation,
            onOrientationToggle: vm.cycleOrientation,
            autoScrollEnabled: vm.autoScrollEnabled,
            autoScrollSpeed: vm.autoScrollSpeed,
            onAutoScrollToggle: vm.toggleAutoScroll,
            onSpeedChanged: vm.updateScrollSpeedLocal,
            onSpeedChangeEnd: vm.setScrollSpeed,
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
// Bottom chrome (page indicator + orientation toggle)
// ---------------------------------------------------------------------------

/// Animated bottom bar showing the page indicator, orientation toggle,
/// auto-scroll toggle, and (when enabled) the speed slider.
class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.currentPage,
    required this.pageCount,
    required this.isVisible,
    required this.playerOrientation,
    required this.onOrientationToggle,
    required this.autoScrollEnabled,
    required this.autoScrollSpeed,
    required this.onAutoScrollToggle,
    required this.onSpeedChanged,
    required this.onSpeedChangeEnd,
  });

  final int currentPage;
  final int pageCount;
  final bool isVisible;
  final PlayerOrientation playerOrientation;
  final VoidCallback onOrientationToggle;
  final bool autoScrollEnabled;
  final double autoScrollSpeed;
  final VoidCallback onAutoScrollToggle;

  /// Updates speed in-memory on every drag frame (no DB write).
  final void Function(double) onSpeedChanged;

  /// Persists speed to storage once drag ends.
  final Future<void> Function(double) onSpeedChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: _kChromeAnimationDuration,
        opacity: isVisible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Speed slider — only shown when auto-scroll is enabled.
                  if (autoScrollEnabled)
                    _AutoScrollSpeedPanel(
                      speed: autoScrollSpeed,
                      onSpeedChanged: onSpeedChanged,
                      onSpeedChangeEnd: onSpeedChangeEnd,
                    ),
                  // Controls row: page indicator, auto-scroll toggle, orient.
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          label: 'Page ${currentPage + 1} of $pageCount',
                          child: Text(
                            '${currentPage + 1} / $pageCount',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _AutoScrollToggleButton(
                          enabled: autoScrollEnabled,
                          onTap: onAutoScrollToggle,
                        ),
                        const SizedBox(width: 8),
                        _OrientationToggleButton(
                          orientation: playerOrientation,
                          onTap: onOrientationToggle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Orientation toggle button
// ---------------------------------------------------------------------------

/// Icon button that cycles through orientation lock modes.
///
/// Shows a different icon for each [PlayerOrientation] value and calls
/// [onTap] when pressed.
class _OrientationToggleButton extends StatelessWidget {
  const _OrientationToggleButton({
    required this.orientation,
    required this.onTap,
  });

  final PlayerOrientation orientation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (orientation) {
      PlayerOrientation.auto => Icons.screen_rotation,
      PlayerOrientation.portrait => Icons.screen_lock_portrait,
      PlayerOrientation.landscape => Icons.screen_lock_landscape,
    };

    final label = switch (orientation) {
      PlayerOrientation.auto => 'Screen rotation: auto',
      PlayerOrientation.portrait => 'Screen rotation: locked portrait',
      PlayerOrientation.landscape => 'Screen rotation: locked landscape',
    };

    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        key: const Key('orientation_toggle_button'),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        tooltip: label,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-scroll toggle button
// ---------------------------------------------------------------------------

/// Icon button that toggles the auto-scroll feature on or off.
///
/// Displays a filled play icon when enabled, outlined when disabled.
class _AutoScrollToggleButton extends StatelessWidget {
  const _AutoScrollToggleButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = enabled ? 'Auto-scroll: on' : 'Auto-scroll: off';
    final icon = enabled ? Icons.play_circle : Icons.play_circle_outline;

    return Semantics(
      label: label,
      button: true,
      toggled: enabled,
      child: IconButton(
        key: const Key('auto_scroll_toggle_button'),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        tooltip: label,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auto-scroll speed panel
// ---------------------------------------------------------------------------

/// A horizontal row containing the speed label and slider for auto-scroll.
///
/// Shown in the bottom chrome when auto-scroll is enabled. The slider range
/// mirrors [kMinAutoScrollSpeed]–[kMaxAutoScrollSpeed] with [_kSpeedSliderStep]
/// divisions.
///
/// [onSpeedChanged] is called on every drag frame to update the in-memory speed
/// immediately. [onSpeedChangeEnd] is called once when the drag ends to persist
/// the final value, avoiding a DB write per drag frame.
class _AutoScrollSpeedPanel extends StatelessWidget {
  const _AutoScrollSpeedPanel({
    required this.speed,
    required this.onSpeedChanged,
    required this.onSpeedChangeEnd,
  });

  final double speed;

  /// Called on every slider drag frame — updates in-memory speed immediately.
  final void Function(double) onSpeedChanged;

  /// Called once when drag ends — persists the final speed to storage.
  final Future<void> Function(double) onSpeedChangeEnd;

  @override
  Widget build(BuildContext context) {
    final divisions =
        ((kMaxAutoScrollSpeed - kMinAutoScrollSpeed) / _kSpeedSliderStep)
            .round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              label: 'Auto-scroll speed: ${speed.toStringAsFixed(1)}×',
              slider: true,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                  valueIndicatorColor: Colors.white,
                  valueIndicatorTextStyle: const TextStyle(
                    color: Colors.black,
                  ),
                ),
                child: Slider(
                  key: const Key('auto_scroll_speed_slider'),
                  value: speed,
                  min: kMinAutoScrollSpeed,
                  max: kMaxAutoScrollSpeed,
                  divisions: divisions,
                  label: '${speed.toStringAsFixed(1)}×',
                  onChanged: onSpeedChanged,
                  onChangeEnd: (v) => onSpeedChangeEnd(v),
                ),
              ),
            ),
          ),
          Text(
            '${speed.toStringAsFixed(1)}×',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ],
      ),
    );
  }
}
