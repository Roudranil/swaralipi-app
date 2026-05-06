// app.dart — root widget and GoRouter configuration for Swaralipi.
//
// [SwaralipiApp] is the single entry point used by both [main.dart] (production)
// and integration tests ([SwaralipiApp.forTesting]).  It wires:
//   • The full GoRouter route tree (all settings sub-routes)
//   • Dependency injection: repositories created once, passed down as
//     ChangeNotifierProvider at each route builder
//
// Route tree:
//   /                        → LibraryScreen
//   /settings                → SettingsScreen
//   /settings/tags           → TagsScreen
//   /settings/instruments    → InstrumentClassesScreen
//   /settings/trash          → TrashScreen
//   /settings/appearance     → AppearanceScreen
//   /settings/custom-fields  → CustomFieldsScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';
import 'package:swaralipi/features/custom_fields/data/custom_field_repository_impl.dart';
import 'package:swaralipi/features/custom_fields/screens/custom_fields_screen.dart';
import 'package:swaralipi/features/custom_fields/viewmodels/custom_fields_view_model.dart';
import 'package:swaralipi/features/instruments/data/instrument_repository_impl.dart';
import 'package:swaralipi/features/instruments/screens/instrument_classes_screen.dart';
import 'package:swaralipi/features/instruments/viewmodels/instrument_classes_view_model.dart';
import 'package:swaralipi/features/library/screens/library_screen.dart';
import 'package:swaralipi/features/library/viewmodels/library_view_model.dart';
import 'package:swaralipi/features/settings/data/user_preferences_repository_impl.dart';
import 'package:swaralipi/features/settings/screens/appearance_screen.dart';
import 'package:swaralipi/features/settings/screens/settings_screen.dart';
import 'package:swaralipi/features/settings/viewmodels/appearance_view_model.dart';
import 'package:swaralipi/features/tags/data/tag_repository_impl.dart';
import 'package:swaralipi/features/tags/screens/tags_screen.dart';
import 'package:swaralipi/features/tags/viewmodels/tags_view_model.dart';
import 'package:swaralipi/features/trash/data/trash_repository_impl.dart';
import 'package:swaralipi/features/trash/screens/trash_screen.dart';
import 'package:swaralipi/features/trash/viewmodels/trash_view_model.dart';
import 'package:swaralipi/shared/repositories/custom_field_repository.dart';
import 'package:swaralipi/shared/repositories/instrument_repository.dart';
import 'package:swaralipi/shared/repositories/notation_repository.dart';
import 'package:swaralipi/shared/repositories/preferences_repository.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';
import 'package:swaralipi/shared/repositories/trash_repository.dart';
import 'package:swaralipi/features/capture/data/notation_repository_impl.dart';

// ---------------------------------------------------------------------------
// SwaralipiApp
// ---------------------------------------------------------------------------

/// Root widget for the Swaralipi application.
///
/// In production, constructed with no arguments — repositories are created
/// internally from [AppDatabase] and [FileStorageService].
///
/// In tests, use [SwaralipiApp.forTesting] to inject fake repositories and
/// control [initialLocation].
class SwaralipiApp extends StatefulWidget {
  /// Creates the production [SwaralipiApp].
  ///
  /// Builds all real repositories from [AppDatabase] and
  /// [FileStorageService] opened via platform channels.
  const SwaralipiApp({super.key})
      : _initialLocation = '/',
        _tagRepository = null,
        _trashRepository = null,
        _instrumentRepository = null,
        _customFieldRepository = null,
        _preferencesRepository = null,
        _notationRepository = null,
        _forTesting = false;

  /// Creates a [SwaralipiApp] with injected repositories for integration tests.
  ///
  /// Parameters:
  /// - [initialLocation]: The route the router starts at. Defaults to `'/'`.
  /// - [tagRepository]: Fake [TagRepository] for testing.
  /// - [trashRepository]: Fake [TrashRepository] for testing.
  /// - [instrumentRepository]: Fake [InstrumentRepository] for testing.
  /// - [customFieldRepository]: Fake [CustomFieldRepository] for testing.
  /// - [preferencesRepository]: Fake [PreferencesRepository] for testing.
  /// - [notationRepository]: Fake [NotationRepository] for testing.
  const SwaralipiApp.forTesting({
    super.key,
    String initialLocation = '/',
    required TagRepository tagRepository,
    required TrashRepository trashRepository,
    required InstrumentRepository instrumentRepository,
    required CustomFieldRepository customFieldRepository,
    required PreferencesRepository preferencesRepository,
    NotationRepository? notationRepository,
  })  : _initialLocation = initialLocation,
        _tagRepository = tagRepository,
        _trashRepository = trashRepository,
        _instrumentRepository = instrumentRepository,
        _customFieldRepository = customFieldRepository,
        _preferencesRepository = preferencesRepository,
        _notationRepository = notationRepository,
        _forTesting = true;

