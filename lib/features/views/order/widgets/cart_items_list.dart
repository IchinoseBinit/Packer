import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/models/cart_item.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';

class CartItemsList extends StatelessWidget {
  final List<ProductDetails> cartItems;

  const CartItemsList({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text("Items Ordered:"),
        ),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: cartItems.length,
          itemBuilder: (context, cartIndex) {
            final cartItem = cartItems[cartIndex];
            return InkWell(
              highlightColor: Colors.transparent,
              onTap: () {
                log("Navigating to QR Scan Screen for ${cartItem.productName} and item id: ${cartItem.id}");
                if (cartItem.itemScanCount == cartItem.quantity) {
                  return;
                }
                navigate(context,
                    route: NavigationConstants.productqrScreenRoute,
                    extra: {
                      "forCartitem": true,
                      "productId": cartItem.id,
                    });
              },
              child: ItemWidget(
                productItems: cartItem,
                status: cartItem.itemScanCount == cartItem.quantity
                    ? ItemStatus.done
                    : ItemStatus.remaining,
              ),
            );
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: 12);
          },
        ),
      ],
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.productItems,
    required this.status, // Add a status parameter
  });

  final ProductDetails productItems;
  final ItemStatus status; // Enum to define the status

  @override
  Widget build(BuildContext context) {
    // Determine the colors based on the status
    final backgroundColor = status == ItemStatus.done
        ? AppColors.green700 // Green border for "Done"
        : Colors.transparent; // Light blue background for "Remaining"

    final borderColor = status == ItemStatus.done
        ? AppColors.green700 // Green border for "Done"
        : Color(0xffEAEAEA); // Blue border for "Remaining"

    final text1Color = status == ItemStatus.done
        ? AppColors.backgroundColor // Green text for "Done"
        : Colors.black; // Blue text for "Remaining"

    final text2Color = status == ItemStatus.done
        ? AppColors.backgroundColor // Green text for "Done"
        : const Color(0xFF7D7C7C); // Blue text for "Remaining"

    final dividerColor = status == ItemStatus.done
        ? AppColors.backgroundColor // Green divider for "Done"
        : Colors.black; // Light blue divider for "Remaining"

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor, // Set background color based on status
        border: Border.all(
          width: 1.5,
          color: borderColor, // Set border color based on status
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
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
                  child: productItems.imageUrl.isNotEmpty
                      ? Image.network(
                          "http://13.211.205.215:8000${productItems.imageUrl}",
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
                      productItems.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: text1Color, // Set text color based on status
                          ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Text(
                    "${productItems.size} ${productItems.measurement}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: text2Color, // Set text color based on status
                        ),
                  ),
                  Text(
                    "${productItems.id} ",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: text2Color, // Set text color based on status
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Qty: ${productItems.quantity}",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: text1Color, // Set text color based on status
                    ),
                  ),
                  SizedBox(
                    height: 4.h,
                  ),
                  // Text(
                  //   productItems.productCompartment,
                  //   style: TextStyle(
                  //     fontSize: 12.sp,
                  //     fontWeight: FontWeight.bold,
                  //     color: text1Color, // Set text color based on status
                  //   ),
                  // ),
                ],
              ),
              if (status == ItemStatus.remaining) ...[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  height: 42.h,
                  width: 2.w,
                  color: dividerColor, // Set divider color based on status
                ),
                Text(
                  "Remaining: ${productItems.quantity - productItems.itemScanCount}",
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: text1Color, // Set text color based on status
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Define an enum for the status
enum ItemStatus {
  done,
  remaining,
}
