import 'dart:developer';

import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/fruits_vegs/models/can_be_eaten_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_category_enum.dart';
import 'package:packer/features/views/fruits_vegs/models/ripeness_score.dart';

class ProductModel {
  late int id;
  late int productId;
  late String productName;
  late String imageUrl;
  late int quantity;
  int? mainStoreStock; // nullable, not late
  late String size;
  late String measurement;
  late String rackName;
  late int scannedCount;
  late int? bogoBuyProductId;

  //
  late bool? isPerishableProduce;

  // units
  List<Units>? units;

  //

  // fromJson constructor
  ProductModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    productId = json['product_id'].toString().toInt();
    productName = json['product_name'].toString().toStringConversion();
    mainStoreStock = json['main_store_stock']?.toString().toInt();
    imageUrl =
        "${AppUrls.imageUrl}${json['product_image'].toString().toStringConversion()}?w=400&h=400&q=80";

    units = json['units'] != null
        ? List<Units>.from(json['units'].map((x) => Units.fromJson(x)))
        : null;
    //
    quantity = json['quantity'] != null
        ? json['quantity'].toString().toInt()
        : units?.length ?? 0;

    //
    isPerishableProduce =
        json['is_perishable_produce'].toString().toBool(false);
    //
    size = json['size'].toString().toStringConversion();
    measurement = json['measurement'].toString().toStringConversion();
    rackName = json['rack_name'].toString().toStringConversion();
    bogoBuyProductId = json['bogo_buy_product_id']?.toString().toInt();
    scannedCount = 0;
  }

  // toJson method (safe and clean)
  Map<String, dynamic> toJson() {
    final effectiveQuantity =
        (mainStoreStock != null && quantity > mainStoreStock!)
            ? mainStoreStock!
            : quantity;
    log('Effective Quantity: $effectiveQuantity');

    final data = {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image': imageUrl,
      'quantity': effectiveQuantity,
      'size': size,
      'measurement': measurement,
      'rack_name': rackName,
      'is_perishable_produce': isPerishableProduce,
    };

    if (mainStoreStock != null) {
      data['main_store_stock'] = mainStoreStock!;
    }

    return data;
  }
}

class Units {
  String? tag;
  String? stockDate;

  //if already scanned, then we can show the scanned date instead of stock date
  RipenessCategoryEnum? ripenessCategory;
  RipenessScore? ripenessScore;
  List<CanBeEatenEnum>? canBeEaten;
  String? assessedBy;
  DateTime? assessedAt;

  Units.fromJson(Map<String, dynamic> json) {
    tag = json['tag']?.toString().toStringConversion();
    stockDate = json['stocked_date']?.toString().toStringConversion();
    //
    ripenessCategory = json['ripeness_category'] != null
        ? RipenessCategoryEnum.values
            .firstWhere((e) => e.value == json['ripeness_category'].toString())
        : null;
    ripenessScore = json['ripeness_score'] != null
        ? RipenessScore.values.firstWhere(
            (e) => e.score == json['ripeness_score'].toString().toInt())
        : null;
    canBeEaten = json['can_be_eaten'] != null
        ? List<CanBeEatenEnum>.from(json['can_be_eaten'].map((e) =>
            CanBeEatenEnum.values.firstWhere((x) => x.value == e.toString())))
        : null;
    assessedBy = json['assessed_by']?.toString().toStringConversion();
    assessedAt = json['assessed_at'] != null
        ? DateTime.parse(json['assessed_at'].toString()).toLocal()
        : null;
  }
}
