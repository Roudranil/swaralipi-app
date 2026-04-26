// main.dart — Swaralipi application entry point.
//
// Initialises the AppDatabase and FileStorageService before running the UI,
// then kicks off a startup orphan-file cleanup task in the background.
//
// Orphan cleanup sequence (runs once per cold start):
//   1. AppDatabase is opened (Drift ensures the schema is up-to-date).
//   2. All image_path values are fetched from notation_pages via
//      NotationPageDao.getAllImagePaths().
//   3. FileStorageService.scanOrphans() compares disk contents to the DB set.
//   4. FileStorageService.purgeOrphans() deletes any files not in the DB.

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:swaralipi/core/database/app_database.dart';
import 'package:swaralipi/core/storage/file_storage_service.dart';

/// Application entry point.
///
/// Calls [WidgetsFlutterBinding.ensureInitialized] before any platform channel
/// work, then opens the database, and finally launches the UI. The orphan
/// cleanup runs as an unawaited background task so it does not delay first
/// frame rendering.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  final storageService = FileStorageService();

  // Fire-and-forget: orphan cleanup must not block the first frame.
  unawaited(_runOrphanCleanup(db, storageService));

  runApp(const SwaralipiApp());
}

/// Fetches all known image paths from the database then scans and purges any
/// orphaned JPEG files from the local file system.
///
/// Logs the orphan count at info level using [dart:developer] [log]. Any
/// exception is caught and logged so that a cleanup failure never crashes the
/// app.
///
/// Parameters:
/// - [db]: The open [AppDatabase] instance.
/// - [storageService]: The [FileStorageService] used to scan and purge files.
Future<void> _runOrphanCleanup(
  AppDatabase db,
  FileStorageService storageService,
) async {
  try {
    final knownPaths = await db.notationPageDao.getAllImagePaths();
    final orphans = await storageService.scanOrphans(knownPaths);

    log(
      'Startup orphan cleanup: ${orphans.length} orphan(s) found',
      name: 'OrphanCleanup',
    );

    if (orphans.isNotEmpty) {
      await storageService.purgeOrphans(orphans);
      log(
        'Startup orphan cleanup: purge complete',
        name: 'OrphanCleanup',
      );
    }
  } on Exception catch (e, st) {
    log(
      'Startup orphan cleanup failed: $e',
      name: 'OrphanCleanup',
      error: e,
      stackTrace: st,
    );
  }
}

/// Root widget for the Swaralipi application.
class SwaralipiApp extends StatelessWidget {
  /// Creates the [SwaralipiApp].
  const SwaralipiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const _PlaceholderHome(),
    );
  }
}

/// Placeholder home screen used until the real navigation shell is implemented.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Swaralipi'),
      ),
      body: const Center(
        child: Text('App under construction'),
      ),
    );
  }
}
