class Basket {
  final String identifier;
  final List<String> productIdentifiers;
  List<String>? packageTags;

  Basket({
    required this.identifier,
    required this.productIdentifiers,
    this.packageTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'product_unit_tags': productIdentifiers,
      'package_tags': packageTags,
    };
  }

  // toPost
  Map<String, dynamic> toPostBasketRequest() {
    return {
      'basket_id': identifier,
      'scanned_tags': productIdentifiers,
      'package_tags': packageTags,
    };
  }

  // from json
  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      identifier: json['identifier'],
      productIdentifiers: List<String>.from(json['product_unit_tags']),
      packageTags: json['package_tags'] != null
          ? List<String>.from(json['package_tags'])
          : null,
    );
  }
}

class PostBasketRequest {
  final int orderId;
  final List<Basket> data;

  PostBasketRequest({required this.orderId, required this.data});

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'basket_data': data.map((basket) => basket.toJson()).toList(),
    };
  }
}
