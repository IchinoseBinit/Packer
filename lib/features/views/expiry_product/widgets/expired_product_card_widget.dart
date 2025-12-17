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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Rack Name: "),
              SizedBox(width: 4.w),
              Text(item.rackName ?? 'N/A',
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
              // boxShadow: [
              //   BoxShadow(
              //     color: Colors.black.withOpacity(0.9),
              //     spreadRadius: 1,
              //     blurRadius: 4,
              //     offset: const Offset(0, 2),
              //   ),
              // ],
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
              ],
            ),
          ),
        ],
      ),
      //    Card(
      //   margin: const EdgeInsets.only(bottom: 24),
      //   shape: RoundedRectangleBorder(
      //     borderRadius: BorderRadius.circular(16.0),
      //     side: BorderSide(
      //       color: Theme.of(context).primaryColor.withOpacity(0.5),
      //       width: 1,
      //     ),
      //   ),
      //   elevation: 3,
      //   child: Padding(
      //     padding: const EdgeInsets.all(16.0),
      //     child: Column(
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         Row(
      //           children: [
      //             CircleAvatar(
      //               backgroundColor: Theme.of(context).primaryColor,
      //               child: const Icon(Icons.near_me, color: Colors.white),
      //             ),
      //             SizedBox(width: 10.w),
      //             Expanded(
      //               child: Column(
      //                 crossAxisAlignment: CrossAxisAlignment.start,
      //                 children: [
      //                   Text(
      //                     item.productName,
      //                     style: Theme.of(context).textTheme.bodyLarge,
      //                   ),

      //                   if (basketId != null) ...[
      //                     Text(
      //                       'Basket ID: $basketId',
      //                       style: Theme.of(context)
      //                           .textTheme
      //                           .bodyMedium
      //                           ?.copyWith(color: Colors.grey[700]),
      //                     ),
      //                   ],
      //                 ],
      //               ),
      //             ),
      //           ],
      //         ),
      //         if (callback != null) ...[
      //           SizedBox(height: 12.h),
      //           const Divider(),
      //           SizedBox(height: 12.h),
      //           Align(
      //             alignment: Alignment.centerRight,
      //             child: InkWell(
      //               onTap: () {
      //                 callback?.call();
      //               },
      //               child: Container(
      //                 decoration: BoxDecoration(
      //                   color: primaryColor,
      //                   borderRadius: BorderRadius.circular(10),
      //                 ),
      //                 padding:
      //                     EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      //                 child: Text(
      //                   'Details',
      //                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
      //                         color: Colors.white,
      //                       ),
      //                 ),
      //               ),
      //             ),
      //           ),
      //         ]
      //       ],
      //     ),
      //   ),
      // );
    );
  }
}
