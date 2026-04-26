// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'render_params.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CropRect _$CropRectFromJson(Map<String, dynamic> json) => CropRect(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
    );

Map<String, dynamic> _$CropRectToJson(CropRect instance) => <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'right': instance.right,
      'bottom': instance.bottom,
    };

RenderParams _$RenderParamsFromJson(Map<String, dynamic> json) => RenderParams(
      filter: $enumDecodeNullable(_$NotationFilterEnumMap, json['filter']) ??
          NotationFilter.none,
      rotationDegrees: (json['rotation_degrees'] as num?)?.toInt() ?? 0,
      cropRect: json['crop_rect'] == null
          ? null
          : CropRect.fromJson(json['crop_rect'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RenderParamsToJson(RenderParams instance) =>
    <String, dynamic>{
      'filter': _$NotationFilterEnumMap[instance.filter]!,
      'rotation_degrees': instance.rotationDegrees,
      'crop_rect': instance.cropRect,
    };

const _$NotationFilterEnumMap = {
  NotationFilter.none: 'none',
  NotationFilter.grayscale: 'grayscale',
  NotationFilter.blackAndWhite: 'black_and_white',
  NotationFilter.tintWarm: 'tint_warm',
  NotationFilter.tintCool: 'tint_cool',
};
