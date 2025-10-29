import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:packer/constants/app_assets.dart';

showToast(String message, {Color? color}) {
  // Fluttertoa
  Fluttertoast.showToast(
    msg: message,
    backgroundColor: color,
    fontSize: 14.sp,
    toastLength: Toast.LENGTH_LONG,
  );
}

FToast? fToast;

void showLongToast({
  required BuildContext context,
  required String message,
  Color? backgroundColor = Colors.black87,
  Color? textColor = Colors.white,
  double fontSize = 14.0,
  int duration = 2, // Longer for long text
}) {
  fToast ??= FToast();
  fToast!.init(context); // Use Provider context

  Widget toast = Padding(
    padding: EdgeInsets.symmetric(vertical: 12.h),
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: backgroundColor,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            AppAssets.appLogo,
            width: 22.w,
            height: 22.h,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize.sp,
                fontWeight: FontWeight.w500,
              ),
              softWrap: true,
              maxLines: null, // Allows full message display
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    ),
  );

  return fToast!.showToast(
    child: toast,
    toastDuration: Duration(seconds: duration),
  );
}
