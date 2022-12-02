class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final double y;

  ChartData.fromJson(Map<String, dynamic> json)
      : x = json['id'],
        y = json['amount'].toDouble();
}
