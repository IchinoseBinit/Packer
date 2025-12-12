import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.model,
    required this.status,
    this.quantity = 1,
  });

  final ProductModel model;
  final ItemStatus status;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final isComplete = status == ItemStatus.done;
    final backgroundColor =
        isComplete ? AppColors.green700 : Colors.transparent;

    final borderColor =
        isComplete ? AppColors.green700 : const Color(0xffEAEAEA);

    final text1Color = isComplete ? AppColors.backgroundColor : Colors.black;

    final text2Color =
        isComplete ? AppColors.backgroundColor : const Color(0xFF7D7C7C);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(
          width: 1.5,
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            height: 60.h,
            width: 60.h,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: model.imageUrl.isNotEmpty
                  ? Image.network(
                      "${AppUrls.imageUrl}${model.imageUrl}",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: .3.sw,
                child: Text(
                  model.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: text1Color,
                      ),
                  textAlign: TextAlign.start,
                ),
              ),
              Text(
                "Quantity: ${model.quantity}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: text2Color,
                    ),
              ),
              Text(
                "${model.size} ${model.measurement}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: text2Color,
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (status == ItemStatus.done)
            Text(
              "Done",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: text1Color,
              ),
            ),
          if (status == ItemStatus.remaining) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              height: 42.h,
              width: 2.w,
              color: Colors.grey, // Set divider color based on status
            ),
            Text(
              "Remaining: $quantity",
              style: TextStyle(
                fontSize: 10.sp,
                color: text1Color, // Set text color based on status
              ),
            ),
          ],
        ],
      ),
    );
  }
}
