import 'package:packer/controllers/extensions/string_extension.dart';

class CustomerInfo {
  final String name;
  final String phoneNumber;

  CustomerInfo({
    required this.name,
    required this.phoneNumber,
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'].toString().toStringConversion(),
      phoneNumber: json['phone_number'].toString().toStringConversion(),
    );
  }
}
