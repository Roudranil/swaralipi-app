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

  /// Convenience method to flip the `tagsSeeded` flag.
  ///
  /// Parameters:
  /// - [value]: The new value for the tagsSeeded field.
  @override
  Future<void> updateTagsSeeded({required bool value});
}
