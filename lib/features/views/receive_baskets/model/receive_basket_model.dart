// {
//             "transfer_id": 15,
//             "transfer_identifier": "transfer-Mother Warehouse-Nayabazar DS-566642",
//             "source_store": "Mother Warehouse",
//             "vehicle_plate": "BA-12-PA-3456",
//             "driver_name": "Heavy Driver",
//             "basket_identifiers": [
//                 "basket-Nayabazar DS-328c62"
//             ],
//             "total_baskets": 1
//         }

import 'package:packer/controllers/extensions/string_extension.dart';

class ReceiveBasketModel {
  late int transferId;
  late String transferIdentifier;
  late String sourceStore;
  late String vehiclePlate;
  late String driverName;
  late List<String> basketIdentifiers;
  late int totalBaskets;

  ReceiveBasketModel({
    required this.transferId,
    required this.transferIdentifier,
    required this.sourceStore,
    required this.vehiclePlate,
    required this.driverName,
    required this.basketIdentifiers,
    required this.totalBaskets,
  });

  ReceiveBasketModel.fromJson(Map<String, dynamic> json) {
    transferId = json['transfer_id'].toString().toInt();
    transferIdentifier = json['transfer_identifier'].toString().toStringConversion();
    sourceStore = json['source_store'].toString().toStringConversion();
    vehiclePlate = json['vehicle_plate'].toString().toStringConversion();
    driverName = json['driver_name'].toString().toStringConversion();
    totalBaskets = json['total_baskets'].toString().toInt();
    basketIdentifiers = [];
    for (var element in json['basket_identifiers']) {
      basketIdentifiers.add(element.toString().toStringConversion());
    }
  }


}