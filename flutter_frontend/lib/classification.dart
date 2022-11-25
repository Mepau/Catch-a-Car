import 'package:json_annotation/json_annotation.dart';

part 'classification.g.dart';

@JsonSerializable(explicitToJson: true)
class Classification {
  double id;
  String type_of_vehicle;
  String vehicle_color;
  double inital_time_of_capture;
  double final_time_of_capture;

  Classification(
      {required this.id,
      required this.type_of_vehicle,
      required this.vehicle_color,
      required this.inital_time_of_capture,
      required this.final_time_of_capture});

  factory Classification.fromJson(Map<String, dynamic> json) =>
      _$ClassificationFromJson(json);
  Map<String, dynamic> toJson() => _$ClassificationToJson(this);
}
