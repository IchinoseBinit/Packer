import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';

class InventoryTransferRequestItemModel {
  late String? rackName;
  late String? productName;
  late int? productId;
  late int? quantity;
  late String? productImage;

  late List<String>? tags;

  InventoryTransferRequestItemModel({
    this.rackName,
    this.productName,
    this.productId,
    this.quantity,
    this.productImage,
    this.tags,
  });

  InventoryTransferRequestItemModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'].toString().toInt();
    rackName = json['rack_name'].toString().toStringConversion();
    productName = json['product_name'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
    productImage = AppUrls.imageUrl +
        json['product_image'].toString().toStringConversion();
    tags = [];
    if (json['tags'] != null) {
      for (var tag in json['tags']) {
        tags!.add(tag.toString().toStringConversion());
      }
    }

    // if tags come in units then assign to tags
    if (json['units'] != null) {
      for (var tag in json['units']) {
        tags!.add(tag.toString().toStringConversion());
      }
    }
  }

  // toJson
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_id'] = productId.toString().toInt();
    data['rack_name'] = rackName.toString().toStringConversion();
    data['product_name'] = productName.toString().toStringConversion();
    data['quantity'] = quantity.toString().toInt();
    data['product_image'] = productImage.toString().toStringConversion();
    data['tags'] = tags;
    return data;
  }
}
