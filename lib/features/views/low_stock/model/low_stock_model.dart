import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';

class LowStockModel {
  late int storeId;
  late String storeName;
  late List<ProductModel> products;
  late int qty;

  LowStockModel({
    this.storeId = 0,
    this.storeName = '',
    this.products = const [],
    this.qty = 0,
  });

  // fromJson
  LowStockModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'].toString().toInt();
    storeName = json['store_name'].toString().toStringConversion();
    qty = 0;
    if (json['products'] != null) {
      products = <ProductModel>[];
      json['products'].forEach((v) {
        products.add(ProductModel.fromJson(v));
      });
    }
  }

  // copyWith
  LowStockModel copyWith({
    int? storeId,
    String? storeName,
    List<ProductModel>? products,
    int? qty,
  }) {
    return LowStockModel(
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      products: products ?? this.products,
      qty: qty ?? this.qty,
    );
  }
}