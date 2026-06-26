import 'package:intl/intl.dart';

class ValidationMixin {
  validateMobileNumber(String value, {String? title}) {
    final validation = validate(value, title: title);
    if (validation == null) {
      if (value.trim().length != 10) {
        return "$title must be 10 digits";
      }
    }
    return validation;
  }

  validate(String value, {String? title}) {
    if (value.trim().isEmpty) {
      return title == null ? "This field is required" : "$title is required";
    }
    return null;
  }

  String validateNumber(
    String text, {
    double maxAmt = 10000,
    double minAmt = 0,
    bool isCheckZero = true,
    bool isCheckMaxAmt = true,
  }) {
    if (text.trim().isEmpty) {
      return "Please enter an amount";
    }
    try {
      double number = double.parse(text.trim());
      if (number == 0) {
        return "Your amount cannot be 0";
      }
      if (number > maxAmt && isCheckMaxAmt) {
        return "Your amount cannot be more than Rs. $maxAmt";
      } else if (number < minAmt) {
        return "Your amount cannot be less than Rs. $minAmt";
      }
      return "";
    } catch (ex) {
      return "Please enter a number";
    }
  }

  String validateDob(String text) {
    if (text.trim().isEmpty) {
      return "Please enter your date of birth";
    }
    return "";
  }

  bool isValidPhoneNumber(String value) {
    if (value.trim().isEmpty) {
      return false;
    }
    if (value.trim().length != 10) {
      return false;
    }
    try {
      int number = int.parse(value.trim());
      if (number.toString().length == 10) {
        return true;
      }
      return false;
    } catch (ex) {
      return false;
    }
  }

  int? extractStoreIdFromQr(String qrData, int expectedStoreId) {
    final parts = qrData.split('-');

    if (parts.length < 4) return null;

    final storeId = int.tryParse(parts[2]);

    if (storeId == null || storeId != expectedStoreId) {
      return null;
    }

    return storeId;
  }

  QrResult validateWaitlistToken(String token) {
    try {
      // Example token: fasto-waitlist-3-2025-04-12 11:22:34
      final dateTimeStr = token.split('-').sublist(3).join('-');
      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final tokenTime = dateFormat.parse(dateTimeStr);

      final now = DateTime.now();
      final difference = now.difference(tokenTime).inSeconds;

      if (difference.abs() > 6) {
        print("${now.hour} ${now.minute} ${now.second}");
        return QrResult(
          message: 'Waitlist QR Expired. Please scan again',
          success: false,
        );
      }

      return QrResult(
        message: 'Qr is valid',
        success: true,
      );
    } catch (e) {
      print(e);
      return QrResult(
        message: 'Invalid Waitlist Qr. Please scan again',
        success: false,
      );
    }
  }
}

class QrResult {
  final String message;
  final bool success;

  QrResult({required this.message, required this.success});
}
