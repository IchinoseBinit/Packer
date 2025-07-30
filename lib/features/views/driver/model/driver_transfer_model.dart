import 'package:packer/controllers/extensions/string_extension.dart';

/**
  {
    "transfers": [
        {
            "inventory_transfer_id": 15,
            "transfer_identifier": "transfer-Mother Warehouse-Nayabazar DS-566642",
            "destination_store_id": 7,
            "destination_store_name": "Nayabazar DS",
            "destination_store_latitude": 27.728817,
            "destination_store_longitude": 85.309325,
            "basket_identifiers": [
                "basket-Nayabazar DS-328c62"
            ]
        }
    ]
}
 */

class DriverTransferModel {
  late int inventoryTransferId;
  late String transferIdentifier;
  late int destinationStoreId;
  late String destinationStoreName;
  late double destinationStoreLatitude;
  late double destinationStoreLongitude;
  late List<String> basketIdentifiers;

  DriverTransferModel({
    required this.inventoryTransferId,
    required this.transferIdentifier,
    required this.destinationStoreId,
    required this.destinationStoreName,
    required this.destinationStoreLatitude,
    required this.destinationStoreLongitude,
    required this.basketIdentifiers,
  });

   DriverTransferModel.fromJson(Map<String, dynamic> json) {
    inventoryTransferId = json['inventory_transfer_id'].toString().toInt();
    transferIdentifier = json['transfer_identifier'].toString().toStringConversion();
    destinationStoreId = json['destination_store_id'].toString().toInt();
    destinationStoreName = json['destination_store_name'].toString().toStringConversion();
    destinationStoreLatitude = json['destination_store_latitude'].toString().toDouble();
    destinationStoreLongitude = json['destination_store_longitude'].toString().toDouble();
    basketIdentifiers = [];
    for (var element in json['basket_identifiers']) {
      basketIdentifiers.add(element.toString().toStringConversion());
    }
  }
}