
import 'package:hive/hive.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';
import 'package:packer/features/views/inventory_transfer_request/model/inventory_transfer_request_item_model.dart';
import 'package:packer/features/views/widgets/post_basket_model.dart';

class TrolleyItemAdapter extends TypeAdapter<TrolleyItem> {
  @override
  final int typeId = 0;

  @override
  TrolleyItem read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return TrolleyItem.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, TrolleyItem obj) {
    writer.writeMap(obj.toJson());
  }
}


class BasketAdapter extends TypeAdapter<Basket> {
  @override
  final int typeId = 1;

  @override
  Basket read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return Basket.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, Basket obj) {
    writer.writeMap(obj.toJson());
  }
}

class InventoryTransferRequestItemAdapter extends TypeAdapter<InventoryTransferRequestItemModel> {
  @override
  final int typeId = 2;

  @override
  InventoryTransferRequestItemModel read(BinaryReader reader) {
    final map = Map<String, dynamic>.from(reader.readMap());
    return InventoryTransferRequestItemModel.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, InventoryTransferRequestItemModel obj) {
    writer.writeMap(obj.toJson());
  }
}
