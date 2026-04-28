// Abstract InstrumentRepository interface.
//
// Defines the contract for all instrument class and instance CRUD and archive
// operations. The concrete implementation lives in
// lib/features/instruments/data/instrument_repository_impl.dart.

import 'package:swaralipi/shared/models/instrument_class.dart';
import 'package:swaralipi/shared/models/instrument_instance.dart';

// ---------------------------------------------------------------------------
// Repository interface
// ---------------------------------------------------------------------------

/// Contract for all instrument class and instance data operations.
///
/// Implementations translate between Drift row types and domain models at the
/// repository boundary. All write methods return the persisted domain model.
abstract interface class InstrumentRepository {
  // -------------------------------------------------------------------------
  // Instrument class operations
  // -------------------------------------------------------------------------

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

  // -------------------------------------------------------------------------
  // Instrument instance operations
  // -------------------------------------------------------------------------

  /// Returns a live stream of all active (non-archived) instances for the
  /// given [classId], ordered by creation time ascending.
  ///
  /// The stream re-emits whenever the underlying table changes.
  ///
  /// Parameters:
  /// - [classId]: The UUIDv4 primary key of the owning class.
  Stream<List<InstrumentInstance>> watchActiveInstancesForClass(String classId);

  /// Creates a new instrument instance under [classId] and returns the
  /// persisted [InstrumentInstance].
  ///
  /// Parameters:
  /// - [classId]: The UUIDv4 of the owning class.
  /// - [colorHex]: Catppuccin hex string for UI display.
  /// - [brand]: Optional brand name.
  /// - [model]: Optional model name.
  /// - [priceInr]: Optional purchase price in INR.
  /// - [photoPath]: Relative path of the instrument photo; nullable.
  /// - [notes]: Free-form notes. Defaults to empty string.
  Future<InstrumentInstance> createInstance(
    String classId, {
    required String colorHex,
    String? brand,
    String? model,
    int? priceInr,
    String? photoPath,
    String notes = '',
  });

  /// Updates fields of the instance identified by [id] and returns the
  /// updated [InstrumentInstance].
  ///
  /// Only non-null arguments are applied; omitted arguments are preserved.
  ///
  /// Throws [InstrumentInstanceNotFoundException] if no instance with [id]
  /// exists.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the instance to update.
  /// - [brand]: New brand name.
  /// - [model]: New model name.
  /// - [colorHex]: New Catppuccin hex color.
  /// - [priceInr]: New price in INR.
  /// - [photoPath]: New relative photo path.
  /// - [notes]: New free-form notes.
  Future<InstrumentInstance> updateInstance(
    String id, {
    String? brand,
    String? model,
    String? colorHex,
    int? priceInr,
    String? photoPath,
    String? notes,
  });

  /// Archives the instance identified by [id] by setting `deleted_at` to the
  /// current UTC timestamp.
  ///
  /// Archived instances are hidden from active lists but retained in the
  /// database so existing notation associations remain valid. If no instance
  /// with [id] exists, the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the instance to archive.
  Future<void> archiveInstance(String id);
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

/// Thrown by [InstrumentRepository.updateInstance] when no instance with the
/// given id exists.
final class InstrumentInstanceNotFoundException implements Exception {
  /// Creates an [InstrumentInstanceNotFoundException] for [id].
  ///
  /// Parameters:
  /// - [id]: The id that was not found.
  const InstrumentInstanceNotFoundException(this.id);

  /// The instance id that was not found.
  final String id;

  @override
  String toString() =>
      'InstrumentInstanceNotFoundException: no instance with id "$id"';
}
