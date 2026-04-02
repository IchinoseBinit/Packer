import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/widgets/order_progress_card.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

import '/constants/app_constants.dart';
import '/constants/navigation_constants.dart';
import '/controllers/services/navigate.dart';
import '/enum/order_status_type.dart';
import '/features/views/auth/provider/home_provider.dart';
import '/features/views/order/provider/order_provider.dart';
import '/features/views/order/widgets/cart_items_list.dart';
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

  // dialog for order cancelled
  void showOrderCancelledDialog(BuildContext context) {
    ShowAlertDialog(
      title: 'Order Cancelled',
      body: Text(
        'This order has been cancelled by the customer. Do you want to proceed with returning the items to inventory?',
      ),
      disableBackground: true,
      okTitle: "Yes, Proceed",
      okFunc: () {
        navigatePop(context);

        navigateReplacement(
          context,
          route: NavigationConstants.orderReturnScreenRoute,
        );
      },
      needCancel: false,
      // cancelFunc: () {
      //   navigatePop(context);
      //   navigateAndRemoveAll(
      //     context,
      //     route: NavigationConstants.dashboardRoute,
      //   );
      // },
    ).showAlertDialog(context);
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
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: PackingProgressWidget(
                      totalItems: widget.order.data.count)),
              //  show icon or something if ice pack is required
              if (orderProvider.hasRequiredIcePacks())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16.r),
                    onTap: () {
                      navigate(
                        context,
                        route: NavigationConstants.icePackScanScreenRoute,
                      );
                    },
                    child: Badge(
                      label: Text(
                        context
                            .watch<OrderProvider>()
                            .countScannedIcePacks()
                            .toString(),
                      ),
                      child: Container(
                        height: 120.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.r),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF6DD5FA), // light icy blue
                              Color(0xFF2980B9), // deeper blue
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: Offset(0, 6),
                            )
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -10,
                              bottom: -10,
                              child: Icon(
                                Icons.ac_unit,
                                size: 90.sp,
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            Positioned(
                              right: 12.w,
                              top: 20.h,
                              child: Container(
                                padding: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12.w, vertical: 10.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 26.sp,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Scan Ice-Pack",
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    "Quickly scan",
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
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
          SizedBox(height: 8.h),
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
                      await orderProvider.removeBasketIdentifier(
                        widget.order.data.id,
                      );
                      await orderProvider.refreshBaskets(widget.order.data.id);
                      final parsedOrderId =
                          int.tryParse(widget.order.data.id.toString()) ?? 0;

                      final response = await Provider.of<OrderProvider>(
                        context,
                        listen: false,
                      ).productPost(context, parsedOrderId);

                      if (response['success'].toString().toBool(false) &&
                          mounted) {
                        Provider.of<HomeProvider>(context, listen: false)
                            .fetchLatestOrders();

                        if (response['isCancelRequest']
                            .toString()
                            .toBool(false)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            showOrderCancelledDialog(context);
                          });
                        } else {
                          navigateAndRemoveAll(
                            context,
                            route: NavigationConstants.dashboardRoute,
                          );
                        }
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
