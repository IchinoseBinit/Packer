// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class TransferItemModel {
    int? id;
    int? product;
    String? productName;
    int? quantity;
    String? status;
    int itemScanCount;
    List<String>? tags;

    TransferItemModel({
        this.id,
        this.product,
        this.productName,
        this.quantity,
        this.status,
        this.itemScanCount = 0,
        this.tags,
    });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'product': product,
      'productName': productName,
      'quantity': quantity,
      'status': status,
      'itemScanCount': itemScanCount,
      'tags': tags,
    };
  }

  factory TransferItemModel.fromMap(Map<String, dynamic> map) {
    return TransferItemModel(
      id: map['id'] != null ? map['id'] as int : null,
      product: map['product'] != null ? map['product'] as int : null,
      productName: map['product_name'] != null ? map['product_name'] as String : null,
      quantity: map['quantity'] != null ? map['quantity'] as int : null,
      status: map['status'] != null ? map['status'] as String : null,
      itemScanCount: map['item_scan_count'] != null ? map['item_scan_count'] as int : 0,
      tags: map['tags'] != null
          ? List<String>.from((map['tags'] as List<dynamic>).map<String>((x) => x as String))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransferItemModel.fromJson(String source) => TransferItemModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
