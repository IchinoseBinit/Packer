import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/audit_product/models/audit_status_enum.dart';

class PackerSummary {
  late String onlineTime;
  late int orderCount;
  // late String totalDistance;
  // late String topicName;
  late bool isOnline;
  late String storeType;
  // late bool isAvailable;

  late int scanGapTime;

  int? storeId;

  AuditStatusEnum? auditStatus;

  PackerSummary.fromJson(Map obj) {
    onlineTime = obj['total_online_time'].toString().toStringConversion();
    orderCount = obj['total_order_count'].toString().toInt();
    // totalDistance = obj['total_distance'].toString().toStringConversion();
    isOnline = obj['is_online'].toString().toBool(false);
    storeType = obj['store_type'].toString().toStringConversion();
    // isAvailable = obj['is_available'].toString().toBool(false);
    // topicName = obj['topic_name'] ?? "packers";

    scanGapTime = obj['scan_gap_time'] ?? 10;

    storeId = obj['store_id']?.toString().toInt();

    auditStatus = obj['audit_status'] == null
        ? null
        : AuditStatusEnum.values.firstWhere(
            (element) => element.value == obj['audit_status'],
            orElse: () => AuditStatusEnum.completed,
          );
  }
}
