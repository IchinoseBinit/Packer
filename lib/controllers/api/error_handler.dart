import 'package:flutter/material.dart';
import 'package:packer/controllers/api/app_exception.dart';
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
    final isFormatException = ex.runtimeType.toString() == "_TypeError";

    if (isFormatException) {
      Navigator.pop(context);
      showToast(errorMessage, color: AppColors.primaryColor);
    } else {
      //
      final errorMessage = ex.runtimeType is AppException
          ? (ex as AppException).message
          : ex.toString();

      Navigator.pop(context);
      showToast(errorMessage, color: AppColors.primaryColor);
    }
  }

  // alert dialog
  static Future<void> alertDialog(BuildContext context, dynamic message,
      [Function()? okFunc]) async {
    final errorMessage = message.runtimeType is AppException
        ? (message as AppException).message
        : message.toString();
    if (!context.mounted) return;
    ShowAlertDialog(
            disableBackground: true,
            body: Text(errorMessage),
            okFunc: okFunc ??
                () {
                  navigatePop(context);
                })
        .showAlertDialog(context);
  }
}
