import 'package:flutter/material.dart';
import 'package:packer/constants/app_constants.dart';

class ShowAlertDialog {
  ShowAlertDialog(
      {this.title,
      this.body,
      this.needCancel = false,
      this.noAction = false,
      this.okFunc,
      this.noPadding = false,
      this.cancelFunc,
      this.okTitle,
      this.cancelTitle,
      this.isDoublePop = false,
      this.disableBackground = false,
      this.cancelBtnColor,
      this.okBtnColor});

  String? title;
  String? okTitle;
  String? cancelTitle;
  Widget? body;
  Color? okBtnColor;
  Color? cancelBtnColor;
  bool needCancel;
  bool noAction;
  bool noPadding;
  bool isDoublePop;
  bool disableBackground;
  VoidCallback? cancelFunc;
  VoidCallback? okFunc;

  Future showAlertDialog(BuildContext context) async {
    Widget okButton = TextButton(
      onPressed: okFunc,
      child: Text(
        okTitle ?? "Ok",
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: okBtnColor ?? Colors.green),
      ),
    );

    Widget cancelButton = TextButton(
      onPressed: cancelFunc,
      child: Text(
        cancelTitle ?? "Cancel",
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: cancelBtnColor ?? Colors.red),
      ),
    );

    AlertDialog alert = AlertDialog(
      title: title == null
          ? Icon(
              Icons.report_problem_outlined,
              color: Theme.of(context).colorScheme.error,
            )
          : Text(title!,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontWeight: FontWeight.w600)),
      content: body,
      titlePadding: noPadding
          ? EdgeInsets.only(
              left: 20,
              right: 20,
              top: AppConstants.padding.top / 1.4,
            )
          : const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 16,
            ),
      contentPadding:
          noPadding ? EdgeInsets.zero : const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 16,
            ),
      actions: noAction
          ? []
          : [
              if (needCancel) cancelButton,
              okButton,
            ],
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return PopScope(
          canPop: true,
          child: alert,
        );
      },
    );
  }
}
