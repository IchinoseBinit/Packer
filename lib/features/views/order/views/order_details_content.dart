import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
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
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final status = widget.order.data.status;
    final showButton = orderProvider.showButton;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: AppConstants.padding,
            children: [
              OrderInfoCard(data: widget.order),
              CartItemsList(cartItems: widget.order.productDetails),
              SizedBox(
                height: 8.h,
              ),
            ],
          ),
        ),
        (status != OrderStatusType.completed &&
                status != OrderStatusType.cancelled &&
                showButton)
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

                    Provider.of<OrderProvider>(context, listen: false)
                        .productPost(
                      parsedOrderId,
                    )
                        .then((value) {
                      removeLoading(context);
                      try {
                        Provider.of<OrderProvider>(context, listen: false)
                            .clearBasket();
                      } catch (ex) {
                        debugPrint(ex.toString());
                      }

                      Provider.of<HomeProvider>(context, listen: false)
                          .fetchLatestOrders();
                      navigateAndRemoveAll(context,
                          route: NavigationConstants.dashboardRoute);
                    });
                  },
                  title: 'Bill this order',
                ),
              )
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: GeneralElevatedButton(
                  onPressed: () {},
                  title: 'Scan all items',
                ),
              ),
      ],
    );
  }
}
