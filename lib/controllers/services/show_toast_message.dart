import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';

showToast(String message, {Color? color}) {
  // Fluttertoa
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: color,
    fontSize: 14.sp,
  );
}
