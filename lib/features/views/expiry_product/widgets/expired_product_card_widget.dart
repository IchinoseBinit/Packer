import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/expiry_product/models/expiry_product_model.dart';

class ExpiredProductCardWidget extends StatelessWidget {
  const ExpiredProductCardWidget({
    super.key,
    required this.item,
  });

  final Results item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => navigate(
        context,
        route: NavigationConstants.basketScanScreenRoute,
        extra: {
          'forTransfer': true,
          'forExpiredProducts': true,
        },
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
            color: AppColors.backgroundColor,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Rack Name :",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600, fontSize: 12.sp)),
                SizedBox(width: 4.w),
                Text(item.rackName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              margin: EdgeInsets.only(bottom: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: AppColors.cartTextColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Product ID: #${item.productId}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w800),
                      ),
                      Text(
                        "Total Units: ${item.totalUnits}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
