import 'dart:developer';

import 'package:hive/hive.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_item_model.dart';

class InventoryRequestDao {

  final Box<InventoryTransferRequestItemModel> _box;

  InventoryRequestDao(this._box);

  List<InventoryTransferRequestItemModel> getAll() {
    final list = _box.values.toList();
    log("Items: ${list.length}");
    for (var element in list) {
      log(element.toJson().toString());
    }
    return list;
  }

  Future<void> addOrUpdateInventoryRequest(InventoryTransferRequestItemModel inventoryRequest) async {
    await _box.put(inventoryRequest.productId.toString(), inventoryRequest);
  }

  Future<void> deleteInventoryRequest(String productId) async {
    await _box.delete(productId);
  }

  InventoryTransferRequestItemModel? getInventoryRequest(String productId) => _box.get(productId);

  Future<void> clearAll() async {
    await _box.clear();
  }

  
}