class CustomException implements Exception {
  late final String message;

  CustomException(this.message);
}

class LogoutException implements Exception {
  late final String? message;

  LogoutException([this.message]);
}
