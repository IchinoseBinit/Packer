import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '/constants/app_constants.dart';
import '/constants/navigation_constants.dart';
import '/controllers/services/navigate.dart';
import '/controllers/services/show_toast_message.dart';
import '/enum/order_status_type.dart';
import '/features/views/auth/provider/home_provider.dart';
import '/features/views/order/models/fetch_order_details.dart';
import '/features/views/order/provider/order_provider.dart';
import '/features/views/order/widgets/cart_items_list.dart';
import '/features/views/widgets/custom_loading_indicator.dart';
import '/features/views/widgets/general_elevated_button.dart';
import '/features/views/widgets/order_info_card.dart';

class OrderDetailsContent extends StatelessWidget {
  final String orderId;

  const OrderDetailsContent({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final OrderDetailsFetch? orderDetails = orderProvider.orderDetails;

    if (orderDetails == null) {
      return const Center(child: Text('Cannot fetch data'));
    }

    return ListView(
      padding: AppConstants.padding,
      children: [
        OrderInfoCard(data: orderDetails),
        CartItemsList(cartItems: orderDetails.cartItems),
        SizedBox(
          height: 8.h,
        ),
        if (orderDetails.status != OrderStatusType.completed &&
            orderDetails.status != OrderStatusType.cancelled)
          GeneralElevatedButton(
            onPressed: () {
              showLoading(context);
              // TODO: Bill order
              Provider.of<OrderProvider>(context, listen: false)
                  .billOrder(orderId)
                  .then((value) {
                removeLoading(context);

                Provider.of<HomeProvider>(context, listen: false)
                    .fetchLatestOrders();
                if (value is bool) {
                  navigateAndRemoveAll(context,
                      route: NavigationConstants.dashboardRoute);
                } else {
                  showToast(value.toString());
                }
              });
            },
            title: 'Bill this order',
          ),
      ],
    );
  }
}
