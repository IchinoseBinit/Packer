import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/widgets/product_item_list.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
// import 'package:slider_button/slider_button.dart';
import 'package:svg_flutter/svg_flutter.dart';

class DeliveredPage extends StatelessWidget {
  final int noOfItems;
  const DeliveredPage({
    super.key,
    required this.noOfItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.splashBackgroundColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SvgPicture.asset(
                        AppAssets.bag,
                        height: 24.h,
                        width: 24.w,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    SizedBox(
                      width: 10.h,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          "#543657463827",
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              ),
                        ),
                        Text(
                          "$noOfItems items",
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                    padding: EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.splashBackgroundColor,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Text(
                          "1",
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge!
                              .copyWith(color: AppColors.primaryColor),
                        ),
                        SizedBox(
                          width: 5.w,
                        ),
                        SvgPicture.asset(AppAssets.bag),
                      ],
                    ))
              ],
            ),
            SizedBox(height: 10.h),
            Divider(
              color: Colors.grey[300],
              thickness: 1,
            ),
            ProductItemList(),
            SizedBox(height: 10.h),
            // SliderButton(
            //   width: 330.w,
            //   action: () async {
            //     context.go("/thank_you");
            //   },
            //   label: Text(
            //     "Mark as delivered.",
            //     style: Theme.of(context)
            //         .textTheme
            //         .bodyLarge!
            //         .copyWith(color: Colors.white),
            //   ),
            //   radius: 0.0,
            //   baseColor: AppColors.backgroundColor,
            //   backgroundColor: AppColors.primaryColor,
            //   icon: Row(
            //     mainAxisAlignment: MainAxisAlignment.center,
            //     children: [
            //       Icon(
            //         Icons.arrow_forward_ios,
            //         color: Colors.red,
            //         size: 30.sp,
            //       ),
            //       Icon(
            //         Icons.arrow_forward_ios,
            //         color: Colors.red,
            //         size: 30.sp,
            //       ),
            //     ],
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
