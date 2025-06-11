import 'package:packer/controllers/extensions/string_extension.dart';

class Store {
  final int id;
  final String name;

  Store({
    required this.id,
    required this.name,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'].toString().toInt(),
      name: json['name'].toString().toStringConversion(),
    );
  }
}