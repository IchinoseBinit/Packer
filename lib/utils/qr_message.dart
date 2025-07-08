import 'dart:developer';

String detectQrMessage(String input) {
  final lower = input.toLowerCase();
  final types = {
    "product": "- Product qr detected",
    "carton": "- Carton qr detected",
    "rack": "- Rack qr detected",
    "identifier": "- Identifier qr detected",
    "order": "- Order qr detected",
    "basket": "- Basket qr detected",
  };

  for (var key in types.keys) {
    if (lower.contains(key)) return types[key]!;
  }

  return "Unknown QR detected";
}
