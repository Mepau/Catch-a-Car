import 'package:flutter/material.dart';

import '../models/CharData.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class TimeSeriesChart extends StatelessWidget {
  const TimeSeriesChart({super.key, required this.data});
  final List<ChartData> data;

  @override
  Widget build(BuildContext context) {
    return Container(
        child: SfCartesianChart(
            primaryXAxis: CategoryAxis(),
            // Chart title
            title: ChartTitle(text: '0.5 ms cars'),
            // Enable legend
            legend: Legend(isVisible: true),
            // Enable tooltip
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <LineSeries<ChartData, String>>[
          LineSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              // Enable data label
              dataLabelSettings: DataLabelSettings(isVisible: true))
        ]));
  }
}
