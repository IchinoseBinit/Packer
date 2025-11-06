import 'package:packer/controllers/extensions/string_extension.dart';

class PackerSummary {
  late String onlineTime;
  late int orderCount;
  // late String totalDistance;
  // late String topicName;
  late bool isOnline;
  late String storeType;
  // late bool isAvailable;

  PackerSummary.fromJson(Map obj) {
    onlineTime = obj['total_online_time'].toString().toStringConversion();
    orderCount = obj['total_order_count'].toString().toInt();
    // totalDistance = obj['total_distance'].toString().toStringConversion();
    isOnline = obj['is_online'].toString().toBool(false);
    storeType = obj['store_type'].toString().toStringConversion();
    // isAvailable = obj['is_available'].toString().toBool(false);
    // topicName = obj['topic_name'] ?? "packers";
  }
}
