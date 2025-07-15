// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';

import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';

class LowStockDetails extends StatefulWidget {
  const LowStockDetails({
    super.key,
  });

  @override
  State<LowStockDetails> createState() => _LowStockDetailsState();
}

class _LowStockDetailsState extends State<LowStockDetails> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Handle the pop event
        Provider.of<StockProvider>(context, listen: false).reset();
        navigatePop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Low Stock Details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Provider.of<StockProvider>(context, listen: false).reset();
              navigatePop(context);
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                ShowAlertDialog(
                    title: "Do you want to scan a new Basket?",
                    okFunc: () {
                      navigate(context,
                          route: NavigationConstants.lowStockScannerRoute);
                    },
                    needCancel: true,
                    cancelTitle: "Cancel",
                    cancelFunc: () {
                      navigatePop(context);
                    }).showAlertDialog(context);
              },
              icon: Icon(
                Icons.shopping_cart,
                color: AppColors.splashNewBackgroundColor,
              ),
            ),
          ],
        ),
        body: Consumer<StockProvider>(
          builder: (context, state, child) {
            final model = state.selectedModel ?? LowStockModel();
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LowStockCard(
                      model: model,
                      basketId: state.basketId,
                      primaryColor: Theme.of(context).primaryColor,
                    ),
                    // 20.h
                    SizedBox(height: 20.h),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () {
                          return Provider.of<StockProvider>(context,
                                  listen: false)
                              .fetchLowStockProducts(context);
                        },
                        child: ListView.builder(
                          itemCount: state.rackNameList.length,
                          itemBuilder: (context, index) {
                            final rackName = state.rackNameList[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                    text: TextSpan(children: [
                                  TextSpan(
                                      text: "Rack Name: ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
                                  TextSpan(
                                      text: rackName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontSize: 16.sp,
                                          )),
                                ])),
                                // 8.h
                                SizedBox(height: 8.h),
                                if (state.rackProductMap[rackName] != null)
                                IntrinsicGridView.vertical(
                                  columnCount: 2,
                                  verticalSpace: 12.w,
                                  horizontalSpace: 12.w,
                                  children: [
                                  ...state.rackProductMap[rackName]!.map(
                                    (product) { 
                                      final width = (1.sw - 12.w - 32.w) / 2;
                                      return ProductCard(
                                      width: width,
                                      onTap: () {
                                        if (state.checkScanCount(
                                            product.productId)) {
                                          return;
                                        }
                                        ErrorHandler.alertDialog(
                                            context, "Scan Carton First");
                                      },
                                      productModel:
                                          CommonProductModel.fromProductModel(
                                              product),
                                      status: state
                                              .checkScanCount(product.productId)
                                          ? ItemStatus.done
                                          : ItemStatus.remaining,
                                      quantity:
                                          state.getScanCount(product.productId),
                                    );},
                                  ),
                                  ]),

                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    // 20.h
                    SizedBox(height: 20.h),
                    state.showCompleteButton()
                        ? GeneralElevatedButton(
                            onPressed: () {
                              // debugger();

                              state.transferBasket(context);
                            },
                            title: "Complete",
                          )
                        : GeneralElevatedButton(
                            title: "Scan Carton",
                            onPressed: () {
                              navigate(
                                context,
                                route: NavigationConstants.qrScanScreenRoute,
                                extra: {
                                  'scanCarton': true,
                                  'isLowStockCarton': true,
                                },
                              );
                            }),
                    // 20.h
                    SizedBox(height: 8.h),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.model,
    required this.status,
    this.quantity = 1,
  });

  final ProductModel model;
  final ItemStatus status;
  final int quantity;

  @override
  Widget build(BuildContext context) {
    final isComplete = status == ItemStatus.done;
    final backgroundColor =
        isComplete ? AppColors.green700 : Colors.transparent;

    final borderColor =
        isComplete ? AppColors.green700 : const Color(0xffEAEAEA);

    final text1Color = isComplete ? AppColors.backgroundColor : Colors.black;

    final text2Color =
        isComplete ? AppColors.backgroundColor : const Color(0xFF7D7C7C);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
        border: Border.all(
          width: 1.5,
          color: borderColor,
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
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
              child: model.imageUrl.isNotEmpty
                  ? Image.network(
                      "${AppUrls.imageUrl}${model.imageUrl}",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          SizedBox(width: 8.w),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: .3.sw,
                child: Text(
                  model.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: text1Color,
                      ),
                  textAlign: TextAlign.start,
                ),
              ),
              // if (model.rackName.isNotEmpty)
              //   RichText(
              //     text: TextSpan(
              //       text: "Rack: ",
              //       style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //             color: text2Color,
              //             fontSize: 14.sp,
              //           ),
              //       children: <TextSpan>[
              //         TextSpan(
              //           text: model.rackName,
              //           style:
              //               Theme.of(context).textTheme.headlineLarge?.copyWith(
              //                     color: text1Color,
              //                     fontSize: 14.sp,
              //                   ),
              //         ),
              //       ],
              //     ),
              //   ),
              Text(
                "Quantity: ${model.quantity}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: text2Color,
                    ),
              ),
              Text(
                "${model.size} ${model.measurement}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: text2Color,
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (status == ItemStatus.done)
            Text(
              "Done",
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: text1Color,
              ),
            ),
          if (status == ItemStatus.remaining) ...[
            Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              height: 42.h,
              width: 2.w,
              color: Colors.grey, // Set divider color based on status
            ),
            Text(
              "Remaining: $quantity",
              style: TextStyle(
                fontSize: 10.sp,
                color: text1Color, // Set text color based on status
              ),
            ),
          ],
        ],
      ),
    );
  }
}
