import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/inventory_transfer_request/provider/inventory_transfer_request_controller.dart';
import 'package:packer/features/views/inventory_transfer_request/views/inventory_transfer_request.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class InventoryTransferRequestItem extends StatelessWidget {
  const InventoryTransferRequestItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text("Transfer Items"),
      ),
      body: Consumer<InventoryTransferRequestController>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (provider.selectedInventoryTransferRequest == null) {
            return const Center(
              child: Text("No transfer items available"),
            );
          }
          if (provider.inventoryTransferRequestItemList.isEmpty) {
            return const Center(
              child: Text("No transfer items available"),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: AppConstants.padding.copyWith(bottom: 8.h),
                sliver: SliverToBoxAdapter(
                  child: TransferRequestNotificationCard(
                    primaryColor: Theme.of(context).primaryColor,
                    transferItem: provider.selectedInventoryTransferRequest!,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: const Divider(
                  height: 1,
                  color: Color(0xffEAEAEA),
                ),
              ),
              for (final rackName in provider.rackList) ...[
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
                        final product =
                            provider.rackWiseInventoryTransferRequestItemList[
                                rackName]![index];
                        ItemStatus status =
                            (provider.getScannedCount(product.productId ?? 0) ==
                                    product.quantity)
                                ? ItemStatus.done
                                : ItemStatus.remaining;
                        final width = (1.sw - 12.w - 24.w) / 2;

                        return ProductCard(
                          width: width,
                          onTap: () {
                            log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.productId}");
                            if (status == ItemStatus.done) return;
                            provider.setSelectedInventoryTransferRequestItem(
                                context, product);
                          },
                          productModel: CommonProductModel
                              .fromInventoryTransferRequestItemModel(product),
                          status: status,
                          statusToShow: "Completed",
                          quantity: (product.quantity ?? 0) -
                              provider.getScannedCount(product.productId ?? 0),
                        );
                      },
                      childCount: provider
                              .rackWiseInventoryTransferRequestItemList[
                                  rackName]
                              ?.length ??
                          0,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<InventoryTransferRequestController>(
        builder: (context, provider, child) {
          if (provider.inventoryRequestDao.getAll().isEmpty) {
            return SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GeneralElevatedButton(
                  title: "Transfer",
                  onPressed: () {
                    provider.initLocal();
                    navigate(context,
                        route: NavigationConstants
                            .inventoryTransferRequestScannerRoute,
                        extra: {"scanBasket": true});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
