// Tests for the UserPreferences domain model.
//
// Covers: default values, copyWith, equality, hashCode, JSON round-trip,
// and the AppThemeMode / ColorSchemeMode / SortOrder / ViewMode enums.

import 'package:flutter_test/flutter_test.dart';
import 'package:swaralipi/shared/models/user_preferences.dart';

void main() {
  UserPreferences makePrefs({
    String userName = 'Musician',
    AppThemeMode themeMode = AppThemeMode.system,
    ColorSchemeMode colorSchemeMode = ColorSchemeMode.catppuccin,
    String? seedColor,
    SortOrder defaultSort = SortOrder.createdAtDesc,
    ViewMode defaultView = ViewMode.list,
  }) =>
      UserPreferences(
        userName: userName,
        themeMode: themeMode,
        colorSchemeMode: colorSchemeMode,
        seedColor: seedColor,
        defaultSort: defaultSort,
        defaultView: defaultView,
      );

  group('AppThemeMode', () {
    test('has light, dark, and system variants', () {
      expect(
        AppThemeMode.values,
        containsAll([
          AppThemeMode.light,
          AppThemeMode.dark,
          AppThemeMode.system,
        ]),
      );
    });
  });

  group('ColorSchemeMode', () {
    test('has catppuccin and monet variants', () {
      expect(
        ColorSchemeMode.values,
        containsAll([
          ColorSchemeMode.catppuccin,
          ColorSchemeMode.monet,
        ]),
      );
    });
  });

  group('SortOrder', () {
    test('has all 8 sort variants', () {
      expect(SortOrder.values, hasLength(8));
      expect(
        SortOrder.values,
        containsAll([
          SortOrder.createdAtDesc,
          SortOrder.createdAtAsc,
          SortOrder.dateWrittenDesc,
          SortOrder.dateWrittenAsc,
          SortOrder.titleAsc,
          SortOrder.titleDesc,
          SortOrder.playCountDesc,
          SortOrder.lastPlayedAtDesc,
        ]),
      );
    });
  });

  group('ViewMode', () {
    test('has list variant', () {
      expect(ViewMode.values, contains(ViewMode.list));
    });
  });

  group('UserPreferences', () {
    group('construction', () {
      test('creates instance with default values', () {
        final p = makePrefs();

        expect(p.userName, 'Musician');
        expect(p.themeMode, AppThemeMode.system);
        expect(p.colorSchemeMode, ColorSchemeMode.catppuccin);
        expect(p.seedColor, isNull);
        expect(p.defaultSort, SortOrder.createdAtDesc);
        expect(p.defaultView, ViewMode.list);
      });

      test('stores provided seedColor', () {
        final p = makePrefs(seedColor: '#cba6f7');
        expect(p.seedColor, '#cba6f7');
      });
    });

    group('copyWith', () {
      test('returns equal instance when no fields changed', () {
        expect(makePrefs().copyWith(), equals(makePrefs()));
      });

      test('copies and overrides userName', () {
        final original = makePrefs();
        final copy = original.copyWith(userName: 'Roudranil');

        expect(copy.userName, 'Roudranil');
        expect(original.userName, 'Musician');
      });

      test('copies and overrides themeMode', () {
        final original = makePrefs();
        final copy = original.copyWith(themeMode: AppThemeMode.dark);

        expect(copy.themeMode, AppThemeMode.dark);
        expect(original.themeMode, AppThemeMode.system);
      });

      test('copies and overrides colorSchemeMode', () {
        final original = makePrefs();
        final copy = original.copyWith(colorSchemeMode: ColorSchemeMode.monet);

        expect(copy.colorSchemeMode, ColorSchemeMode.monet);
      });

      test('copies and overrides defaultSort', () {
        final original = makePrefs();
        final copy = original.copyWith(defaultSort: SortOrder.titleAsc);

        expect(copy.defaultSort, SortOrder.titleAsc);
        expect(original.defaultSort, SortOrder.createdAtDesc);
      });

      test('copies and sets seedColor', () {
        final original = makePrefs();
        final copy = original.copyWith(seedColor: '#89b4fa');

        expect(copy.seedColor, '#89b4fa');
        expect(original.seedColor, isNull);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        expect(makePrefs(), equals(makePrefs()));
      });

      test('different themeMode produces inequality', () {
        expect(
          makePrefs(themeMode: AppThemeMode.light),
          isNot(equals(makePrefs(themeMode: AppThemeMode.dark))),
        );
      });

      test('different sortOrder produces inequality', () {
        expect(
          makePrefs(defaultSort: SortOrder.titleAsc),
          isNot(equals(makePrefs(defaultSort: SortOrder.createdAtDesc))),
        );
      });
    });

    group('hashCode', () {
      test('equal instances have same hashCode', () {
        expect(makePrefs().hashCode, equals(makePrefs().hashCode));
      });
    });

    group('JSON serialization', () {
      test('toJson produces expected keys and values', () {
        final json = makePrefs().toJson();

        expect(json['user_name'], 'Musician');
        expect(json['theme_mode'], 'system');
        expect(json['color_scheme_mode'], 'catppuccin');
        expect(json['seed_color'], isNull);
        expect(json['default_sort'], 'created_at_desc');
        expect(json['default_view'], 'list');
      });

      test('fromJson round-trips default preferences', () {
        final original = makePrefs();
        expect(UserPreferences.fromJson(original.toJson()), equals(original));
      });

      test('fromJson round-trips all theme modes', () {
        for (final mode in AppThemeMode.values) {
          final original = makePrefs(themeMode: mode);
          expect(
            UserPreferences.fromJson(original.toJson()),
            equals(original),
          );
        }
      });

      test('fromJson round-trips all sort orders', () {
        for (final sort in SortOrder.values) {
          final original = makePrefs(defaultSort: sort);
          expect(
            UserPreferences.fromJson(original.toJson()),
            equals(original),
          );
        }
      });

      test('fromJson handles non-null seedColor', () {
        final original = makePrefs(
          colorSchemeMode: ColorSchemeMode.catppuccin,
          seedColor: '#f38ba8',
        );
        final restored = UserPreferences.fromJson(original.toJson());

        expect(restored.seedColor, '#f38ba8');
      });
    });
  });
}
