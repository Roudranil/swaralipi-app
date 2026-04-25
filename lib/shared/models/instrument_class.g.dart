// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument_class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstrumentClass _$InstrumentClassFromJson(Map<String, dynamic> json) =>
    InstrumentClass(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$InstrumentClassToJson(InstrumentClass instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
