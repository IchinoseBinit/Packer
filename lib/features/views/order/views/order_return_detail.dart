import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/low_stock/views/trolley_item_screen.dart';
import 'package:packer/features/views/profile/provider/order_return_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class OrderReturnDetail extends StatefulWidget {
  const OrderReturnDetail({super.key});

  @override
  State<OrderReturnDetail> createState() => _OrderReturnDetailState();
}

class _OrderReturnDetailState extends State<OrderReturnDetail> {
  @override
  Widget build(BuildContext context) {
    OrderReturnProvider orderReturnProvider =
        Provider.of<OrderReturnProvider>(context, listen: false);
    return Scaffold(
      appBar: const GeneralAppBar(
        middleWidget: Text("Order Return"),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsetsGeometry.all(8.r),
        child: orderReturnProvider.isCompleted
            ? GeneralElevatedButton(
                onPressed: () async {
                  final result =
                      await orderReturnProvider.postOrderReturn(context);
                  if (result.success) {
                    showToast("Order returned successfully");
                    navigateAndRemoveAll(context,
                        route: NavigationConstants.dashboardRoute);
                  } else {
                    if (result.message != null) {
                      ErrorHandler.alertDialog(context, result.message ?? '');
                    }
                  }
                },
                title: 'Return this order',
              )
            : GeneralElevatedButton(
                onPressed: () {},
                title: 'Scan all items',
              ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: OrderReturnInfoCard()),
            // 12.h
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),
            SliverPadding(
              padding: EdgeInsets.all(8.0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "Items Ordered:",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // 12.h
            SliverToBoxAdapter(child: SizedBox(height: 12.h)),

            for (final rackName in orderReturnProvider.rackNames) ...[
              //
              SliverPadding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8.h),
                sliver: SliverToBoxAdapter(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                            text: "Rack Name: ",
                            style: Theme.of(context).textTheme.labelLarge),
                        TextSpan(
                          text: rackName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontSize: 16.sp,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              //
              SliverPadding(
                padding: EdgeInsetsGeometry.symmetric(horizontal: 8.h),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180.w,
                    crossAxisSpacing: 8.w,
                    childAspectRatio: 0.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final orderItem = orderReturnProvider
                          .rackToOrderItems[rackName]![index];

                      return TrolleyItemWidget(
                        id: orderItem.productId,
                        name: orderItem.productName,
                        image: orderItem.imageUrl,
                        qty: orderItem.unitTags.length,
                        measurement:
                            "${orderItem.size} ${orderItem.measurement}",
                        isCompleted: orderReturnProvider
                            .isItemCompleted(orderItem.productId),
                        onTap: () {
                          if (orderReturnProvider
                              .isItemCompleted(orderItem.productId)) {
                            return;
                          }
                          Provider.of<OrderReturnProvider>(context,
                                  listen: false)
                              .initScannedTagsList();
                          navigate(context,
                              route:
                                  NavigationConstants.orderReturnScannerRoute,
                              extra: {
                                "productId": orderItem.productId,
                                "rack": true
                              });
                        },
                      );
                    },
                    childCount: orderReturnProvider
                            .rackToOrderItems[rackName]?.length ??
                        0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OrderReturnInfoCard extends StatelessWidget {
  const OrderReturnInfoCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider =
        Provider.of<OrderReturnProvider>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0.h),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Order ID + Status Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order ID: ${orderProvider.selectedOrder?.orderId}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: orderProvider.isCompleted
                              ? AppColors.green700
                              : AppColors.orderDetailColor,
                          borderRadius: BorderRadius.circular(4.h),
                        ),
                        child: Text(
                          orderProvider.isCompleted
                              ? "Completed"
                              : "In Progress",
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: orderProvider.isCompleted
                                        ? Colors.black
                                        : AppColors.orderDetailFontColor,
                                  ),
                        ),
                      )
                    ],
                  ),

                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'Product Count: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        "${orderProvider.selectedOrder?.orderItems.length}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                      )
                    ],
                  ),

                  /// Basket Line (if available)

                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        'Basket: ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        orderProvider.baskets.firstOrNull?.identifier ?? "",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
