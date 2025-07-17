import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:packer/controllers/services/hive_db/product_model_adapter.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';

class HiveDBService {
  static Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TrolleyItemAdapter());
  }

  static Future<Box<TrolleyItem>> openProductBox(String storeId) async {
    return await Hive.openBox<TrolleyItem>('store_$storeId');
  }

  static Future<void> closeAll() async {
    await Hive.close();
  }
}
