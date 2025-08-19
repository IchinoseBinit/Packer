import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GeneralElevatedButton extends StatelessWidget {
  static double getDefaultHeight() => 48.h;

  final String title;
  final bool isSmallText;
  final Color? bgColor;
  final Color? fgColor;
  final VoidCallback onPressed;
  final bool checkInternet;
  final double? borderRadius;
  final bool isDisabled;
  final double? height;
  final double? width;
  final double? marginH;
  final double? elevation;
  final TextStyle? textStyle;
  final bool isFittedBox;
  final Icon? icon;
  final Color? borderColor;

  const GeneralElevatedButton({
    super.key,
    this.isSmallText = false,
    required this.title,
    this.bgColor,
    this.fgColor,
    this.borderRadius,
    this.isDisabled = false,
    this.checkInternet = true,
    required this.onPressed,
    this.height,
    this.width,
    this.marginH,
    this.textStyle,
    this.elevation,
    this.isFittedBox = false,
    this.icon,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    var textStyle = this.textStyle;
    if (textStyle == null) {
      if (isSmallText) {
        textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: fgColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 600,
            );
        print(textStyle);
      } else {
        textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: fgColor ?? Colors.white,
              fontWeight: FontWeight.w500,
            );
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: marginH ?? 0),
      height: height ?? getDefaultHeight(),
      width: width ?? double.infinity,
      child: ElevatedButton(
        key: key,
        style: ButtonStyle(
          elevation: WidgetStateProperty.all(elevation),
          backgroundColor: WidgetStateProperty.all(
            isDisabled
                ? Theme.of(context).disabledColor
                : bgColor ?? Theme.of(context).primaryColor,
          ),
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? 5.r),
              side: BorderSide(
                color: borderColor ?? Theme.of(context).primaryColor,
                width: 1.0,
              ),
            ),
          ),
        ),
        onPressed: isDisabled
            ? () {}
            : () async {
                onPressed();
                // if (!checkInternet) {
                // } else {
                //   final provider = Provider.of<ConnectivityProvider>(context, listen: false);
                //   if (provider.isConnected) {
                //     onPressed!();
                //   } else {
                //     ShowAlertDialog(
                //       okFunc: () => Navigator.pop(context),
                //       body: Text(LocaleKeys.noInternetDescription.tr()),
                //       title: LocaleKeys.noInternet.tr()
                //     ).showAlertDialog(context);
                //   }
                // }
              },
        child: Builder(builder: (context) {
          final child = Center(
            child: Text(
              title,
              style: textStyle,
              textAlign: TextAlign.center,
            ),
          );
          if (isFittedBox) {
            return FittedBox(
              child: child,
            );
          } else {
            return child;
          }
        }),
      ),
    );
  }
}
