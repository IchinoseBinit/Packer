import '../../../../controllers/extensions/string_extension.dart';

class Token {
  late String accessToken;
  late String refreshToken;

  Token.fromMap(Map obj) {
    accessToken = obj['access'].toString().toStringConversion();
    refreshToken = obj['refresh'].toString().toStringConversion();
  }
}
