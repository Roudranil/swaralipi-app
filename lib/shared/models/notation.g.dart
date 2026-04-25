// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notation _$NotationFromJson(Map<String, dynamic> json) => Notation(
      id: json['id'] as String,
      title: json['title'] as String,
      artists:
          (json['artists'] as List<dynamic>).map((e) => e as String).toList(),
      dateWritten: json['date_written'] as String?,
      timeSig: json['time_sig'] as String?,
      keySig: json['key_sig'] as String?,
      languages:
          (json['languages'] as List<dynamic>).map((e) => e as String).toList(),
      notes: json['notes'] as String,
      playCount: (json['play_count'] as num).toInt(),
      lastPlayedAt: json['last_played_at'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );

Map<String, dynamic> _$NotationToJson(Notation instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artists': instance.artists,
      'date_written': instance.dateWritten,
      'time_sig': instance.timeSig,
      'key_sig': instance.keySig,
      'languages': instance.languages,
      'notes': instance.notes,
      'play_count': instance.playCount,
      'last_played_at': instance.lastPlayedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'deleted_at': instance.deletedAt,
    };
