
import 'package:flutter/material.dart';

class ScanMessageProvider extends ChangeNotifier {

  String message = '';

  setMessage(BuildContext context, String message) {
    this.message = message;
    print("Setting message $message");
    if (context.mounted) {
      notifyListeners();
    }
  }

  // dispose
  @override
  void dispose() {
    message = '';
    super.dispose();
  }
  
}
