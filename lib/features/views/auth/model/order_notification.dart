import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/enum/order_status_type.dart';

class OrderNotification {
  late String orderId;
  late String customerName;
  late final OrderStatusType status;

  OrderNotification.fromJson(Map obj) {
    orderId = (obj["order_id"] ?? obj["id"]).toString().toStringConversion();
    customerName = obj["customer_name"] ??
        obj["customer_info"]['name'].toString().toStringConversion();
    status = StatusTypeExtension.fromString(
        obj['status'].toString().toStringConversion());
  }
}
