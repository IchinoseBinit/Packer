extension NumExtension on num {
 String toIntStringConversion() {
    // Utility function to format size
    if (this == toInt()) {
      return toInt().toString();
    } else if (runtimeType == double) {
      return toStringAsFixed(2);
    } else {
      return toString();  
    }
  }
}