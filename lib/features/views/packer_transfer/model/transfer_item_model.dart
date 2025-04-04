// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:packer/controllers/extensions/string_extension.dart';

class TransferItemModel {
  int? id;
  int? product;
  String? productName;
  int? quantity;
  String? status;
  int itemScanCount;
  String? rack;
  List<String>? tags;

  TransferItemModel({
    this.id,
    this.product,
    this.productName,
    this.quantity,
    this.status,
    this.rack,
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
      'rack': rack,
    };
  }

  factory TransferItemModel.fromMap(Map<String, dynamic> map) {
    return TransferItemModel(
      id: map['id'].toString().toInt(),
      product: map['product'].toString().toInt(),
      productName: map['product_name'].toString().toString(),
      quantity: map['quantity'].toString().toInt(),
      status: map['status'].toString().toStringConversion(),
      rack: map['rack'].toString().toStringConversion(),
      itemScanCount:
          map['item_scan_count'].toString().toInt() ,
      tags: map['tags'] != null
          ? List<String>.from(
              (map['tags'] as List<dynamic>).map<String>((x) => x as String))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransferItemModel.fromJson(String source) =>
      TransferItemModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
