class TrolleyItem {

  late int productId;
  late String productName;
  late String image;
  
  late List<String> tags;
  late int quantity;

  late TrolleyItemStatus status;

  // constructor
  TrolleyItem({
    required this.productId,
    required this.productName,
    required this.image,
    required this.tags,
    required this.quantity,
    this.status = TrolleyItemStatus.collected,
  });

  // fromJson
  TrolleyItem.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    image = json['image'];
    tags = List<String>.from(json['tags']);
    quantity = json['quantity'];
    status = TrolleyItemStatus.values.firstWhere(
      (e) => e.name == json['status'],
    );
  }


  // toJson
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'image': image,
      'tags': tags,
      'quantity': quantity,
      'status': status.name,
    };
  }

  
}

enum TrolleyItemStatus {
  collected,
  distributed;
}
