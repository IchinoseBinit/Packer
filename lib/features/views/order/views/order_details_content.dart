import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/widgets/order_progress_card.dart';
import 'package:provider/provider.dart';

import '/constants/app_constants.dart';
import '/constants/navigation_constants.dart';
import '/controllers/services/navigate.dart';
import '/enum/order_status_type.dart';
import '/features/views/auth/provider/home_provider.dart';
import '/features/views/order/provider/order_provider.dart';
import '/features/views/order/widgets/cart_items_list.dart';
import '/features/views/widgets/custom_loading_indicator.dart';
import '/features/views/widgets/general_elevated_button.dart';
import '/features/views/widgets/order_info_card.dart';

class OrderDetailsContent extends StatefulWidget {
  final OrderDetailModel order;

  const OrderDetailsContent({
    super.key,
    required this.order,
  });

  @override
  State<OrderDetailsContent> createState() => _OrderDetailsContentState();
}

class _OrderDetailsContentState extends State<OrderDetailsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).resetPackedTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final status = widget.order.data.status;

    return Padding(
      padding: AppConstants.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrderInfoCard(data: widget.order),
          SizedBox(
            height: 8.h,
          ),
          PackingProgressWidget(
            totalItems: widget.order.data.count,
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Items Ordered:",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
              child: CartItemsList(cartItems: widget.order.productDetails)),
          SizedBox(
            height: 8.h,
          ),
          (status != OrderStatusType.completed &&
                  status != OrderStatusType.cancelled &&
                  orderProvider.allCartItemScanned())
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ).copyWith(
                    bottom: MediaQuery.of(context).padding.bottom + 20.h,
                  ),
                  child: GeneralElevatedButton(
                    onPressed: () async {
                      showLoading(context);

                      final parsedOrderId =
                          int.tryParse(widget.order.data.id.toString()) ?? 0;

                      final success = await Provider.of<OrderProvider>(
                        context,
                        listen: false,
                      ).productPost(context, parsedOrderId);

                      if (!mounted) return;

                      removeLoading(context);

                      if (success) {
                        Provider.of<HomeProvider>(context, listen: false)
                            .fetchLatestOrders();

                        navigateAndRemoveAll(
                          context,
                          route: NavigationConstants.dashboardRoute,
                        );
                      }
                    },

                    // },
                    title: 'Bill this order',
                  ),
                )
              : Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: GeneralElevatedButton(
                    onPressed: () {},
                    title: 'Scan all items',
                  ),
                ),
        ],
      ),
    );
  }
}
