/* [
    {
        "product_id": 539,
        "product_name": "Dove Shampoo Nourishing Oil Care",
        "size": "325.00",
        "measurement": "mL",
        "stock_quantity": 4,
        "rack_name": null,
        "image": "/media/src/images/product_images/dove_nourishing.jpg",
        "product_units": []
    },
    {
        "product_id": 58,
        "product_name": "Nebico Cashew Cookies",
        "size": "120.00",
        "measurement": "g",
        "stock_quantity": 25,
        "rack_name": null,
        "image": "/media/src/images/product_images/cashew-removebg-preview.png",
        "product_units": []
    }
] */

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class StockItemModel {
  final int productId;
  final String productName;
  final String size;
  final String measurement;
  final int stockQuantity;
  final String? rackName;
  final String image;
  final List<String> productUnits;

  StockItemModel({
    required this.productId,
    required this.productName,
    required this.size,
    required this.measurement,
    required this.stockQuantity,
    this.rackName,
    required this.image,
    required this.productUnits,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      productId: json['product_id'].toString().toInt(),
      productName: json['product_name'].toString().toStringConversion(),
      size: json['size'].toString().toStringConversion(),
      measurement: json['measurement'].toString().toStringConversion(),
      stockQuantity: json['stock_quantity'].toString().toInt(),
      rackName: json['rack_name'].toString().toStringConversion(),
      image: AppUrls.imageUrl + json['image'].toString().toStringConversion(),
      productUnits: json['product_units'].map((e) => e.toString().toStringConversion()).toList(),
    );
  }
}