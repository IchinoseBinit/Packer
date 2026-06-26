import 'dart:convert';

import 'package:packer/constants/app_constants.dart';

/// Decode a string that was produced by the Python custom_encode.
///
/// Throws [ArgumentError] if encoded contains a non-Base-62 character.
String customDecode(String encoded) {
  if (encoded.isEmpty) return '';

  // 1️⃣  Base-62 → big integer (use BigInt so size is unbounded)
  BigInt value = BigInt.zero;
  for (var codeUnit in encoded.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    final index = AppConstants.BASE62_CHARS.indexOf(char);
    if (index == -1) {
      throw ArgumentError("Invalid character '$char' in encoded string");
    }
    value = value * BigInt.from(62) + BigInt.from(index);
  }

  // 2️⃣  Big integer → byte list (little-endian, we'll reverse later)
  final bytesLE = <int>[];
  while (value > BigInt.zero) {
    bytesLE.add((value & BigInt.from(0xFF)).toInt());
    value = value >> 8;
  }

  // 3️⃣  Reverse to big-endian and decode as UTF-8
  return utf8.decode(bytesLE.reversed.toList());
}
