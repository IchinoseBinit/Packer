import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/model/order_notification.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

class NotificationOrderCard extends StatelessWidget {
  final OrderNotification orderItem;
  final Color primaryColor;
  final VoidCallback callback;

  const NotificationOrderCard({
    super.key,
    required this.orderItem,
    required this.primaryColor,
    required this.callback,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.shopping_cart, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: orderItem.customerName,
                          style: Theme.of(context).textTheme.bodyLarge,
                          children: [
                            TextSpan(
                              text:
                                  " (${orderItem.status.toStringConversion()})",
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          ],
                        ),
                      ),
                      Text(
                        'Order ID: ${orderItem.orderId}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            const Divider(),
            SizedBox(height: 12.h),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () async {
                  final result = await navigate(context,
                      route: NavigationConstants.basketScanScreenRoute,
                      extra: {
                        'forOrder': true,
                      });
                  log("result from basket scan screen $result",
                      name: "Order Detials");
                  if ((result ?? false) && context.mounted) {
                    navigate(context,
                        route: NavigationConstants.orderDetailsRoute,
                        extra: orderItem.orderId);
                    Provider.of<OrderProvider>(context, listen: false)
                        .initState();
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Text(
                    'Details',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
