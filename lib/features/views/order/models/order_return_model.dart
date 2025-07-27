import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class OrderReturnModel {
  late final int id;
  late final int orderId;
  late final String basket;
  late final String createdAt;
  late final List<OrderItems> orderItems;

  OrderReturnModel(
      {required this.id,
      required this.orderId,
      required this.basket,
      required this.createdAt,
      required this.orderItems});

  OrderReturnModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    orderId = json['order'].toString().toInt();
    basket = json['basket'].toString().toStringConversion();
    createdAt = json['created_at'];
    // orderItems = [];
    if (json['order_items'] != null) {
      orderItems = <OrderItems>[];
      json['order_items'].forEach((v) {
        orderItems.add(OrderItems.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id.toString().toInt();
    data['order'] = orderId.toString().toInt();
    data['basket'] = basket.toString().toStringConversion();
    data['created_at'] = createdAt;
    data['order_items'] = orderItems.map((v) => v.toJson()).toList();
    return data;
  }
}

class OrderItems {
  late final int productId;
  late final String productName;
  late final String size;
  late final String measurement;
  late final String imageUrl;
  late final List<String> unitTags;
  late final String rackName;

  OrderItems(
      {required this.productId,
      required this.productName,
      required this.size,
      required this.measurement,
      required this.imageUrl,
      required this.unitTags,
      required this.rackName});

  OrderItems.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    size = json['size'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    imageUrl = AppUrls.imageUrl + json['image_url'].toString().toStringConversion();
    unitTags = json['unit_tags'].cast<String>();
    rackName = json['rack_name'].toString().toStringConversion();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId.toString().toInt();
    data['product_name'] = productName.toString().toStringConversion();
    data['size'] = size.toString().toStringConversion();
    data['measurement'] = measurement.toString().toStringConversion();
    data['image_url'] = imageUrl.toString().toStringConversion();
    data['unit_tags'] = unitTags;
    data['rack_name'] = rackName.toString().toStringConversion();
    return data;
  }
}
