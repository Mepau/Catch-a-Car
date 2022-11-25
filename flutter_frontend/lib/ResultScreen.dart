import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/material.dart';

import 'Classification.dart';
import 'OptionPicker.dart';

class ResultsTable extends StatelessWidget {
  const ResultsTable({Key? key, required this.resultsList}) : super(key: key);

  final List<Classification> resultsList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Text('Type of vehicle'),
          ),
          DataColumn(
            label: Text('Vehicle color'),
          ),
          DataColumn(label: Text("Initial Time of Capture")),
          DataColumn(label: Text("Final Time of Capture")),
        ],
        rows: List<DataRow>.generate(
          resultsList.length,
          (int index) => DataRow(
            color: MaterialStateProperty.resolveWith<Color?>(
                (Set<MaterialState> states) {
              // All rows will have the same selected color.
              if (states.contains(MaterialState.selected)) {
                return Theme.of(context).colorScheme.primary.withOpacity(0.08);
              }
              // Even rows will have a grey color.
              if (index.isEven) {
                return Colors.grey.withOpacity(0.3);
              }
              return null; // Use default value for other states and odd rows.
            }),
            cells: <DataCell>[
              DataCell(Text(resultsList[index].type_of_vehicle)),
              DataCell(Text(resultsList[index].vehicle_color)),
              DataCell(
                  Text(resultsList[index].inital_time_of_capture.toString())),
              DataCell(
                  Text(resultsList[index].final_time_of_capture.toString())),
            ],
          ),
        ),
      ),
    );
  }
}

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

class ResultsTable2 extends StatelessWidget {
  const ResultsTable2({Key? key, required this.resultsList}) : super(key: key);

  final ResultsDataSource resultsList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: PaginatedDataTable(
        source: resultsList,
        header: const Text('My Products'),
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
        columnSpacing: 100,
        horizontalMargin: 10,
        rowsPerPage: 8,
        showCheckboxColumn: false,
      ),
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
  List<Classification> results = [];

  @override
  void initState() {
    super.initState();

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

      List<Classification> resResults = (json.decode(response.data) as List)
          .map((i) => Classification.fromJson(i))
          .toList();
      //List<Map<String, dynamic>> resResults = jsonDecode(response.data);

      setState(() {
        results = resResults;
      });

      //List< dynamic > itemsList= List< dynamic >.from(parsedListJson.map((i) => Item.fromJson(i)));
    });

    //print(returnedResult.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Sample Code'),
        ),
        body: Column(children: [
          Text("Hello"),
          GenresPicker(
            callback: (List<dynamic> val) {},
          ),
          ResultsTable2(
            resultsList: ResultsDataSource(dataList: results),
          )
        ]));
  }
}
