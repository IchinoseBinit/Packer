import 'package:packer/controllers/extensions/string_extension.dart';

class CartonListModel {
  final int id;
  final String uniqueIdentifier;
  final String status;
  final DateTime createdAt;

  CartonListModel({
    required this.id,
    required this.uniqueIdentifier,
    required this.status,
    required this.createdAt,
  });

  factory CartonListModel.fromJson(Map<String, dynamic> json) {
    return CartonListModel(
      id: json['id'].toString().toInt(),
      uniqueIdentifier:
          json['unique_identifier'].toString().toStringConversion(),
      status: json['status'].toString().toStringConversion(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unique_identifier': uniqueIdentifier,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
