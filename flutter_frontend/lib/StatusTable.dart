import 'package:flutter/material.dart';
import 'package:flutter_frontend/ResultScreen.dart';
import 'package:go_router/go_router.dart';

class PathButton extends StatelessWidget {
  const PathButton({Key? key, required this.id}) : super(key: key);

  final String id;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.all(16.0),
        textStyle: const TextStyle(fontSize: 20),
      ),
      onPressed: () => {
        //context.go("/Results/$id")
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultScreen(id: id),
          ),
        )
      },
      child: const Text('Gradient'),
    );
  }
}

class StatusTable extends StatelessWidget {
  const StatusTable({Key? key, required this.statusList}) : super(key: key);

  final List<Map<String, dynamic>> statusList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DataTable(
        columns: const <DataColumn>[
          DataColumn(
            label: Text('id'),
          ),
          DataColumn(
            label: Text('Status'),
          ),
          DataColumn(
            label: Text('Date'),
          ),
          DataColumn(
            label: Text('WTF'),
          ),
        ],
        rows: List<DataRow>.generate(
          statusList.length,
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
              DataCell(Text(statusList[index]["id"])),
              DataCell(Text(statusList[index]["status"].toString())),
              DataCell(Text(DateTime.parse(statusList[index]["received_time"])
                  .toString())),
              DataCell(PathButton(id: statusList[index]["id"])),
            ],
          ),
        ),
      ),
    );
  }
}
