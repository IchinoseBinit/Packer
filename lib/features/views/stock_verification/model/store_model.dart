import 'package:packer/controllers/extensions/string_extension.dart';

class Store {
  final int id;
  final String name;
  final bool isMainStore;
  final String type;

  Store({
    required this.id,
    required this.name,
    required this.type,
  }) : isMainStore = type.toLowerCase() == 'main'; 

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'].toString().toInt(),
      name: json['name'].toString().toStringConversion(),
      type: json['type'].toString().toStringConversion(),
    );
  }
}
