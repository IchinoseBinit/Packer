import '../../../../controllers/extensions/string_extension.dart';

class UserInfo {
  late final int id;
  late final String name;
  late final String address;
  late final double latitude;
  late final double longitude;
  late final String additionalInfo;
  late final String homeImage;

  UserInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.additionalInfo,
    required this.homeImage,
  });

  UserInfo.fromJson(Map<String, dynamic> json)
      : id = json['id'].toString().toInt(),
        name = json['name'].toString().toStringConversion(),
        address = json['address'].toString().toStringConversion(),
        additionalInfo = json['additional_info'].toString().toStringConversion(),
        homeImage = json['home_image'].toString().toStringConversion(),
        latitude = json['latitude'].toString().toDouble(),
        longitude = json['longitude'].toString().toDouble();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
