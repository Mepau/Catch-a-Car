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

  /*
  Classification.fromJson(Map<String, dynamic> json){

    List vehicle_type = json["type_of_vehicle"].split("_");
    return Classification(
      id = json["id"],
      type_of_vehicle = vehicle_type[0] as String,
      vehicle_color: vehicle_type[1] as String,
      inital_time_of_capture: json["inital_time_of_capture"],
      final_time_of_capture: json["final_time_of_capture"]

    );
    
  }*/

  Classification.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        type_of_vehicle = json["type_of_vehicle"].split("_")[0],
        vehicle_color = json["type_of_vehicle"].split("_")[1],
        inital_time_of_capture = json["inital_time_of_capture"].toDouble(),
        final_time_of_capture = json["final_time_of_capture"].toDouble();
}
