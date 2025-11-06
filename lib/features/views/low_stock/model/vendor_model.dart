import 'package:packer/controllers/extensions/string_extension.dart';

class VendorModel {
  late int count;
  List<Vendors> vendors = [];

  VendorModel({
    required this.count,
    required this.vendors,
  });

  VendorModel.fromJson(Map<String, dynamic> json) {
    count = json['count'].toString().toInt();
    if (json['vendors'] != null) {
      vendors = <Vendors>[];
      json['vendors'].forEach((v) {
        vendors.add(Vendors.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['count'] = count;
    data['vendors'] = vendors.map((v) => v.toJson()).toList();
    return data;
  }
}

class Vendors {
  late int id;
  late String company;
  late String name;

  Vendors({
    required this.id,
    required this.company,
    required this.name,
  });

  Vendors.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString().toInt();
    company = json['company'].toString().toStringConversion();
    name = json['name'].toString().toStringConversion();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['company'] = company;
    data['name'] = name;
    return data;
  }
}
