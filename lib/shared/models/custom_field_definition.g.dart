// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_field_definition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomFieldDefinition _$CustomFieldDefinitionFromJson(
        Map<String, dynamic> json) =>
    CustomFieldDefinition(
      id: json['id'] as String,
      keyName: json['key_name'] as String,
      fieldType: $enumDecode(_$CustomFieldTypeEnumMap, json['field_type']),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$CustomFieldDefinitionToJson(
        CustomFieldDefinition instance) =>
    <String, dynamic>{
      'id': instance.id,
      'key_name': instance.keyName,
      'field_type': _$CustomFieldTypeEnumMap[instance.fieldType]!,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$CustomFieldTypeEnumMap = {
  CustomFieldType.text: 'text',
  CustomFieldType.number: 'number',
  CustomFieldType.date: 'date',
  CustomFieldType.boolean: 'boolean',
};
