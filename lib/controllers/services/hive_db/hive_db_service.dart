import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/hive_db/model_adapter.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_item_model.dart';
import 'package:path_provider/path_provider.dart';

class HiveDBService {
  static Future<void> initHive() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/${HiveConstants.hivePath}';
    await Hive.initFlutter(hivePath);
    Hive.registerAdapter(TrolleyItemAdapter());
    Hive.registerAdapter(BasketAdapter());
    Hive.registerAdapter(InventoryTransferRequestItemAdapter());
    await Hive.openBox(HiveConstants.auditScanBox);
  }

  static Future<Box<TrolleyItem>> openProductBox(String storeId) async {
    return await Hive.openBox<TrolleyItem>('${HiveConstants.storeId}$storeId');
  }

  static Future<Box<InventoryTransferRequestItemModel>>
      openInventoryTransferRequestBox(String id) async {
    return await Hive.openBox<InventoryTransferRequestItemModel>(
        '${HiveConstants.inventoryTransferRequest}$id');
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }

  /// Deletes every saved basket from disk: the tags a packer scanned into a
  /// basket for an order, or for a return, that they never finished.
  ///
  /// Local only. A basket reaches the server once, when it is posted, and the
  /// record is deleted with it - so nothing dropped here is a hand-over the
  /// server is still waiting for. Leaves the trolley, audit and transfer boxes
  /// alone: those hold stock counted against the store, not the tags of one
  /// packer's session.
  static Future<void> clearSavedBaskets() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/${HiveConstants.hivePath}';
    final hiveDir = Directory(hivePath);
    if (!await hiveDir.exists()) {
      return;
    }

    // Both families BasketDao writes: a return box holds the same scanned tags
    // and is restored the same way, and its name is not under the order prefix.
    const prefixes = [HiveConstants.order, HiveConstants.orderReturn];

    // A box is up to three files; name it from whichever holds the data and
    // let Hive take the rest, closing the box if it is still open.
    final boxes = <String>{};
    await for (final entity in hiveDir.list()) {
      final file = entity.uri.pathSegments.last;
      if (!prefixes.any(file.startsWith)) {
        continue;
      }
      for (final suffix in const ['.hive', '.hivec']) {
        if (file.endsWith(suffix)) {
          boxes.add(file.substring(0, file.length - suffix.length));
        }
      }
    }

    for (final box in boxes) {
      await Hive.deleteBoxFromDisk(box);
    }
  }

  /// Closes all open boxes and deletes every Hive box from disk.
  static Future<void> wipeHiveCompletely() async {
    await Hive.deleteFromDisk();

    // Remove the Hive directory in case any stray box files remain.
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/${HiveConstants.hivePath}';
    final hiveDir = Directory(hivePath);
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  }
}
