// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'instrument_instance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstrumentInstance _$InstrumentInstanceFromJson(Map<String, dynamic> json) =>
    InstrumentInstance(
      id: json['id'] as String,
      classId: json['class_id'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      colorHex: json['color_hex'] as String,
      priceInr: (json['price_inr'] as num?)?.toInt(),
      photoPath: json['photo_path'] as String?,
      notes: json['notes'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      deletedAt: json['deleted_at'] as String?,
    );

Map<String, dynamic> _$InstrumentInstanceToJson(InstrumentInstance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'class_id': instance.classId,
      'brand': instance.brand,
      'model': instance.model,
      'color_hex': instance.colorHex,
      'price_inr': instance.priceInr,
      'photo_path': instance.photoPath,
      'notes': instance.notes,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'deleted_at': instance.deletedAt,
    };
