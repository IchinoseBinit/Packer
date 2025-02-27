import '../../../../controllers/extensions/string_extension.dart';

class User {
  late String id;
  late String name;
  late String? username;
  late String? phoneNumber;
  late String role;

  User.fromMap(Map obj) {
    id = obj['user_id'].toString().toStringConversion();
    name = obj['name'].toString().toStringConversion();
    username = obj['username'];
    phoneNumber = obj['phone_number'];
    role = obj['role'].toString().toStringConversion();
  }

}
