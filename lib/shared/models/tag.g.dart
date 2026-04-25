// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorHex: json['color_hex'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color_hex': instance.colorHex,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
