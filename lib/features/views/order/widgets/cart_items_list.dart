import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:provider/provider.dart';

class CartItemsList extends StatelessWidget {
  final List<ProductDetails> cartItems;

  const CartItemsList({super.key, required this.cartItems});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, state, child) {
        return CustomScrollView(
          slivers: [
            for (final rack in state.rackList) ...[
              SliverToBoxAdapter(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "Rack Name: ",
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      TextSpan(
                        text: rack,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: 8.h)),
              //
              if (state.rackProductData[rack] != null)
                SliverPadding(
                  padding: EdgeInsetsGeometry.symmetric(horizontal: 8.h),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180.w,
                      crossAxisSpacing: 8.w,
                      childAspectRatio: 0.4,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = state.rackProductData[rack]![index];
                        final isDone = state.checkItem(product.id);
                        final width = (1.sw - 12.w - 32.w) / 2;

                        return ProductCard(
                          width: width,
                          onTap: () {
                            log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.id}");
                            if (isDone) return;

                            navigate(
                              context,
                              route:
                                  NavigationConstants.cartItemScanScreenRoute,
                              extra: {
                                'productId': product.id,
                              },
                            );
                          },
                          productModel:
                              CommonProductModel.fromProductDetails(product),
                          quantity: (product.quantity ?? 0) -
                              state.countScannedItem(product.id),
                          status:
                              isDone ? ItemStatus.done : ItemStatus.remaining,
                        );
                      },
                      childCount: state.rackProductData[rack]?.length ?? 0,
                    ),
                  ),
                ),
            ],
            // ListView.separated(
            //   shrinkWrap: true,
            //   itemCount: state.rackList.length,
            //   itemBuilder: (context, index) {
            //     final rack = state.rackList[index];

            //     return Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         RichText(
            //           text: TextSpan(
            //             children: [
            //               TextSpan(
            //                 text: "Rack Name: ",
            //                 style: Theme.of(context)
            //                     .textTheme
            //                     .labelLarge
            //                     ?.copyWith(
            //                       fontSize: 12.sp,
            //                       fontWeight: FontWeight.w500,
            //                     ),
            //               ),
            //               TextSpan(
            //                 text: rack,
            //                 style: Theme.of(context)
            //                     .textTheme
            //                     .headlineSmall
            //                     ?.copyWith(
            //                         fontSize: 16.sp,
            //                         fontWeight: FontWeight.w600),
            //               ),
            //             ],
            //           ),
            //         ),
            //         SizedBox(height: 8.h),
            //         if (state.rackProductData[rack] != null)
            //           IntrinsicGridView.vertical(
            //             columnCount: 2,
            //             verticalSpace: 12.w,
            //             horizontalSpace: 12.w,
            //             children: List.generate(
            //               state.rackProductData[rack]!.length,
            //               (index) {
            //                 final product = state.rackProductData[rack]![index];
            //                 final isDone = state.checkItem(product.id);
            //                 final width = (1.sw - 12.w - 32.w) / 2;

            //                 return ProductCard(
            //                   width: width,
            //                   onTap: () {
            //                     log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.id}");
            //                     if (isDone) return;

            //                     navigate(
            //                       context,
            //                       route: NavigationConstants
            //                           .cartItemScanScreenRoute,
            //                       extra: {
            //                         'productId': product.id,
            //                       },
            //                     );
            //                   },
            //                   productModel:
            //                       CommonProductModel.fromProductDetails(
            //                           product),
            //                   quantity: (product.quantity ?? 0) -
            //                       state.countScannedItem(product.id),
            //                   status: isDone
            //                       ? ItemStatus.done
            //                       : ItemStatus.remaining,
            //                 );
            //               },
            //             ),
            //           )
            //       ],
            //     );
            //   },
            //   separatorBuilder: (context, index) => const SizedBox(height: 12),
            // ),
            //
          ],
        );
      },
    );
  }
}

class ItemWidget extends StatefulWidget {
  const ItemWidget({
    super.key,
    required this.productItems,
    required this.status,
  });

  final ProductDetails productItems;
  final ItemStatus status;

  @override
  State<ItemWidget> createState() => _ItemWidgetState();
}

class _ItemWidgetState extends State<ItemWidget> {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.status == ItemStatus.done
        ? AppColors.green700
        : Colors.transparent;
    final borderColor = widget.status == ItemStatus.done
        ? AppColors.green700
        : const Color(0xffEAEAEA);
    final text1Color = widget.status == ItemStatus.done
        ? AppColors.backgroundColor
        : Colors.black;
    final text2Color = widget.status == ItemStatus.done
        ? AppColors.backgroundColor
        : const Color(0xFF7D7C7C);
    final dividerColor = widget.status == ItemStatus.done
        ? AppColors.backgroundColor
        : Colors.black;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(width: 1.5, color: borderColor),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                height: 60.h,
                width: 60.h,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.productItems.imageUrl.isNotEmpty
                      ? Image.network(
                          "${AppUrls.imageUrl}${widget.productItems.imageUrl}",
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported),
                        )
                      : const Icon(Icons.image_not_supported),
                ),
              ),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 0.3.sw,
                    child: Text(
                      widget.productItems.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: text1Color,
                          ),
                    ),
                  ),
                  Text(
                    "${widget.productItems.size} ${widget.productItems.measurement}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: text2Color,
                        ),
                  ),
                  if (widget.productItems.rackName.isNotEmpty)
                    SizedBox(
                      width: 0.3.sw,
                      child: Text(
                        widget.productItems.rackName,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: text1Color,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    )
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Qty: ${widget.productItems.quantity}",
                    style: TextStyle(fontSize: 16.sp, color: text1Color),
                  ),
                  SizedBox(height: 4.h),
                ],
              ),
              if (widget.status == ItemStatus.remaining) ...[
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  height: 42.h,
                  width: 2.w,
                  color: dividerColor,
                ),
                Text(
                  "Remaining: ${widget.productItems.quantity! - widget.productItems.itemScanCount}",
                  style: TextStyle(fontSize: 10.sp, color: text1Color),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

enum ItemStatus {
  done,
  remaining,
}
