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
}
