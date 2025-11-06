import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

class PackingProgressWidget extends StatefulWidget {
  final int totalItems;

  const PackingProgressWidget({super.key, required this.totalItems});

  @override
  State<PackingProgressWidget> createState() => _PackingProgressWidgetState();
}

class _PackingProgressWidgetState extends State<PackingProgressWidget> {
  @override
  Widget build(BuildContext context) {
    final packedItems = context.watch<OrderProvider>().packedCount;
    final progress =
        widget.totalItems > 0 ? packedItems / widget.totalItems : 0.0;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: AppColors.progressContainerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Top Row: Title and Packed Count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Packing Progress",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                "$packedItems of ${widget.totalItems}",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          /// Sub Text
          Text(
            "Items packed",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.sp,
            ),
          ),

          SizedBox(height: 8.h),

          /// Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 15,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),

          /// Percentage Text
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(right: 8.w, top: 4.h, bottom: 4.h),
              child: Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
