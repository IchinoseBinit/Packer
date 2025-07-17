
import 'package:hive/hive.dart';
import 'package:packer/controllers/services/hive_db/trolley_item.dart';

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
