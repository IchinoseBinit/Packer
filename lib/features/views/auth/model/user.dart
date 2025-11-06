import '../../../../controllers/extensions/string_extension.dart';

class User {
  late String id;
  late String name;
  late String? username;
  late String? phoneNumber;
  late UserRole role;

  User.fromMap(Map obj) {
    id = obj['user_id'].toString().toStringConversion();
    name = obj['name'].toString().toStringConversion();
    username = obj['username'];
    phoneNumber = obj['phone_number'];
    role = UserRole.fromString(obj['role'].toString().toStringConversion());
    // role = UserRole.fromString("driver");
  }

  // toString
  @override
  String toString() {
    return 'User(id: $id, name: $name, username: $username, phoneNumber: $phoneNumber, role: $role)';
  }

}

enum UserRole {
  packer, rider, manager, audit, driver;

  // from string
  static UserRole fromString(String role) {
    switch (role) {
      case 'packer':
        return UserRole.packer;
      case 'rider':
        return UserRole.rider;
      case 'manager':
        return UserRole.manager;
      case 'audit':
        return UserRole.audit;
      case 'driver':
        return UserRole.driver;
      default:
        throw Exception('Invalid user role');
    }
  }
}
