import 'package:packer/controllers/extensions/string_extension.dart';

class DailySummary {
  late final int count;
  late final double sum;
  late final double cashPayment;
  late final double distance;
  late final List<DailyOrderSummary> orders;

  DailySummary({
    required this.count,
    required this.sum,
    required this.distance,
    required this.orders,
  });

  // Method to parse JSON into an OrderSummary instance
  DailySummary.fromJson(Map<String, dynamic> json) {
    count = json['count'].toString().toInt();
    sum = json['sum'].toString().toDouble();
    cashPayment = json['total_cash_payment'].toString().toDouble();
    distance = json['distance'].toString().toDouble();
    orders =
        (json['orders'] as List).map((order) => DailyOrderSummary.fromJson(order)).toList();
  }
}

class DailyOrderSummary {
  late final int id;
  late final double total;
  late final double distance;
  late final String paymentType;
  late final DateTime? settlementDate;

  DailyOrderSummary({
    required this.id,
    required this.total,
    required this.distance,
    required this.paymentType,
    required this.settlementDate,
  });

  // Method to parse JSON into an Order instance
  DailyOrderSummary.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    total = json['total'].toString().toDouble();
    distance = json['distance'].toString().toDouble();
    paymentType = json['payment_type'].toString().toStringConversion();
    settlementDate = json['settlement_date'] != null ? DateTime.tryParse(json['settlement_date']) : null;
  }
}
