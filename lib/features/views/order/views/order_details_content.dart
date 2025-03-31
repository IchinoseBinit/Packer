import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
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

class OrderDetailsContent extends StatefulWidget {
  final String orderId;

  const OrderDetailsContent({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsContent> createState() => _OrderDetailsContentState();
}

class _OrderDetailsContentState extends State<OrderDetailsContent> {
  @override
  void initState() {
    super.initState();
    Provider.of<OrderProvider>(context, listen: false).initState();
  }

  @override
  Widget build(BuildContext context) {
    final bucketData = Provider.of<OrderProvider>(context).bucketData;
    final orderProvider = Provider.of<OrderProvider>(context);
    final OrderDetailModel? orderDetails = orderProvider.orderDetails;
    final status = orderDetails?.data.status ?? "";

    if (orderDetails == null) {
      return const Center(child: Text('Cannot fetch data'));
    }

    return ListView(
      padding: AppConstants.padding,
      children: [
        OrderInfoCard(data: orderDetails),
        CartItemsList(cartItems: orderDetails.productDetails),
        SizedBox(
          height: 8.h,
        ),
        if (status != OrderStatusType.completed &&
            status != OrderStatusType.cancelled)
          GeneralElevatedButton(
            onPressed: () async {
              showLoading(context);

              final parsedOrderId = int.tryParse(widget.orderId) ?? 0;

              Provider.of<OrderProvider>(context, listen: false)
                  .productPost(
                parsedOrderId,
              )
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
