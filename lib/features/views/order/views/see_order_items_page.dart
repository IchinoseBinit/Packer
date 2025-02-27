import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/controllers/extensions/num_extension.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/models/cart_item.dart';
import 'package:packer/features/views/order/models/fetch_order_details.dart';
import 'package:packer/features/views/order/models/order_picked_details.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/order/views/order_details_content.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class SeeOrderedItemsPage extends StatelessWidget {
  const SeeOrderedItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final OrderDetailsFetch? orderDetails = orderProvider.orderDetails;
    final OrderPickedDetails? orderPickedDetails =
        orderProvider.orderPickedDetails;

    if (orderDetails == null && orderPickedDetails == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Order ID: ${orderPickedDetails?.id ?? orderDetails?.id}"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          CartItemsList(
              cartItems:
                  orderPickedDetails?.cartItems ?? orderDetails!.cartItems),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: AppConstants.bottomNavBarButtonPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('To Receive:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Rs. ${(orderPickedDetails?.total ?? orderDetails?.total ?? 0).toIntStringConversion()}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 20.sp,
                      ),
                ),
              ],
            ),
            SizedBox(
              height: 12.h,
            ),
            GeneralElevatedButton(
              title: "Back",
              onPressed: () => navigatePop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderedItemCard extends StatelessWidget {
  const OrderedItemCard({super.key, required this.orderedItem});

  final CartItem orderedItem;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.w),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.w),
                image: DecorationImage(
                  image:
                      NetworkImage(AppUrls.imageUrl + orderedItem.productImage),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: .3.sw,
                    child: Text(
                      orderedItem.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "${orderedItem.size} ${orderedItem.measurement}",
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              "Qty: ${orderedItem.quantity}",
              style: TextStyle(
                fontSize: 16.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
