import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';

class LowStockModel {
  late int storeId;
  late String storeName;
  late List<ProductModel> products;

  LowStockModel({
    this.storeId = 0,
    this.storeName = '',
    this.products = const [],
  });

  // fromJson
  LowStockModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'].toString().toInt();
    storeName = json['store_name'].toString().toStringConversion();
    if (json['products'] != null) {
      products = <ProductModel>[];
      json['products'].forEach((v) {
        products.add(ProductModel.fromJson(v));
      });
    }
  }
}