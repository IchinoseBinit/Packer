import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class ProductModel {
  late int id;
  late int productId;
  late String productName;
  late String imageUrl;
  late int quantity;
  late String size;
  late String measurement;
  late String rackName;
  late int scannedCount;

  // fromJson
  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    imageUrl = AppUrls.imageUrl +
        json['product_image'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
    size = json['size'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    scannedCount = 0;
  }

  
}
