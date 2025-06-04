// ignore_for_file: non_constant_identifier_names


import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/order/models/user_info.dart';

class CompletedOrderDetails {
  late final int id;
  late final OrderStatusType status;
  late final double total;
  late final UserInfo user_info;
  late final String name;

  CompletedOrderDetails({
    required this.id,
    required this.status,
    required this.total,
    required this.user_info,
    // required this.customer,
  });

  CompletedOrderDetails.fromJson(Map<String, dynamic> obj) {
    final json = obj['data'];
    id = json['id'].toString().toInt();
    status = OrderStatusType.fromString(json['status'].toString().toStringConversion());
    total = json['total'].toString().toDouble();
    user_info = UserInfo.fromJson(json['user_info']);
    // customer = Info.fromJson(json['customer']);
    name = json['customer_name'].toString().toStringConversion();
  }
}

class Info {
  late final String name;
  late final String phone;

  Info({
    required this.name,
    required this.phone,
  });

  Info.fromJson(Map<String, dynamic> json)
      : name = json['name'].toString().toStringConversion(),
        phone = json['phone'].toString().toStringConversion();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
    };
  }

  @override
  String toString() {
    return name;
  }
}
