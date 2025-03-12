// import 'package:galli_vector_package/galli_vector_package.dart';

import 'package:packer/features/views/order/models/cart_item.dart';
import 'package:packer/features/views/order/models/user_info.dart';

import '../../../../controllers/extensions/string_extension.dart';

class OrderPickedDetails {
  late final int id;
  late final String status;
  late final String additionalInfo;
  late final double total;
  late final UserInfo userInfo;
  late final List<CartItem> cartItems;
  late final Info customer;

  OrderPickedDetails({
    required this.id,
    required this.status,
    required this.additionalInfo,
    required this.total,
    required this.userInfo,
    required this.cartItems,
    required this.customer,
  });

  OrderPickedDetails.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    id = data['id'].toString().toInt();
    status = data['status'].toString().toStringConversion();
    additionalInfo = data['additional_info'].toString().toStringConversion();
    total = data['total'].toString().toDouble();
    userInfo = UserInfo.fromJson(data['user_info']);
    customer = Info.fromJson(data['customer_info']);
    cartItems = List<CartItem>.from(
        data['cart_items'].map((item) => CartItem.fromJson(item)));
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
        phone = json['phone_number'].toString().toStringConversion();

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
