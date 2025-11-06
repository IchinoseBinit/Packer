import 'package:packer/controllers/extensions/string_extension.dart';

class WeeklySummary {
  late final int count;
  late final double cashPayment;
  late final double distance;
  late final List<WeeklySummaryData> orders;

  WeeklySummary({
    required this.count,
    required this.distance,
    required this.orders,
  });

  // Method to parse JSON into an OrderSummary instance
  WeeklySummary.fromJson(Map<String, dynamic> json) {
    count = json['count'].toString().toInt();
    cashPayment = json['cash_payment'].toString().toDouble();
    distance = json['distance'].toString().toDouble();
    orders =
        (json['summary'] as List).map((order) => WeeklySummaryData.fromJson(order)).toList();
  }
}


class WeeklySummaryData {
  late DateTime date;
  late int count;
  late double distance;

  WeeklySummaryData(
      {required this.date, required this.count, required this.distance});

  WeeklySummaryData.fromJson(Map<String, dynamic> json) {
    date = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
    count = json['count'].toString().toInt();
    distance = json['distance'].toString().toDouble();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date'] = date;
    data['count'] = count;
    data['distance'] = distance;
    return data;
  }
}
