import 'package:packer/controllers/extensions/string_extension.dart';

class CartonModel {
  late String cartonCode;
  late int productId;
  late String productName;
  late String rackName;
  late int quantity;
  late List<String> productUnits;

  CartonModel({
    required this.productId,
    required this.productName,
    required this.rackName,
    required this.quantity,
    this.productUnits = const [],
  });

  CartonModel.fromJson(Map<String, dynamic> json, String code) {
    cartonCode = code;
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
    productUnits = [];
    if (json['product_units'] != null) {
      for (var element in json['product_units']) {
        productUnits.add(element.toString());
      }
    }
  }
}
