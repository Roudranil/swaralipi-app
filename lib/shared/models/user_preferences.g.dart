// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      userName: json['user_name'] as String,
      themeMode: $enumDecode(_$AppThemeModeEnumMap, json['theme_mode']),
      colorSchemeMode:
          $enumDecode(_$ColorSchemeModeEnumMap, json['color_scheme_mode']),
      seedColor: json['seed_color'] as String?,
      defaultSort: $enumDecode(_$SortOrderEnumMap, json['default_sort']),
      defaultView: $enumDecode(_$ViewModeEnumMap, json['default_view']),
      tagsSeeded: json['tags_seeded'] as bool? ?? false,
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'user_name': instance.userName,
      'theme_mode': _$AppThemeModeEnumMap[instance.themeMode]!,
      'color_scheme_mode': _$ColorSchemeModeEnumMap[instance.colorSchemeMode]!,
      'seed_color': instance.seedColor,
      'default_sort': _$SortOrderEnumMap[instance.defaultSort]!,
      'default_view': _$ViewModeEnumMap[instance.defaultView]!,
      'tags_seeded': instance.tagsSeeded,
    };

const _$AppThemeModeEnumMap = {
  AppThemeMode.light: 'light',
  AppThemeMode.dark: 'dark',
  AppThemeMode.system: 'system',
};

const _$ColorSchemeModeEnumMap = {
  ColorSchemeMode.catppuccin: 'catppuccin',
  ColorSchemeMode.monet: 'monet',
};

const _$SortOrderEnumMap = {
  SortOrder.createdAtDesc: 'created_at_desc',
  SortOrder.createdAtAsc: 'created_at_asc',
  SortOrder.dateWrittenDesc: 'date_written_desc',
  SortOrder.dateWrittenAsc: 'date_written_asc',
  SortOrder.titleAsc: 'title_asc',
  SortOrder.titleDesc: 'title_desc',
  SortOrder.playCountDesc: 'play_count_desc',
  SortOrder.lastPlayedAtDesc: 'last_played_at_desc',
};

const _$ViewModeEnumMap = {
  ViewMode.list: 'list',
};
