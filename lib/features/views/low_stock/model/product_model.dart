import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class ProductModel {
  late int id;
  late int productId;
  late String productName;
  late String imageUrl;
  late int quantity;
  late int? mainStoreStock;
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
    imageUrl = AppUrls.imageUrl +
        json['product_image'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
    size = json['size'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    scannedCount = 0;
  }

  Map<String, dynamic> toJson() {
    final data = {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': imageUrl,
      'quantity': quantity,
      'size': size,
      'measurement': measurement,
      'rack_name': rackName,
    };

    // Only add main_store_stock if it's not null
    if (mainStoreStock != null) {
      data['main_store_stock'] = mainStoreStock!;
    }

    return data;
  }
}
