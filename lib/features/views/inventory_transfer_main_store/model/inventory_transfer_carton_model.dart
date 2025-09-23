import 'package:packer/controllers/extensions/string_extension.dart';

class InventoryTransferCartonModel {
  late int id;
  late String uniqueIdentifier;
  late String status;
  late String createdAt;
  late int productQuantity;

  InventoryTransferCartonModel({
    required this.id,
    required this.uniqueIdentifier,
    required this.status,
    required this.createdAt,
    required this.productQuantity,
  });

  InventoryTransferCartonModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    uniqueIdentifier =
        json['unique_identifier'].toString().toStringConversion();
    status = json['status'].toString().toStringConversion();
    createdAt = json['created_at'].toString().toStringConversion();
    productQuantity = json['product_quantity'].toString().toInt();
  }
}
