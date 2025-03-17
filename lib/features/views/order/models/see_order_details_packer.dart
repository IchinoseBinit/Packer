// class SeeOrderDetailsPacker {
//   final int id;
//   final late final String  productId;
//   final late final String  productName;
//   final late final String  productImage;
//   final late final String  measurement;
//   final double markedPrice;
//   final double discountPercent;
//   final double price;
//   final int quantity;

//   SeeOrderDetailsPacker({
//     required this.id,
//     required this.productId,
//     required this.productName,
//     required this.productImage,
//     required this.measurement,
//     required this.markedPrice,
//     required this.discountPercent,
//     required this.price,
//     required this.quantity,
//   });

//   factory SeeOrderDetailsPacker.fromJson(Map<late final String , dynamic> json) {
//     return SeeOrderDetailsPacker(
//       id: json['id'],
//       productId: json['product_id'],
//       productName: json['product_name'],
//       productImage: json['product_image'],
//       measurement: json['measurement'],
//       markedPrice: json['marked_price'],
//       discountPercent: json['discount_percent'],
//       price: json['price'],
//       quantity: json['quantity'],
//     );
//   }
// }

import 'package:packer/controllers/extensions/string_extension.dart';

class OrderDetailModel {
  late final bool success;
  late final List<ProductDetails> productDetails;
  late final OrderData data;

  OrderDetailModel(
      {required this.success,
      required this.productDetails,
      required this.data});

  OrderDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['product_details'] != null) {
      productDetails = <ProductDetails>[];
      json['product_details'].forEach((v) {
        productDetails.add(ProductDetails.fromJson(v));
      });
    }
    data = (json['data'] != null ? OrderData.fromJson(json['data']) : null)!;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['product_details'] = productDetails.map((v) => v.toJson()).toList();
    data['data'] = this.data.toJson();
    return data;
  }
}

class ProductDetails {
  late final int id;
  late final String productName;
  late final int quantity;
  late final String imageUrl;
  late final double _size;
  late final String measurement;
  late int itemScanCount;

  String get size {
    // Utility function to format size
    if (_size == _size.toInt()) {
      return _size.toInt().toString();
    } else {
      return _size.toString();
    }
  }

  ProductDetails(
      {required this.productName,
      required this.quantity,
      required this.imageUrl,
      required this.measurement});

  ProductDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    quantity = json['quantity'].toString().toInt();
    imageUrl = json['image_url'].toString().toStringConversion();
    _size = json['size'].toString().toDouble();

    measurement = json['measurement'].toString().toStringConversion();
    itemScanCount = 0;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_name'] = productName.toString().toStringConversion();
    data['quantity'] = quantity.toString().toInt();
    data['image_url'] = imageUrl.toString().toStringConversion();
    data['size'] = size.toString().toInt();

    data['measurement'] = measurement.toString().toStringConversion();

    return data;
  }
}

class OrderData {
  late final int id;
  late final String status;
  late final int count;
  late final String smallCartFee;
  late final String total;
  late final String finalTotal;
  late final UserInfo userInfo;

  OrderData({
    required this.id,
    required this.status,
    required this.count,
    required this.smallCartFee,
    required this.total,
    required this.finalTotal,
    required this.userInfo,
  });

  OrderData.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    status = json['status'].toString().toStringConversion();
    count = json['count'].toString().toInt();
    smallCartFee = json['small_cart_fee'].toString().toStringConversion();
    total = json['total'].toString().toStringConversion();
    finalTotal = json['final_total'].toString().toStringConversion();
    userInfo = (json['user_info'] != null
        ? UserInfo.fromJson(json['user_info'])
        : null)!;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id.toString().toInt();
    data['status'] = status.toString().toStringConversion();
    data['count'] = count.toString().toInt();
    data['small_cart_fee'] = smallCartFee.toString().toStringConversion();
    data['total'] = total.toString().toStringConversion();
    data['final_total'] = finalTotal.toString().toStringConversion();
    data['user_info'] = userInfo.toJson();

    return data;
  }
}

class UserInfo {
  late final String name;
  late final String addressName;
  late final String phone;
  late final String address;

  UserInfo(
      {required this.name,
      required this.addressName,
      required this.phone,
      required this.address});

  UserInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'].toString().toStringConversion();
    addressName = json['address_name'].toString().toStringConversion();
    phone = json['phone'].toString().toStringConversion();
    address = json['address'].toString().toStringConversion();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name.toString().toStringConversion();
    data['address_name'] = addressName.toString().toStringConversion();
    data['phone'] = phone.toString().toStringConversion();
    data['address'] = address.toString().toStringConversion();
    return data;
  }
}
