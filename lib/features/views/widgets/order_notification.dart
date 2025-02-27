import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/constants/app_colors.dart';

class OrderNotifier extends StatelessWidget {
  final int packingTime;
  final void Function() onPressed;
  const OrderNotifier({
    super.key,
    required this.packingTime,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fillColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 30.h,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(50))),
                    child: Icon(Icons.badge),
                  ),
                  SizedBox(
                    width: 10.w,
                  ),
                  Text(
                    "Will be packed on $packingTime minutes",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30.h,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GeneralElevatedButton(
                  title: 'Continue',
                  isDisabled: false,
                  onPressed: onPressed,
                ),
              ),
              SizedBox(
                height: 20.h,
              ),
            ],
          ),
        ),
        Positioned(
          top: -15.h,
          left: 100.w,
          child: Container(
            padding: EdgeInsets.fromLTRB(30.w, 5.h, 30.w, 5.h),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              "New Order !",
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
