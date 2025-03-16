// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:provider/provider.dart';

import '/constants/app_constants.dart';
import '/constants/navigation_constants.dart';
import '/controllers/services/navigate.dart';
import '/controllers/services/show_toast_message.dart';
import '/enum/order_status_type.dart';
import '/features/views/auth/provider/home_provider.dart';
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
    //  required order,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<HomeProvider>(context);
    final OrderDetailModel? orderDetails = Provider.of<HomeProvider>(context).orderDetailModel;

    if (orderDetails == null) {
      return const Center(child: Text('Cannot fetch data'));
    }

    return ListView(
      padding: AppConstants.padding,
      children: [
        OrderInfoCard(data: orderDetails),
        CartItemsList(orderDetailModel: orderDetails),
        SizedBox(
          height: 8.h,
        ),
        if (orderDetails.data!.status != OrderStatusType.completed &&
            orderDetails.data!.status != OrderStatusType.cancelled)
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
