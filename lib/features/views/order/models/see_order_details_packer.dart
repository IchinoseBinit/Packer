// class SeeOrderDetailsPacker {
//   final int id;
//   final String productId;
//   final String productName;
//   final String productImage;
//   final String measurement;
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

//   factory SeeOrderDetailsPacker.fromJson(Map<String, dynamic> json) {
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

class OrderDetailModel {
  bool? success;
  List<ProductDetails>? productDetails;
  Data? data;

  OrderDetailModel({this.success, this.productDetails, this.data});

  OrderDetailModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    if (json['product_details'] != null) {
      productDetails = <ProductDetails>[];
      json['product_details'].forEach((v) {
        productDetails!.add(ProductDetails.fromJson(v));
      });
    }
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    if (productDetails != null) {
      data['product_details'] = productDetails!.map((v) => v.toJson()).toList();
    }
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class ProductDetails {
  String? productName;
  int? quantity;
  String? imageUrl;
  num? size;
  String? measurement;

  ProductDetails({this.productName, this.quantity, this.imageUrl});

  ProductDetails.fromJson(Map<String, dynamic> json) {
    productName = json['product_name'];
    quantity = json['quantity'];
    imageUrl = json['image_url'];
    size = json['size'];

    measurement = json['measurement'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['product_name'] = productName;
    data['quantity'] = quantity;
    data['image_url'] = imageUrl;
    data['size'] = size;

    data['measurement'] = measurement;

    return data;
  }
}

class Data {
  int? id;
  String? status;
  int? count;
  String? smallCartFee;
  String? total;
  String? finalTotal;
  UserInfo? userInfo;
  Null additionalInfo;
  Null distance;

  Data(
      {this.id,
      this.status,
      this.count,
      this.smallCartFee,
      this.total,
      this.finalTotal,
      this.userInfo,
      this.additionalInfo,
      this.distance});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    status = json['status'];
    count = json['count'];
    smallCartFee = json['small_cart_fee'];
    total = json['total'];
    finalTotal = json['final_total'];
    userInfo =
        json['user_info'] != null ? UserInfo.fromJson(json['user_info']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['count'] = count;
    data['small_cart_fee'] = smallCartFee;
    data['total'] = total;
    data['final_total'] = finalTotal;
    if (userInfo != null) {
      data['user_info'] = userInfo!.toJson();
    }

    return data;
  }
}

class UserInfo {
  String? name;
  String? addressName;
  String? phone;
  String? address;

  UserInfo({this.name, this.addressName, this.phone, this.address});

  UserInfo.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    addressName = json['address_name'];
    phone = json['phone'];
    address = json['address'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['address_name'] = addressName;
    data['phone'] = phone;
    data['address'] = address;
    return data;
  }
}
