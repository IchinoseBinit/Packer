import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';

Widget customCupertinoActivityIndicator(bool isLight) {
  return Center(
    child: Theme(
      data: ThemeData(
        cupertinoOverrideTheme: CupertinoThemeData(
          brightness: isLight ? Brightness.light : Brightness.dark,
        ),
      ),
      child: CupertinoActivityIndicator(
        radius: 20.r,
      ),
    ),
  );
}

void showLoading(BuildContext context, {String? label}) {
  final alert = AlertDialog(
    content: Container(
      padding:
          EdgeInsets.symmetric(horizontal: (AppConstants.padding.left / 2)),
      margin: EdgeInsets.symmetric(horizontal: AppConstants.padding.left / 2),
      height: 40.h,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(
            width: 20.w,
          ),
          Text(
            label ?? "Loading...",
          ),
        ],
      ),
    ),
  );
  showDialog(
    barrierDismissible: kDebugMode,
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

void removeLoading(BuildContext context) {
  Navigator.pop(context);
}
