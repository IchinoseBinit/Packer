import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class StockItemModel {
  final int productId;
  final String productName;
  final String size;
  final String measurement;
  final int stockQuantity;
  final int plannedQuantity;
  final String rackName;
  final String image;
  final List<String> productUnits;

  StockItemModel({
    required this.productId,
    required this.productName,
    required this.size,
    required this.measurement,
    required this.stockQuantity,
    required this.plannedQuantity,
    required this.rackName,
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
      plannedQuantity: json['planned_quantity'].toString().toInt(),
      rackName: json['rack_name'].toString().toStringConversion(),
      image: AppUrls.imageUrl + json['image'].toString().toStringConversion(),
      productUnits: List<String>.from(json['product_units']),

    );
  }
}