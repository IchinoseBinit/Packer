
class Basket {
  final String identifier;
  final List<String> productIdentifiers;

  Basket({required this.identifier, required this.productIdentifiers});

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'product_unit_tags': productIdentifiers,
    };
  }

  // toPost
  Map<String, dynamic> toPostBasketRequest() {
    return {
      'basket_id': identifier,
      'scanned_tags': productIdentifiers,
    };
  }

  // from json
  factory Basket.fromJson(Map<String, dynamic> json) {
    return Basket(
      identifier: json['identifier'],
      productIdentifiers: List<String>.from(json['product_unit_tags']),
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
