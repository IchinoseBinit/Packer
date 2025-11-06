import 'package:packer/controllers/extensions/string_extension.dart';

class BasketModel {
  late int id;
  late String identifier;


  // fromJson
  BasketModel.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    identifier = json['identifier'].toString().toStringConversion();
  }
}