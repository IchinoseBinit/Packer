import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/order/models/cart_item.dart';
import 'package:packer/features/views/order/models/customer_info.dart';
import 'package:packer/features/views/order/models/user_info.dart';

class OrderDetailsFetch {
  final int id;
  final OrderStatusType status;
  final String? additionalInfo;
  final double total;
  final List<CartItem> cartItems;
  final UserInfo userInfo;
  final CustomerInfo customerInfo;
  final String? createdTimestamp;
  final String? acknowledgedTimestamp;
  final String? pickedTimestamp;
  final String? completedTimestamp;
  final String? cancelledTimestamp;

  OrderDetailsFetch({
    required this.id,
    required this.status,
    required this.additionalInfo,
    required this.total,
    required this.cartItems,
    required this.userInfo,
    required this.customerInfo,
    this.createdTimestamp,
    this.acknowledgedTimestamp,
    this.pickedTimestamp,
    this.completedTimestamp,
    this.cancelledTimestamp,
  });

  factory OrderDetailsFetch.fromJson(Map<String, dynamic> json) {
    return OrderDetailsFetch(
      id: json['id'].toString().toInt(),
      status: StatusTypeExtension.fromString(
          json['status'].toString().toStringConversion()),
      additionalInfo: json['additional_info'].toString().toStringConversion(),
      total: json['total'].toString().toDouble(),
      cartItems: (json['cart_items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      userInfo: UserInfo.fromJson(json['user_info']),
      customerInfo: CustomerInfo.fromJson(json['customer_info']),
      createdTimestamp: json['created_timestamp'],
      acknowledgedTimestamp: json['acknowledged_timestamp'],
      pickedTimestamp: json['picked_timestamp'],
      completedTimestamp: json['completed_timestamp'],
      cancelledTimestamp: json['cancelled_timestamp'],
    );
  }
}
