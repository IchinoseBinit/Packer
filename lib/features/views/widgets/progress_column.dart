import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';

class TodaysProgressWidget extends StatelessWidget {
  const TodaysProgressWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Provider.of<HomeProvider>(context, listen: false).fetchpackerSummary();
    return Consumer<HomeProvider>(builder: (_, provider, __) {
      final packerSummary = provider.packerSummary;
      if (packerSummary == null) {
        return const SizedBox.shrink();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            textAlign: TextAlign.left,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(
            height: 8.h,
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.fillColor,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Padding(
              padding: AppConstants.padding,
              child: Builder(builder: (context) {
                // debugger();
                final width = (1.sw - 64 - 40.w) / 2;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EachCountWidget(
                      width: width,
                      title: "Orders",
                      value: packerSummary.orderCount.toString(),
                    ),
                    SizedBox(
                      width: 20.w,
                    ),
                    EachCountWidget(
                      width: width,
                      title: "Time",
                      value: packerSummary.onlineTime.toString(),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      );
    });
  }
}

class EachCountWidget extends StatelessWidget {
  const EachCountWidget(
      {super.key,
      required this.width,
      required this.title,
      required this.value});

  final double width;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
