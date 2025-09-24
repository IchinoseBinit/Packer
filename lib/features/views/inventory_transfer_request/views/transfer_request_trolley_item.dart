import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/inventory_transfer_request/provider/inventory_transfer_request_controller.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class TransferRequestTrolleyItem extends StatelessWidget {
  const TransferRequestTrolleyItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text('Transfer Request Trolley Item'),
      ),
      body: Consumer<InventoryTransferRequestController>(
        builder: (context, controller, child) {
          final items = controller.inventoryRequestDao.getAll();
          if (items.isNotEmpty) {
            return Padding(
              padding: AppConstants.padding,
              child: IntrinsicGridView.vertical(
                columnCount: 2,
                verticalSpace: 12.w,
                horizontalSpace: 12.w,
                children: List.generate(
                  items.length,
                  (index) {
                    final product = items[index];
                    ItemStatus status = (controller.getScannedCount(
                                product.productId ?? 0,
                                fromLocal: true) ==
                            product.quantity)
                        ? ItemStatus.done
                        : ItemStatus.remaining;
                    final width = (1.sw - 12.w - 24.w) / 2;
              
                    return ProductCard(
                      width: width,
                      onTap: () {
                        // log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.productId}");
                        // if (status == ItemStatus.done) return;
                        // controller.setSelectedLocalInventoryTransferRequestItem(
                        //     context, product);
                      },
                      productModel: CommonProductModel
                          .fromInventoryTransferRequestItemModel(product),
                      status: status,
                      statusToShow: "Completed",
                      quantity: (product.quantity ?? 0) -
                          controller.getScannedCount(product.productId ?? 0,
                              fromLocal: true),
                    );
                  },
                ),
              ),
            );
          }
          return const Center(
            child: Text('No Data'),
          );
        },
      ),
      bottomNavigationBar: Consumer<InventoryTransferRequestController>(
          builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GeneralElevatedButton(
                title: "Scan Basket",
                onPressed: () {
                  provider.scanBasketCode(context);
                },
              ),
            ],
          ),
        );
      }),
    );
  }
}
