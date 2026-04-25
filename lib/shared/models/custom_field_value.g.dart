// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_field_value.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomFieldValue _$CustomFieldValueFromJson(Map<String, dynamic> json) =>
    CustomFieldValue(
      notationId: json['notation_id'] as String,
      definitionId: json['definition_id'] as String,
      valueText: json['value_text'] as String?,
      valueNumber: (json['value_number'] as num?)?.toDouble(),
      valueDate: json['value_date'] as String?,
      valueBoolean: json['value_boolean'] as bool?,
    );

Map<String, dynamic> _$CustomFieldValueToJson(CustomFieldValue instance) =>
    <String, dynamic>{
      'notation_id': instance.notationId,
      'definition_id': instance.definitionId,
      'value_text': instance.valueText,
      'value_number': instance.valueNumber,
      'value_date': instance.valueDate,
      'value_boolean': instance.valueBoolean,
    };
