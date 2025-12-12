import 'dart:developer';

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class ProductModel {
  late int id;
  late int productId;
  late String productName;
  late String imageUrl;
  late int quantity;
  int? mainStoreStock; // nullable, not late
  late String size;
  late String measurement;
  late String rackName;
  late int scannedCount;

  // fromJson constructor
  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    mainStoreStock = json['main_store_stock']?.toString().toInt();
    imageUrl =
        "${AppUrls.imageUrl}${json['product_image'].toString().toStringConversion()}?w=400&h=400&q=80";
    quantity = json['quantity'].toString().toInt();
    size = json['size'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    scannedCount = 0;
  }

  // toJson method (safe and clean)
  Map<String, dynamic> toJson() {
    final effectiveQuantity =
        (mainStoreStock != null && quantity > mainStoreStock!)
            ? mainStoreStock!
            : quantity;
    log('Effective Quantity: $effectiveQuantity');

    final data = {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': imageUrl,
      'quantity': effectiveQuantity,
      'size': size,
      'measurement': measurement,
      'rack_name': rackName,
    };

    if (mainStoreStock != null) {
      data['main_store_stock'] = mainStoreStock!;
    }

    return data;
  }
}
