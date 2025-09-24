import 'package:packer/controllers/extensions/string_extension.dart';

class InventoryTransferRequestModel {
    late int id;
    late String sourceStore;
    late String destinationStore;
    late String status;
    late String createdBy;
    late String createdAt;

    InventoryTransferRequestModel({
        required this.id,
        required this.sourceStore,
        required this.destinationStore,
        required this.status,
        required this.createdBy,
        required this.createdAt,
    });

    InventoryTransferRequestModel.fromJson(Map<String, dynamic> json) {
        id = json['id'].toString().toInt();
        sourceStore = json['source_store'].toString().toStringConversion();
        destinationStore = json['destination_store'].toString().toStringConversion();
        status = json['status'].toString().toStringConversion();
        createdBy = json['created_by'].toString().toStringConversion();
        createdAt = json['created_at'].toString().toStringConversion();
    }

  get source => null;

}
