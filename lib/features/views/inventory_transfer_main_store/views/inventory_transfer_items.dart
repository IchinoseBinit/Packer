import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/inventory_transfer_main_store/controller/inventory_transfer_controller.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';

import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class InventoryTransferItems extends StatelessWidget {
  const InventoryTransferItems({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        navigatePop(context);
        Provider.of<InventoryTransferController>(context, listen: false)
            .getInventoryTransferDetailsById();
      },
      child: Scaffold(
        appBar: GeneralAppBar(
          leadingOnPressed: () {
            navigatePop(context);
            Provider.of<InventoryTransferController>(context, listen: false)
                .getInventoryTransferDetailsById();
          },
          middleWidget: const Text("Transfer Items"),
        ),
        body: Consumer<InventoryTransferController>(
          builder: (context, provider, child) {
            if (provider.selectedInventoryTransfer == null) {
              return const Center(
                child: Text("No transfer items available"),
              );
            }
            if (provider.selectedInventoryTransfer!.items == null ||
                provider.selectedInventoryTransfer!.items!.isEmpty) {
              return const Center(
                child: Text("No transfer items available"),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: AppConstants.padding,
                  sliver: SliverToBoxAdapter(
                    child: TransferNotificationCard(
                      primaryColor: Theme.of(context).primaryColor,
                      transferItem: provider.selectedInventoryTransfer!,
                      basketId: provider.selectedBasket?.identifier ?? '',
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                SliverToBoxAdapter(
                  child: const Divider(
                    height: 1,
                    color: Color(0xffEAEAEA),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                for (final rackName in provider.rackList) ...[
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
                          final product =
                              provider.rackProductMap[rackName]![index];
                          ItemStatus status =
                              (provider.getScannedCount(product.product ?? 0) ==
                                      product.quantity)
                                  ? ItemStatus.done
                                  : ItemStatus.remaining;
                          final width = (1.sw - 12.w - 24.w) / 2;

                          return ProductCard(
                            width: width,
                            onTap: () {
                              log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.product}");
                              if (status == ItemStatus.done) {
                                return;
                              }

                              provider.onItemScanTapped(context, product);
                            },
                            productModel:
                                CommonProductModel.fromTransferItemModel(
                                    product),
                            status: status,
                            statusToShow: "Completed",
                            quantity: (product.quantity ?? 0) -
                                provider.getScannedCount(product.product ?? 0),
                          );
                        },
                        childCount:
                            provider.rackProductMap[rackName]?.length ?? 0,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Consumer<PackerTransferProvider>(
            builder: (context, provider, child) {
              if (provider.selectedTransferModel == null) {
                return const SizedBox.shrink();
              }
              if (provider.selectedTransferModel!.items == null ||
                  provider.selectedTransferModel!.items!.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: provider.showCompleteButton()
                    ? GeneralElevatedButton(
                        onPressed: () {
                          // if(packerRole=='main'){Provider.of<>}
                          Provider.of<PackerTransferProvider>(context,
                                  listen: false)
                              .completeTransfer(context);
                        },
                        title: 'Complete',
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(
                            child: Text(
                              "Please scan all items to complete the transfer",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        ),
      ),
    );
  }
}
