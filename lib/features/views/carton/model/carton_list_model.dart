// import 'package:packer/controllers/extensions/string_extension.dart';

// class CartonListModel {
//   final int id;
//   final String uniqueIdentifier;
//   final String status;
//   bool isScanned;
//   final DateTime createdAt;
//   final int productQuantity;

//   CartonListModel({
//     required this.id,
//     required this.uniqueIdentifier,
//     required this.status,
//     required this.createdAt,
//     required this.productQuantity,
//     this.isScanned = false,
//   });

//   factory CartonListModel.fromJson(Map<String, dynamic> json) {
//     return CartonListModel(
//       id: json['id'].toString().toInt(),
//       uniqueIdentifier:
//           json['unique_identifier'].toString().toStringConversion(),
//       status: json['status'].toString().toStringConversion(),
//       createdAt: DateTime.parse(json['created_at']),
//       productQuantity: json['product_quantity'].toString().toInt(),
//     );
//   }

//   setIsScanned(bool isScanned) {
//     this.isScanned = isScanned;
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'unique_identifier': uniqueIdentifier,
//       'status': status,
//       'created_at': createdAt.toIso8601String(),
//       'product_quantity': productQuantity,
//     };
//   }
// }
