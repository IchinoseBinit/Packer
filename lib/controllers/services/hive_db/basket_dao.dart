import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';

class BasketDao {
  final Box<Basket> _box;

  BasketDao(this._box);

  List<Basket> getAll() {
    final list = _box.values.toList();
    log("Items: ${list.length}");
    for (var element in list) {
      log(element.toJson().toString());
    }
    return list;
  }

  Future<void> addOrUpdateBasket(Basket basket) async {
    await _box.put(basket.identifier.toString(), basket);
  }

  Future<void> deleteBasket(String basketId) async {
    await _box.delete(basketId);
  }

  Basket? getBasket(String basketId) => _box.get(basketId);

  Future<void> clearAll() async {
    await _box.clear();
  }
}
