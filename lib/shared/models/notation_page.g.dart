// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notation_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotationPage _$NotationPageFromJson(Map<String, dynamic> json) => NotationPage(
      id: json['id'] as String,
      notationId: json['notation_id'] as String,
      pageOrder: (json['page_order'] as num).toInt(),
      imagePath: json['image_path'] as String,
      renderParams: json['render_params'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$NotationPageToJson(NotationPage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'notation_id': instance.notationId,
      'page_order': instance.pageOrder,
      'image_path': instance.imagePath,
      'render_params': instance.renderParams,
      'created_at': instance.createdAt,
    };
