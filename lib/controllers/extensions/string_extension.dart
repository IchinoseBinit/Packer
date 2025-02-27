extension StringExtension on String? {
  int toInt() {
    if (this == null || int.tryParse(toString()) == null) {
      return 0;
    }
    return int.parse(toString());
  }

  double toDouble() {
    if (this == null || double.tryParse(toString()) == null) {
      return 0.0;
    }
    return double.parse(toString());
  }

  String toStringConversion() {
    if (this == "null") {
      return "";
    }
    return toString();
  }

  ///The value passed in the parameter is the alternative value if the bool is null
  bool toBool(bool value) {
    if (this == "null") {
      return value;
    }
    return this == "true";
  }

  String convertCamelToKebabCase() {
    // Use regular expressions to identify capital letters and insert hyphens
    String result = this!.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (Match match) => '-${match.group(1)!.toLowerCase()}',
    );
    // Remove leading hyphen if present
    if (result.startsWith('-')) {
      result = result.substring(1);
    }
    return result;
  }

  String addSlashInRoute() {
    return "/$this";
  }

  
}
