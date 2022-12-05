import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_frontend/widgets/PieChart.dart';

import 'models/Classification.dart';
import 'widgets/OptionPicker.dart';
import 'models/CharData.dart';

class ResultsDataSource extends DataTableSource {
  ResultsDataSource({Key? key, required this.dataList});

  final List<Classification> dataList;
  // Generate some made-up data

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => dataList.length;
  @override
  int get selectedRowCount => 0;
  @override
  DataRow getRow(int index) {
    return DataRow(cells: [
      DataCell(Text(dataList[index].type_of_vehicle)),
      DataCell(Text(dataList[index].vehicle_color)),
      DataCell(Text(dataList[index].inital_time_of_capture.toString())),
      DataCell(Text(dataList[index].final_time_of_capture.toString())),
    ]);
  }
}

class ResultsTable extends StatelessWidget {
  const ResultsTable({Key? key, required this.resultsList}) : super(key: key);

  final ResultsDataSource resultsList;

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable(
      source: resultsList,
      columnSpacing: (MediaQuery.of(context).size.width / 20) * 0.5,
      header: const Text('Video results'),
      columns: const [
        DataColumn(
          label: Text('Type of vehicle'),
        ),
        DataColumn(
          label: Text('Vehicle color'),
        ),
        DataColumn(label: Text("Initial Time of Capture")),
        DataColumn(label: Text("Final Time of Capture")),
      ],
      //columnSpacing: 100,
      horizontalMargin: 10,
      rowsPerPage: 8,
      showCheckboxColumn: false,
    );
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  List<Classification>? results;
  final List<String> colorOptions = ["BLACK", "WHITE", "RED"];
  final List<String> typeOptions = ["SEDAN", "PICKUP", "SUV"];
  List<String> selectedColors = [];
  List<String> selectedTypes = [];
  List<ChartData>? colorPieChartData;
  List<ChartData>? typePieChartData;

  Future<Map<String, dynamic>> filterButtonPressed() async {
    Map<String, dynamic> jsonResponse = {};
    var dio = Dio();
    String colorOptionString = "colorOptions[]=";
    String colorOptionStringParam = "";
    String typeOptionString = "typeOptions[]=";
    String typeOptionStringParam = "";
    String taskId = widget.id;

    if (selectedColors.isNotEmpty) {
      for (int i = 0; i < selectedColors.length; i++) {
        if (i < selectedColors.length - 1) {
          colorOptionStringParam =
              "$colorOptionStringParam$colorOptionString${selectedColors[i]}&";
        } else {
          colorOptionStringParam =
              "$colorOptionStringParam$colorOptionString${selectedColors[i]}";
        }
      }
    }
    if (selectedTypes.isNotEmpty) {
      for (int i = 0; i < selectedTypes.length; i++) {
        if (i < selectedTypes.length - 1) {
          typeOptionStringParam =
              "$typeOptionStringParam$typeOptionString${selectedTypes[i]}&";
        } else {
          typeOptionStringParam =
              "$typeOptionStringParam$typeOptionString${selectedTypes[i]}";
        }
      }
    }
    await dio
        .get(
      "http://localhost:8000/api/v1/object_detection/Results/filter?id=$taskId&$colorOptionStringParam&$typeOptionStringParam",
    )
        .then((response) {
      List<Classification> resData =
          (json.decode(response.data)["data"] as List)
              .map((i) => Classification.fromJson(i))
              .toList();
      List<ChartData> resColorPieChartData =
          (json.decode(response.data)["colorPieChart"] as List)
              .map((i) => ChartData.fromJson(i))
              .toList();
      List<ChartData> resTypePieChartData =
          (json.decode(response.data)["typePieChart"] as List)
              .map((i) => ChartData.fromJson(i))
              .toList();
      setState(() {
        colorPieChartData = resColorPieChartData;
        typePieChartData = resTypePieChartData;
        results = resData;
      });
    });
    return jsonResponse;
  }

  @override
  void initState() {
    String taskId = widget.id;
    String url =
        'http://localhost:8000/api/v1/object_detection/Results?id=$taskId';
    print(url);
    var dio = Dio();
    dio
        .get(
      url,
    )
        .then((response) {
      //var res = jsonDecode(response.data);

      //List<Map<String, dynamic>> resResults = jsonDecode(response.data);
      List<Classification> resData =
          (json.decode(response.data)["data"] as List)
              .map((i) => Classification.fromJson(i))
              .toList();
      List<ChartData> resColorPieChartData =
          (json.decode(response.data)["colorPieChart"] as List)
              .map((i) => ChartData.fromJson(i))
              .toList();
      List<ChartData> resTypePieChartData =
          (json.decode(response.data)["typePieChart"] as List)
              .map((i) => ChartData.fromJson(i))
              .toList();
      setState(() {
        results = resData;
        colorPieChartData = resColorPieChartData;
        typePieChartData = resTypePieChartData;
      });
      results = resData;
      colorPieChartData = resColorPieChartData;
      //colorPieChartData = resColorPieChartData;

      //print(colorPieChartData[0]);
      //print(colorPieChartData[0].id);

      //List< dynamic > itemsList= List< dynamic >.from(parsedListJson.map((i) => Item.fromJson(i)));
    });

    //print(returnedResult.body);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool isScreenWide = MediaQuery.of(context).size.width >= 415;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Catch a Car'),
        ),
        body: SingleChildScrollView(
            child: (colorPieChartData != null &&
                    results != null &&
                    typePieChartData != null)
                ? Column(children: [
                    OptionsPicker(
                      optionTitle: "Vehicle Colors",
                      options: colorOptions,
                      callback: (List<String> val) {
                        setState(() {
                          selectedColors = val;
                        });
                      },
                    ),
                    OptionsPicker(
                      optionTitle: "Vehicle Types",
                      options: typeOptions,
                      callback: (List<String> val) {
                        selectedTypes = val;
                      },
                    ),
                    ElevatedButton(
                        onPressed: filterButtonPressed, child: Text("Filter")),
                    SizedBox(
                      width: double.infinity,
                      child: ResultsTable(
                        resultsList: ResultsDataSource(dataList: results!),
                      ),
                    ),
                    PieChart2(data: colorPieChartData!),
                    PieChart2(data: typePieChartData!)
                  ])
                : Center(child: CircularProgressIndicator())));
  }
}
