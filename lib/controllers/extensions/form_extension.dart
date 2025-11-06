import 'package:flutter/material.dart';

extension FormStateExtension on FormState {
  bool saveAndValidate() {
    save();
    return validate();
  }
}
