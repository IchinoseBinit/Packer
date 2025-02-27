class SeeOrderDetailsPacker {
  final int id;
  final String productId;
  final String productName;
  final String productImage;
  final String measurement;
  final double markedPrice;
  final double discountPercent;
  final double price;
  final int quantity;

  SeeOrderDetailsPacker({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.measurement,
    required this.markedPrice,
    required this.discountPercent,
    required this.price,
    required this.quantity,
  });

  factory SeeOrderDetailsPacker.fromJson(Map<String, dynamic> json) {
    return SeeOrderDetailsPacker(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productImage: json['product_image'],
      measurement: json['measurement'],
      markedPrice: json['marked_price'],
      discountPercent: json['discount_percent'],
      price: json['price'],
      quantity: json['quantity'],
    );
  }
}
