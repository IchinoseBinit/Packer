import 'package:packer/controllers/extensions/string_extension.dart';

class CartonModel {
  late int productId;
  late String productName;
  late String rackName;
  late int quantity;

  CartonModel({
    required this.productId,
    required this.productName,
    required this.rackName,
    required this.quantity,
  });

  CartonModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
  }
}