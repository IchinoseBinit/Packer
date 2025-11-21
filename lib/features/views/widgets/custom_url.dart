
import 'package:shared_preferences/shared_preferences.dart';

class CustomUrlManager {
  static const String _key = "";

  static Future<void> setCustomUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  static Future<String?> getCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> clearCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
