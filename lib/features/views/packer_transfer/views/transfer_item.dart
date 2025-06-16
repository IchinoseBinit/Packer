import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_urls.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';

import 'package:packer/features/views/packer_transfer/model/transfer_item_model.dart';
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TransferNotificationCard(
                  primaryColor: Theme.of(context).primaryColor,
                  transferItem: provider.selectedTransferModel!,
                ),
              ),
              SizedBox(height: 8.h),
              const Divider(
                height: 1,
                color: Color(0xffEAEAEA),
              ),
              SizedBox(height: 8.h),
              IntrinsicGridView.vertical(
                columnCount: 2,
                verticalSpace: 12.w,
                horizontalSpace: 12.w,
                children: List.generate(
                  provider.selectedTransferModel!.items?.length ?? 0,
                  (index) {
                    final product =
                        provider.selectedTransferModel!.items?[index];
                    ItemStatus status =
                        (product?.itemScanCount == product?.quantity)
                            ? ItemStatus.done
                            : ItemStatus.remaining;
                    final width = (1.sw - 12.w - 32.w) / 2;

                    return ProductCard(
                      width: width,
                      onTap: () {
                        log("Navigating to QR Scan Screen for ${product.productName} and item id: ${product?.id}");
                        if (status == ItemStatus.done) return;
                        provider.itemTaped(context, product);
                      },
                      productModel:
                          CommonProductModel.fromTransferItemModel(product!),
                      status: status,
                    );
                  },
                ),
              )

              // Expanded(
              //   child: ListView.separated(
              //     physics: const BouncingScrollPhysics(),
              //     padding: EdgeInsets.all(16.w),
              //     shrinkWrap: true,
              //     itemCount: provider.selectedTransferModel!.items?.length ?? 0,
              //     itemBuilder: (context, index) {
              //       final transferItem =
              //           provider.selectedTransferModel!.items?[index];

              //       ItemStatus status =
              //           (transferItem?.itemScanCount == transferItem?.quantity)
              //               ? ItemStatus.done
              //               : ItemStatus.remaining;

              //       return ProductCard(
              //       onTap: () {
              //         log("Navigating to QR Scan Screen for ${transferItem?.productName} and item id: ${transferItem?.id}");
              //         if (status == ItemStatus.done) return;
              //         provider.itemTaped(context, transferItem);
              //       },
              //         productModel: CommonProductModel.fromTransferItemModel(
              //             transferItem ?? TransferItemModel()),
              //         status: status,
              //       );
              //     },
              //     separatorBuilder: (context, index) {
              //       return const SizedBox(height: 12);
              //     },
              //   ),
              // ),
            ],
          );
        },
      ),
      bottomNavigationBar:
          Consumer<PackerTransferProvider>(builder: (context, provider, child) {
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
                    Provider.of<PackerTransferProvider>(context, listen: false)
                        .completeTransfer(context);
                  },
                  title: Provider.of<PackerTransferProvider>(context,
                                  listen: false)
                              .role ==
                          'packer'
                      ? 'Complete'
                      : 'Accept',
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Text(
                        "Please scan all items to complete the transfer",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
        );
      }),
    );
  }
}

class TransferItemWidget extends StatelessWidget {
  const TransferItemWidget({
    super.key,
    required this.transferItem,
    required this.status,
  });

  final TransferItemModel transferItem;
  final ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final quantity = (transferItem.quantity ?? 0) - transferItem.itemScanCount;
    final isComplete = quantity == 0 || status == ItemStatus.done;
    final backgroundColor =
        isComplete ? AppColors.green700 : Colors.transparent;

    final borderColor =
        isComplete ? AppColors.green700 : const Color(0xffEAEAEA);

    final text1Color = isComplete ? AppColors.backgroundColor : Colors.black;

    final text2Color =
        isComplete ? AppColors.backgroundColor : const Color(0xFF7D7C7C);
    print(transferItem.tags);

    return Container(
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
              child: transferItem.productImage.isNotEmpty
                  ? Image.network(
                      "${AppUrls.imageUrl}${transferItem.productImage}",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image_not_supported),
                    )
                  : const Icon(Icons.image_not_supported),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: .55.sw,
                  child: Text(
                    transferItem.productName ?? "Unknown",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: text1Color,
                        ),
                    textAlign: TextAlign.start,
                  ),
                ),
                if (transferItem.rack != null && transferItem.rack!.isNotEmpty)
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    text: TextSpan(
                      text: "Rack: ",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: text2Color,
                            fontSize: 14.sp,
                          ),
                      children: <TextSpan>[
                        TextSpan(
                          text: transferItem.rack,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: text1Color,
                                fontSize: 14.sp,
                              ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  "Quantity: ${transferItem.quantity}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: text2Color,
                      ),
                ),
                Row(
                  children: [
                    Text(
                      "Size: ${transferItem.size ?? 'N/A'}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: text2Color,
                          ),
                    ),
                    Text(
                      " ${transferItem.measurement ?? ''}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: text2Color,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
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
