
import 'package:packer/controllers/extensions/string_extension.dart';

class UnsettledOrders {
  UnsettledOrders({
    required this.summary,
    required this.data,
  });
  late final Summary summary;
  late final List<Data> data;

  UnsettledOrders.fromJson(Map<String, dynamic> json) {
    summary = Summary.fromJson(json['summary']);
    data = List.from(json['data']).map((e) => Data.fromJson(e)).toList();
  }
}

class Summary {
  Summary({
    required this.orderCount,
    required this.totalAmount,
  });
  late final int orderCount;
  late final double totalAmount;
  late final double totalCommission;

  Summary.fromJson(Map<String, dynamic> json) {
    orderCount = json['order_count'].toString().toInt();
    totalAmount = json['total_amount'].toString().toDouble();
    totalCommission = json['total_commission'].toString().toDouble();
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['order_count'] = orderCount;
    data['total_amount'] = totalAmount;
    return data;
  }
}

class Data {
  Data({
    required this.id,
    required this.total,
    required this.completedDateTime,
  });
  late final int id;
  late final String name;
  late final double total;
  late final double commission;
  late final String completedDateTime;


  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    name = json['name'].toString().toStringConversion();
    total = json['total'].toString().toDouble();
    commission = json['commission'].toString().toDouble();
    completedDateTime =
        json['completed_timestamp'].toString().toStringConversion();
  }
}
