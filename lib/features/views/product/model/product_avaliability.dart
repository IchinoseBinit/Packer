

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class ProductAvailability {
  late int productId;
  late String productName;
  late String rackName;
  late String newRackName;
  late String image;
  late List<String> productUnits;

  ProductAvailability({
    required this.productId,
    required this.productName,
    required this.rackName,
    required this.newRackName,
    required this.image,
    required this.productUnits,
  });

  ProductAvailability.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    newRackName = json['new_rack_name'].toString().toStringConversion();
    image = AppUrls.imageUrl + json['image'].toString().toStringConversion();
    productUnits = [];
    for (var element in json['product_units']) {
      productUnits.add(element.toString().toStringConversion());
    }
  }
}
  

