import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';

import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class TransferItemsList extends StatelessWidget {
  const TransferItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transfer Items"),
      ),
      body: Consumer<PackerTransferProvider>(
        builder: (context, provider, child) {
          if (provider.selectedTransferModelLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (provider.selectedTransferModel == null) {
            return const Center(
              child: Text("No transfer items available"),
            );
          }
          if (provider.selectedTransferModel!.items == null ||
              provider.selectedTransferModel!.items!.isEmpty) {
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
                    transferItem: provider.selectedTransferModel!,
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
                SliverToBoxAdapter(
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
                                )),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: SizedBox(height: 8.h)),

                if (provider.rackMap[rackName] != null)
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
                          final product = provider.rackMap[rackName]![index];
                          ItemStatus status =
                              (provider.getScannedCount(product.product ?? 0) ==
                                      product.quantity)
                                  ? ItemStatus.done
                                  : ItemStatus.remaining;
                          final width = (1.sw - 12.w - 24.w) / 2;

                          return ProductCard(
                            width: width,
                            onTap: () {
                              log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.id}");
                              if (status == ItemStatus.done) return;

                              provider.itemTaped(context, product);
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
                        childCount: provider.rackMap[rackName]?.length ?? 0,
                      ),
                    ),
                  ),
              ],

              // Expanded(
              //   child: ListView.builder(
              //     padding: AppConstants.padding,
              //     itemCount: provider.rackList.length,
              //     itemBuilder: (context, index) {
              //       final rackName = provider.rackList[index];
              //       return Column(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           RichText(
              //             text: TextSpan(
              //               children: [
              //                 TextSpan(
              //                     text: "Rack Name: ",
              //                     style:
              //                         Theme.of(context).textTheme.labelLarge),
              //                 TextSpan(
              //                     text: rackName,
              //                     style: Theme.of(context)
              //                         .textTheme
              //                         .headlineSmall
              //                         ?.copyWith(
              //                           fontSize: 16.sp,
              //                         )),
              //               ],
              //             ),
              //           ),
              //           // 8.h
              //           SizedBox(height: 8.h),
              //           if (provider.rackMap[rackName] != null)
              //             IntrinsicGridView.vertical(
              //               columnCount: 2,
              //               verticalSpace: 12.w,
              //               horizontalSpace: 12.w,
              //               children: List.generate(
              //                 provider.rackMap[rackName]?.length ?? 0,
              //                 (index) {
              //                   //

              //                   final product =
              //                       provider.rackMap[rackName]![index];
              //                   ItemStatus status = (provider.getScannedCount(
              //                               product.product ?? 0) ==
              //                           product.quantity)
              //                       ? ItemStatus.done
              //                       : ItemStatus.remaining;
              //                   final width = (1.sw - 12.w - 24.w) / 2;

              //                   return ProductCard(
              //                     width: width,
              //                     onTap: () {
              //                       log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product.id}");
              //                       if (status == ItemStatus.done) return;

              //                       provider.itemTaped(context, product);
              //                     },
              //                     productModel:
              //                         CommonProductModel.fromTransferItemModel(
              //                             product),
              //                     status: status,
              //                     statusToShow: "Completed",
              //                     quantity: (product.quantity ?? 0) -
              //                         provider.getScannedCount(
              //                             product.product ?? 0),
              //                   );
              //                 },
              //               ),
              //             ),
              //         ],
              //       );
              //     },
              //   ),
              // )
              //
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Consumer<PackerTransferProvider>(
          builder: (context, provider, child) {
            final packerRole =
                Provider.of<PackerTransferProvider>(context, listen: false)
                    .role;
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
                        Provider.of<PackerTransferProvider>(context,
                                listen: false)
                            .completeTransfer(context);
                      },
                      title: packerRole == 'packer' ? 'Complete' : 'Accept',
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
    );
  }
}
