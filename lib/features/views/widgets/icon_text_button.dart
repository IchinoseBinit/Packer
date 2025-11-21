import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:svg_flutter/svg_flutter.dart';

class IconTextButton extends StatelessWidget {
  final String title;
  final String assetURl;
  final Color? bgColor;
  final Color? fgColor;
  final double? borderRadius;
  final double? height;
  final double? width;
  final double? marginH;
  final VoidCallback onPressed;
  final TextStyle? textStyle;

  const IconTextButton({
    super.key,
    required this.title,
    required this.assetURl,
    this.bgColor,
    this.fgColor,
    this.borderRadius,
    this.height,
    this.width,
    this.marginH,
    required this.onPressed,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: marginH ?? 0,
      ),
      height: height ?? 60.h,
      width: width ?? double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? Color(0xFF327AF4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius ?? 10.r),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Transform.rotate(
                  angle: 45 * (3.1415926535 / 180),
                  child: Container(
                    height: 30.h,
                    width: 30.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  top: 5.h,
                  left: 4.h,
                  child: SvgPicture.asset(
                    assetURl,
                    height: 20.h,
                    width: 22.w,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.w),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: fgColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
