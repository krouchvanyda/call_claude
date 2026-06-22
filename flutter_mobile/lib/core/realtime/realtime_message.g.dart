// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'realtime_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RealtimeChartSeriesPayloadImpl _$$RealtimeChartSeriesPayloadImplFromJson(
  Map<String, dynamic> json,
) => _$RealtimeChartSeriesPayloadImpl(
  id: json['id'] as String,
  label: json['label'] as String,
  x: (json['x'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
  y: (json['y'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
);

Map<String, dynamic> _$$RealtimeChartSeriesPayloadImplToJson(
  _$RealtimeChartSeriesPayloadImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'x': instance.x,
  'y': instance.y,
};
