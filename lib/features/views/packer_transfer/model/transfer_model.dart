// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';

class TransferModel {
    int? id;
    String? identifier;
    String? source;
    String? destination;
    String? status;
    String? createdAt;
    List<TransferItemModel>? items;

    TransferModel({
        this.id,
        this.identifier,
        this.source,
        this.destination,
        this.status,
        this.createdAt,
        this.items,
    });


  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'identifier': identifier,
      'source': source,
      'destination': destination,
      'status': status,
      'createdAt': createdAt,
      'items': items?.map((x) => x.toMap()).toList(),
    };
  }

  factory TransferModel.fromMap(Map<String, dynamic> map) {
    return TransferModel(
      id: map['id'].toString().toInt(),
      identifier: map['identifier'].toString().toStringConversion(),
      source: map['source'].toString().toStringConversion(),
      destination: map['destination'].toString().toStringConversion(),
      status: map['status'].toString().toStringConversion(),
      createdAt: map['createdAt'].toString().toStringConversion(),
      items: map['items'] != null
          ? List<TransferItemModel>.from(
              (map['items'] as List<dynamic>).map<TransferItemModel>(
                (x) => TransferItemModel.fromMap(x as Map<String, dynamic>),
              ),
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TransferModel.fromJson(String source) => TransferModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
