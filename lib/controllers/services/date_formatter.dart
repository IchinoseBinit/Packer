import 'package:intl/intl.dart';

class DateFormatter {
  String formatTimestamp(String timestamp) {
    // Removes the +Plus symbol so that the app does not subtract the time
    timestamp = timestamp.split("+").first;
    final DateTime dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm a');
    return formatter.format(dateTime);
  }
}