  final String _initialLocation;
  final TagRepository? _tagRepository;
  final TrashRepository? _trashRepository;
  final InstrumentRepository? _instrumentRepository;
  final CustomFieldRepository? _customFieldRepository;
  final PreferencesRepository? _preferencesRepository;
  final NotationRepository? _notationRepository;
  final bool _forTesting;

  @override
  State<SwaralipiApp> createState() => _SwaralipiAppState();
}

class _SwaralipiAppState extends State<SwaralipiApp> {
  late final AppDatabase? _db;
  late final FileStorageService? _storageService;
  late final TagRepository _tagRepository;
  late final TrashRepository _trashRepository;
  late final InstrumentRepository _instrumentRepository;
  late final CustomFieldRepository _customFieldRepository;
  late final PreferencesRepository _preferencesRepository;
  late final NotationRepository? _notationRepository;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _initDependencies();
    _router = _buildRouter();
  }

  void _initDependencies() {
    if (widget._forTesting) {
      _db = null;
      _storageService = null;
      _tagRepository = widget._tagRepository!;
      _trashRepository = widget._trashRepository!;
      _instrumentRepository = widget._instrumentRepository!;
      _customFieldRepository = widget._customFieldRepository!;
      _preferencesRepository = widget._preferencesRepository!;
      _notationRepository = widget._notationRepository;
    } else {
      final db = AppDatabase();
      final storageService = FileStorageService();
      _db = db;
      _storageService = storageService;

      final prefsRepo = UserPreferencesRepositoryImpl(db.userPreferencesDao);
      _preferencesRepository = prefsRepo;
      _tagRepository = TagRepositoryImpl(db.tagDao, prefsRepo);
      _trashRepository = TrashRepositoryImpl(db.notationDao, storageService);
      _instrumentRepository = InstrumentRepositoryImpl(db.instrumentDao);
      _customFieldRepository = CustomFieldRepositoryImpl(db.customFieldDao);
      _notationRepository = NotationRepositoryImpl(
        db.notationDao,
        db.notationPageDao,
        db.notationTagDao,
        db.customFieldDao,
      );
    }
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: widget._initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            final notationRepo = _notationRepository;
            if (notationRepo == null) {
              // Notation repository not provided — render empty placeholder.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return ChangeNotifierProvider<LibraryViewModel>(
              create: (_) => LibraryViewModel(
                notationRepo,
                _trashRepository,
                tagRepository: _tagRepository,
              )..init(),
              child: LibraryScreen(
                notationRepository: notationRepo,
                tagRepository: _tagRepository,
                instrumentRepository: _instrumentRepository,
                customFieldRepository: _customFieldRepository,
                fileStorageService: _storageService,
                onNotationTap: (id) => context.go('/notation/$id'),
              ),
            );
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'tags',
              builder: (context, state) =>
                  ChangeNotifierProvider<TagsViewModel>(
                create: (_) => TagsViewModel(_tagRepository)..init(),
                child: const TagsScreen(),
              ),
            ),
            GoRoute(
              path: 'instruments',
              builder: (context, state) =>
                  ChangeNotifierProvider<InstrumentClassesViewModel>(
                create: (_) =>
                    InstrumentClassesViewModel(_instrumentRepository)..init(),
                child: const InstrumentClassesScreen(),
              ),
            ),
            GoRoute(
              path: 'trash',
              builder: (context, state) =>
                  ChangeNotifierProvider<TrashViewModel>(
                create: (_) => TrashViewModel(_trashRepository)..init(),
                child: const TrashScreen(),
              ),
            ),
            GoRoute(
              path: 'appearance',
              builder: (context, state) =>
                  ChangeNotifierProvider<AppearanceViewModel>(
                create: (_) =>
                    AppearanceViewModel(_preferencesRepository)..init(),
                child: const AppearanceScreen(),
              ),
            ),
            GoRoute(
              path: 'custom-fields',
              builder: (context, state) =>
                  ChangeNotifierProvider<CustomFieldsViewModel>(
                create: (_) =>
                    CustomFieldsViewModel(_customFieldRepository)..init(),
                child: const CustomFieldsScreen(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Swaralipi',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
  }
}
