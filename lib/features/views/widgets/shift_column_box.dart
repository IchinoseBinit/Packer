import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:svg_flutter/svg_flutter.dart';

class ShiftColumnBox extends StatelessWidget {
  final int startingHour;
  final int startingMin;
  final int endingHour;
  final int endingMin;
  final int remainingTime;
  final bool isOnline;
  const ShiftColumnBox(
      {super.key,
      required this.startingHour,
      required this.startingMin,
      required this.endingHour,
      required this.endingMin,
      required this.remainingTime,
      required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "$startingHour:$startingMin am - $endingHour:$endingMin pm",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(
                width: 10.w,
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isOnline ? Colors.red[100] : Colors.blue[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isOnline ? "Shift Ongoing" : "Starts in $remainingTime mins",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.sp,
                    color: isOnline ? AppColors.primaryColor : Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.splashBackgroundColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  padding: EdgeInsets.all(5),
                  child: SvgPicture.asset(
                    AppAssets.clock,
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Shift starts at $startingHour am",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Please reach your store before shift start time.",
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w300),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
