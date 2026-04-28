// Abstract InstrumentRepository interface.
//
// Defines the contract for all instrument class CRUD and archive operations.
// The concrete implementation lives in
// lib/features/instruments/data/instrument_repository_impl.dart.

import 'package:swaralipi/shared/models/instrument_class.dart';

// ---------------------------------------------------------------------------
// Repository interface
// ---------------------------------------------------------------------------

/// Contract for all instrument class data operations.
///
/// Implementations translate between [InstrumentClassRow] (Drift) and
/// [InstrumentClass] (domain) at the repository boundary.
///
/// All write methods return the persisted domain model so callers never need
/// to issue a follow-up read.
abstract interface class InstrumentRepository {
  /// Returns a live stream of all active (non-archived) instrument classes
  /// ordered alphabetically by name.
  ///
  /// The stream re-emits whenever the underlying table changes.
  Stream<List<InstrumentClass>> watchActiveClasses();

  /// Creates a new instrument class with [name] and returns the persisted
  /// [InstrumentClass].
  ///
  /// Throws if [name] already exists (UNIQUE constraint violation).
  ///
  /// Parameters:
  /// - [name]: Unique human-readable class name, e.g. `'Sitar'`.
  Future<InstrumentClass> createClass(String name);

  /// Updates the name of the instrument class identified by [id] and returns
  /// the updated [InstrumentClass].
  ///
  /// Throws [InstrumentClassNotFoundException] if no class with [id] exists.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the class to update.
  /// - [name]: The new display name for the class.
  Future<InstrumentClass> updateClass(String id, String name);

  /// Archives the instrument class identified by [id] by setting
  /// `deleted_at` to the current UTC timestamp.
  ///
  /// Archived classes are hidden from active lists but retained in the
  /// database for referential integrity. Instance rows that reference this
  /// class are NOT modified. If no class with [id] exists, the call is
  /// silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the class to archive.
  Future<void> archiveClass(String id);
}

// ---------------------------------------------------------------------------
// Domain exceptions
// ---------------------------------------------------------------------------

/// Thrown by [InstrumentRepository.updateClass] when no class with the given
/// id exists.
final class InstrumentClassNotFoundException implements Exception {
  /// Creates an [InstrumentClassNotFoundException] for [id].
  ///
  /// Parameters:
  /// - [id]: The id that was not found.
  const InstrumentClassNotFoundException(this.id);

  /// The class id that was not found.
  final String id;

  @override
  String toString() =>
      'InstrumentClassNotFoundException: no class with id "$id"';
}
