import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';

class ProductDao {
  final Box<TrolleyItem> _box;

  ProductDao(this._box);

  List<TrolleyItem> getAll() {
    final list = _box.values.toList();
    log("Trolley Items: ${list.length}");
    for (var element in list) {
      log(element.toJson().toString());
    }
    return list;
  }

  Future<void> addOrUpdateProduct(TrolleyItem product) async {
    await _box.put(product.productId.toString(), product);
  }

  Future<void> deleteProduct(String productId) async {
    await _box.delete(productId);
  }

  TrolleyItem? getProduct(String productId) => _box.get(productId);

  Future<void> clearAll() async {
    await _box.clear();
  }

  List<TrolleyItem> getCollected() {
    final list = _box.values
        .where((e) => e.status == TrolleyItemStatus.collected)
        .toList();
    list.map((e) => log(e.toJson().toString()));
    return list;
  }
}
