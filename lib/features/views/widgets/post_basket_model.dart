import 'package:flutter/material.dart';

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
