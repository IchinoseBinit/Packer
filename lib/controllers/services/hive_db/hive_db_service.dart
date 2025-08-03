import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/hive_db/model_adapter.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';
import 'package:path_provider/path_provider.dart';

class HiveDBService {
  static Future<void> initHive() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/${HiveConstants.hivePath}';
    await Hive.initFlutter(hivePath);
    Hive.registerAdapter(TrolleyItemAdapter());
    Hive.registerAdapter(BasketAdapter());
  }

  static Future<Box<TrolleyItem>> openProductBox(String storeId) async {
    return await Hive.openBox<TrolleyItem>('${HiveConstants.storeId}$storeId');
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }

 static Future<void> wipeHiveCompletely() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final hivePath = '${appDocDir.path}/${HiveConstants.hivePath}';

    final hiveDir = Directory(hivePath);
    if (await hiveDir.exists()) {
      await hiveDir.delete(recursive: true);
    }
  }

  // static Future<void> clearAllBoxes() async {
  //   for (var box in Hive.boxes.values) {
  //     await box.clear();
  //   }
  // }

  // static Future<void> deleteAllBoxesFromDisk() async {
  //   for (var box in Hive.boxes.values) {
  //     await box.deleteFromDisk();
  //   }
  // }
}
