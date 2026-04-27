// Abstract TagRepository interface.
//
// Defines the contract for all tag CRUD operations and seed data
// initialisation. The concrete implementation lives in
// lib/features/tags/data/tag_repository_impl.dart.
//
// Seeding policy:
//   Call [seedDefaultTagsIfNeeded] once at app startup. It checks the
//   UserPreferences.tagsSeeded flag; if false it inserts the 5 default tags
//   and sets the flag to true so subsequent launches are a no-op.

import 'package:swaralipi/shared/models/tag.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';

// ---------------------------------------------------------------------------
// Repository interface
// ---------------------------------------------------------------------------

/// Contract for all tag data operations.
///
/// Implementations translate between [TagRow] (Drift) and [Tag] (domain)
/// and enforce the seeding policy via [seedDefaultTagsIfNeeded].
///
/// All write methods return the persisted domain model so callers never need
/// to issue a follow-up read.
abstract interface class TagRepository {
  /// Returns a live stream of all tags ordered alphabetically by name.
  ///
  /// The stream re-emits whenever the underlying tags table changes.
  Stream<List<Tag>> watchAllTags();

  /// Creates a new tag with [name] and [colorHex] and returns the persisted
  /// [Tag].
  ///
  /// Throws if [name] already exists (UNIQUE constraint violation).
  ///
  /// Parameters:
  /// - [name]: Unique display name for the new tag.
  /// - [colorHex]: Catppuccin hex color string, e.g. `'#f38ba8'`.
  Future<Tag> createTag(String name, String colorHex);

  /// Updates the [name] and/or [colorHex] of the tag identified by [id] and
  /// returns the updated [Tag].
  ///
  /// Throws [TagNotFoundException] if no tag with [id] exists.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the tag to update.
  /// - [name]: New display name; omit to leave unchanged.
  /// - [colorHex]: New Catppuccin hex color string; omit to leave unchanged.
  Future<Tag> updateTag(String id, {String? name, String? colorHex});

  /// Permanently deletes the tag with [id].
  ///
  /// Associated `notation_tags` join rows cascade automatically via the FK
  /// constraint. If no tag with [id] exists the call is silently ignored.
  ///
  /// Parameters:
  /// - [id]: The UUIDv4 primary key of the tag to delete.
  Future<void> deleteTag(String id);

  /// Seeds the 5 default tags if they have not been seeded yet.
  ///
  /// Reads the `UserPreferences.tagsSeeded` flag. If `false`, inserts the
  /// default tags and sets the flag to `true`. If `true`, returns immediately
  /// without touching the database.
  ///
  /// This method is idempotent and safe to call on every app launch.
  Future<void> seedDefaultTagsIfNeeded();
}

// ---------------------------------------------------------------------------
// Preferences sub-interface (used by TagRepositoryImpl for seeding)
// ---------------------------------------------------------------------------

/// Minimal contract for reading and writing the tagsSeeded preference flag.
///
/// The full [PreferencesRepository] will implement this interface.
/// [TagRepositoryImpl] depends only on this narrow contract to avoid coupling
/// to unrelated preference fields.
abstract interface class UserPreferencesRepository {
  /// Returns the current singleton [UserPreferences].
  Future<UserPreferences> getPreferences();

  /// Persists a complete [UserPreferences] value.
  ///
  /// Parameters:
  /// - [preferences]: The new preferences to persist.
  Future<void> updatePreferences(UserPreferences preferences);

  /// Convenience method to flip the `tagsSeeded` flag.
  ///
  /// Parameters:
  /// - [value]: The new value for the tagsSeeded field.
  Future<void> updateTagsSeeded({required bool value});
}

// ---------------------------------------------------------------------------
// Domain exceptions
// ---------------------------------------------------------------------------

/// Thrown by [TagRepository.updateTag] when no tag with the given id exists.
final class TagNotFoundException implements Exception {
  /// Creates a [TagNotFoundException] for [id].
  ///
  /// Parameters:
  /// - [id]: The id that was not found.
  const TagNotFoundException(this.id);

  /// The tag id that was not found.
  final String id;

  @override
  String toString() => 'TagNotFoundException: no tag with id "$id"';
}
