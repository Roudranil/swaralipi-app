// Abstract PreferencesRepository interface.
//
// Defines the contract for reading and writing the singleton
// UserPreferences record. The concrete implementation lives in
// lib/features/settings/data/user_preferences_repository_impl.dart.
//
// This interface extends [UserPreferencesRepository] (the narrow contract
// used by TagRepositoryImpl for seeding) and adds the appearance-specific
// write methods required by AppearanceViewModel.

import 'package:swaralipi/shared/models/user_preferences.dart';
import 'package:swaralipi/shared/repositories/tag_repository.dart';

/// Full contract for reading and writing all user preferences.
///
/// Extends [UserPreferencesRepository] (seeding contract) with the four
/// targeted write methods exposed by the Appearance feature. Implementations
/// must persist changes to the `user_preferences` singleton row and guarantee
/// subsequent [getPreferences] calls reflect the update.
abstract interface class PreferencesRepository
    implements UserPreferencesRepository {
  /// Returns the current singleton [UserPreferences].
  @override
  Future<UserPreferences> getPreferences();

  /// Returns a [Stream] that emits the current [UserPreferences] and re-emits
  /// whenever any preference field is updated.
  ///
  /// Callers must ensure [getPreferences] has been called once before
  /// subscribing so the singleton row exists in the database.
  Stream<UserPreferences> watchPreferences();

  /// Persists a complete [UserPreferences] value.
  ///
  /// Parameters:
  /// - [preferences]: The new preferences to persist.
  @override
  Future<void> updatePreferences(UserPreferences preferences);

  /// Updates the `theme_mode` field to [mode].
  ///
  /// All other preference fields are left unchanged.
  ///
  /// Parameters:
  /// - [mode]: The new [AppThemeMode] to persist.
  Future<void> updateThemeMode(AppThemeMode mode);

  /// Updates the `color_scheme_mode` field to [mode].
  ///
  /// All other preference fields are left unchanged.
  ///
  /// Parameters:
  /// - [mode]: The new [ColorSchemeMode] to persist.
  Future<void> updateColorSchemeMode(ColorSchemeMode mode);

  /// Updates the `seed_color` field to [colorHex].
  ///
  /// Pass `null` to clear the seed color. All other preference fields are
  /// left unchanged.
  ///
  /// Parameters:
  /// - [colorHex]: A Catppuccin hex string (e.g. `'#f38ba8'`), or `null`.
  Future<void> updateSeedColor(String? colorHex);

  /// Updates the `player_orientation` field to [orientation].
  ///
  /// All other preference fields are left unchanged.
  ///
  /// Parameters:
  /// - [orientation]: The new [PlayerOrientation] to persist.
  Future<void> updatePlayerOrientation(PlayerOrientation orientation);

  /// Updates the `auto_scroll_speed` field to [speed].
  ///
  /// All other preference fields are left unchanged. [speed] must be in the
  /// range [0.1, 3.0]; the implementation clamps to this range.
  ///
  /// Parameters:
  /// - [speed]: The new auto-scroll speed multiplier to persist.
  Future<void> updateAutoScrollSpeed(double speed);

  /// Updates the `user_name` field to [name].
  ///
  /// All other preference fields are left unchanged.
  ///
  /// Parameters:
  /// - [name]: The new display name to persist. An empty string is allowed.
  Future<void> updateUserName(String name);

  /// Convenience method to flip the `tagsSeeded` flag.
  ///
  /// Parameters:
  /// - [value]: The new value for the tagsSeeded field.
  @override
  Future<void> updateTagsSeeded({required bool value});
}
