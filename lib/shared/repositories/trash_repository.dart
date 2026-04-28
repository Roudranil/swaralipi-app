// Abstract TrashRepository interface.
//
// Defines the contract for all soft-delete lifecycle operations on notations.
// The concrete implementation lives in
// lib/features/trash/data/trash_repository_impl.dart.
//
// Soft-delete policy (from data-model.md §6):
//   - Notations are soft-deleted by setting deleted_at; not physically removed.
//   - All active-notation queries filter WHERE deleted_at IS NULL.
//   - Hard deletes remove the DB row AND call FileStorageService to delete the
//     notation directory from disk.
//   - Auto-purge runs at app startup: removes all rows where
//     deleted_at < now − 30 days.

import 'package:swaralipi/shared/models/notation.dart';

/// Contract for all trash lifecycle operations.
///
/// Implementations translate between DB rows and [Notation] domain models and
/// enforce the hard-delete policy (DB row + file system cleanup).
abstract interface class TrashRepository {
  /// Emits a live list of soft-deleted [Notation]s ordered by
  /// [Notation.deletedAt] descending (most-recently deleted first).
  ///
  /// The stream re-emits whenever the underlying notations table changes.
  Stream<List<Notation>> watchTrashedNotations();

  /// Restores the notation identified by [id] by clearing its [Notation.deletedAt]
  /// field.
  ///
  /// The notation reappears in the active library on the next stream emission.
  /// If no notation with [id] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to restore.
  Future<void> restoreNotation(String id);

  /// Permanently deletes the notation identified by [id] from the database
  /// and removes its directory from the file system.
  ///
  /// This is a hard delete. All pages cascade automatically via the FK
  /// constraint. If no notation with [id] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the notation to purge.
  Future<void> purgeNotation(String id);

  /// Permanently deletes all currently trashed notations and their files.
  ///
  /// Equivalent to calling [purgeNotation] for each trashed notation in one
  /// operation. Safe to call when the trash is already empty.
  Future<void> purgeAll();

  /// Deletes all notations whose [Notation.deletedAt] is older than 30 days
  /// from now.
  ///
  /// Returns the number of notations that were purged. Safe to call on every
  /// app launch — it is a no-op when no notations have expired.
  Future<int> autoPurgeExpired();
}
