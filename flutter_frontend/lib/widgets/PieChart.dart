import 'package:flutter/material.dart';

import '../models/CharData.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class PieChart2 extends StatelessWidget {
  const PieChart2({super.key, required this.data});
  final List<ChartData> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SfCircularChart(
          tooltipBehavior: TooltipBehavior(enable: true),
          legend: Legend(
              isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
          series: <CircularSeries>[
            // Renders doughnut chart

            DoughnutSeries<ChartData, String>(
                dataSource: data,
                //pointColorMapper:(_ChartData data,  _) => data.color,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                dataLabelSettings: DataLabelSettings(isVisible: true))
          ]),
    );
  }
}
