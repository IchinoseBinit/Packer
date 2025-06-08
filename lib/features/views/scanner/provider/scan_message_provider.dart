
import 'package:flutter/material.dart';

class ScanMessageProvider extends ChangeNotifier {

  String message = '';

  setMessage(String message) {
    this.message = message;
    notifyListeners();
  }

  // dispose
  @override
  void dispose() {
    message = '';
    super.dispose();
  }
  
}
