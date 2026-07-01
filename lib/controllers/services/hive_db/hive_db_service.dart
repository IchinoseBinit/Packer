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
