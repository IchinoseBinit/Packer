// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:packer/controllers/extensions/string_extension.dart';

class TransferItemModel {
  int? id;
  int? product;
  String? productName;
  late String productImage;
  int? quantity;
  String? status;
  int itemScanCount;
  String? rack;
  double? size;
  String? measurement;

  List<String>? tags;

  TransferItemModel({
    this.id,
    this.product,
    this.productName,
    this.productImage = "",
    this.quantity,
    this.status,
    this.rack,
    this.size,
    this.measurement,
    this.itemScanCount = 0,
    this.tags,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'product': product,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'status': status,
      'itemScanCount': itemScanCount,
      'tags': tags,
      'rack': rack,
      'size': size,
      'measurement': measurement,
    };
  }

  factory TransferItemModel.fromMap(Map<String, dynamic> map) {
    return TransferItemModel(
      id: map['id'].toString().toInt(),
      product: map['product_id'].toString().toInt(),
      productName: map['product_name'].toString().toString(),
      productImage: map['product_image'].toString().toString(),
      quantity: map['quantity'].toString().toInt(),
      status: map['status'].toString().toStringConversion(),
      rack: map['rack'].toString().toStringConversion(),
      size: map['size'].toString().toDouble(),
      measurement: map['measurement'].toString().toStringConversion(),
      itemScanCount: map['item_scan_count'].toString().toInt(),
      tags: map['unit_tags'] != null
          ? List<String>.from((map['unit_tags'] as List<dynamic>)
              .map<String>((x) => x as String))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransferItemModel.fromJson(String source) =>
      TransferItemModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
