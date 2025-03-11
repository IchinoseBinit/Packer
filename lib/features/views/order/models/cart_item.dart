import 'dart:math';

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class CartItem {
  late final int id;
  late final String productId;
  late final String productName;
  late final String productImage;
  late final String measurement;
  late final int quantity;
  late final double _size;

  late final String productCompartment;
  late final String addedAt;
  late final String updatedAt;

  late int itemScanCount;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.measurement,
    required this.quantity,
    required this.productCompartment,
    required this.addedAt,
    this.itemScanCount = 0,
    required this.updatedAt,
  });

  String get size {
    // Utility function to format size
    if (_size == _size.toInt()) {
      return _size.toInt().toString();
    } else {
      return _size.toString();
    }
  }

  CartItem.fromJson(Map<String, dynamic> json) {
    // id = json['id'].toString().toInt();
    id = randomId;
    productId = json['product_id'].toString().toStringConversion();
    productName = json['product_name'].toString().toStringConversion();
    productImage = AppUrls.imageUrl +
        json['product_image'].toString().toStringConversion();
    productCompartment = json['product_compartment'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    _size = json['size'].toString().toDouble();
    quantity = json['quantity'].toString().toInt();
    addedAt = json['added_at'].toString().toStringConversion();
    updatedAt = json['updated_at'].toString().toStringConversion();
    itemScanCount = 0;
  }


  int get randomId {
    return Random().nextInt(1000);
  }

}
