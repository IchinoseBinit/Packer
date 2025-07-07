import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

class ErrorHandler {
  static const errorMessage =
      "Cannot process at the moment. Please try again later.";

  errorHandler(
    BuildContext context,
    Object ex,
  ) {
    print(ex);
    final isFormatException = ex.runtimeType.toString() == "_TypeError";

    if (isFormatException) {
      Navigator.pop(context);
      showToast(ex.toString(), color: AppColors.primaryColor);
    } else {
      Navigator.pop(context);
      showToast(ex.toString(), color: AppColors.primaryColor);
    }
  }

  // alert dialog
  static Future<void> alertDialog(BuildContext context, String message,
      [Function()? okFunc]) async {
    if (!context.mounted) return;
    ShowAlertDialog(
            disableBackground: true,
            body: Text(message),
            okFunc: okFunc ??
                () {
                  navigatePop(context);
                })
        .showAlertDialog(context);
  }
}
