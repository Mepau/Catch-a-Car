// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Classification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Classification _$ClassificationFromJson(Map<String, dynamic> json) {
  List vehicle_type = json["type_of_vehicle"].split("_");
  return Classification(
    id: (json['id'] as num).toDouble(),
    type_of_vehicle: vehicle_type[0] as String,
    vehicle_color: vehicle_type[1] as String,
    inital_time_of_capture: (json['inital_time_of_capture'] as num).toDouble(),
    final_time_of_capture: (json['final_time_of_capture'] as num).toDouble(),
  );
}

Map<String, dynamic> _$ClassificationToJson(Classification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type_of_vehicle': instance.type_of_vehicle,
      'vehicle_color': instance.vehicle_color,
      'inital_time_of_capture': instance.inital_time_of_capture,
      'final_time_of_capture': instance.final_time_of_capture,
    };
