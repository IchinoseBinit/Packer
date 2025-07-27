import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class TrolleyItemScreen extends StatelessWidget {
  const TrolleyItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trolley Item Screen"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<StockProvider>(
            builder: (context, state, child) {
              if (state.trolleyItems.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () {
                  ShowAlertDialog(
                      title: "Do you want to scan a new Basket?",
                      okFunc: () {
                        navigatePop(context);
                        navigate(context,
                            route: NavigationConstants.lowStockScannerRoute,
                            extra: {"changeBasket": true});
                      },
                      needCancel: true,
                      cancelTitle: "Cancel",
                      cancelFunc: () {
                        navigatePop(context);
                      }).showAlertDialog(context);
                },
                icon: Icon(
                  Icons.shopping_bag,
                  color: AppColors.splashNewBackgroundColor,
                ),
              );
            },
          )
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, state, child) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Column(
              children: [
                LowStockCard(
                  model: state.trolleyLowStockModel!,
                  basketId: state.basketId,
                  primaryColor: Theme.of(context).primaryColor,
                  count: state.trolleyItems.length,
                ),
                // 12.h
                SizedBox(height: 12.h),

                Expanded(
                  child: state.trolleyItems.isEmpty
                      ? const Center(child: Text("No items in trolley"))
                      : IntrinsicGridView.vertical(
                          columnCount: 2,
                          verticalSpace: 12.w,
                          horizontalSpace: 12.w,
                          children: [
                              ...state.trolleyItems.map((product) {
                                final width = (1.sw - 12.w - 32.w) / 2;
                                return TrolleyItemWidget(
                                  id: product.productId,
                                  name: product.productName,
                                  image: product.image,
                                  width: width,
                                  qty: product.quantity,
                                  onTap: () {
                                    print('Trolley item tapped');
                                    // trolleyItemScannerRoute

                                    navigate(context,
                                        route: NavigationConstants
                                            .trolleyItemScannerRoute,
                                        extra: product.productId);
                                  },
                                );
                              })
                            ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TrolleyItemWidget extends StatelessWidget {
  final int id;
  final String name;
  final String image;
  final int qty;
  final double width;
  final String? measurement;
  final VoidCallback? onTap;
  final bool isCompleted;

  const TrolleyItemWidget({
    super.key,
    required this.id,
    required this.name,
    required this.image,
    required this.qty,
    this.width = 140,
    this.measurement,
    this.onTap,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        width: width,
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.productCardBorderColor),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                SizedBox(height: 4.h),
                AspectRatio(
                  aspectRatio: 0.9,
                  child: ClipRRect(
                    child: Stack(
                      children: [
                        image.isNotEmpty
                            ? Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: CachedNetworkImage(
                                    imageUrl: image,
                                    width: width,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, error, stackTrace) =>
                                        const Center(
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                    placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator
                                            .adaptive()),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                Icons.image_not_supported,
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Product Name
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                          color: Colors.black,
                        ),
                  ),

                  SizedBox(height: 6.h),

                  /// Quantity
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Qty: $qty',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.homeScreenDimTextColor,
                                  ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          measurement ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.homeScreenDimTextColor,
                                  ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.h),
                      color: isCompleted
                          ? AppColors.green700
                          : AppColors.primaryColor,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isCompleted ? "Completed" : "Remaining: $qty",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
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
