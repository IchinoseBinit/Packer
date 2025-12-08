class AppException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic json;

  AppException({
    this.statusCode,
    required this.message,
    this.json,
  });

  @override
  String toString() => message;
}
