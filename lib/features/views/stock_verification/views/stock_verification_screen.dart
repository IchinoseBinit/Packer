import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:provider/provider.dart';

import '/constants/app_colors.dart';

class StockVerificationScreen extends StatefulWidget {
  const StockVerificationScreen({super.key, required this.storeId});
  final String storeId;

  @override
  State<StockVerificationScreen> createState() =>
      _StockVerificationScreenState();
}

class _StockVerificationScreenState extends State<StockVerificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StockVerificationProvider>();
      provider.fetchStockItems(widget.storeId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fillColor,
      appBar: AppBar(
        title: const Text('Stock Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<StockVerificationProvider>(context, listen: false)
                  .fetchStockItems(widget.storeId);
            },
          ),
        ],
      ),
      body: Consumer<StockVerificationProvider>(
          builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Padding(
          padding: AppConstants.padding,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Products Remaining: ${provider.stockItems.length}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView.separated(
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 8.h);
                  },
                  itemCount: provider.rackList.length,
                  itemBuilder: (context, index) {
                    final rackName = provider.rackList[index];
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                            text: TextSpan(children: [
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
                        ])),
                        SizedBox(height: 8.h),
                        if (provider.rackProductMap[rackName] != null)
                          IntrinsicGridView.vertical(
                            columnCount: 2,
                            verticalSpace: 6.w,
                            horizontalSpace: 6.w,
                            children: List.generate(
                              provider.rackProductMap[rackName]!.length,
                              (index) {
                                final item =
                                    provider.rackProductMap[rackName]![index];
                                    final width = (1.sw - 12.w- 32.w) /2;
                                return ProductCard(
                                  productModel: CommonProductModel.fromStockItemModel(item),
                                  status: ItemStatus.remaining,
                                  width: width,
                                  onTap: () {
                                     Provider.of<StockVerificationProvider>(
                                            context,
                                            listen: false)
                                        .onItemTap(context, item);
                                  },
                                );
                              },
                            ),
                            // itemBuilder: (context, index) {
                            //   final item =
                            //       provider.rackProductMap[rackName]![index];
                            //   return InkWell(
                            //     onTap: () {
                            //       Provider.of<StockVerificationProvider>(
                            //               context,
                            //               listen: false)
                            //           .onItemTap(context, item);
                            //     },
                            //     child: ProductCard(
                            //       productModel: CommonProductModel.fromStockItemModel(item),
                            //       status: ItemStatus.remaining,
                            //     ),
                            //   );
                            // },
                          ),

                        // 8.h
                        SizedBox(height: 8.h),
                      ],
                    );
                  },
                ),
              ),

              // 16.h
              // const SizedBox(height: 16),
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 16),
              //   child:
              //       GeneralElevatedButton(onPressed: () {}, title: 'Verify',),
              // )
            ],
          ),
        );
      }),
    );
  }
}

class StockItemWidget extends StatelessWidget {
  final StockItemModel cartItem;
  const StockItemWidget({
    super.key,
    required this.cartItem,
  });

  @override
  Widget build(BuildContext context) {
    final text2Color = const Color(0xFF7D7C7C);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 2, 4, 2),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 60.h,
                  width: 60.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: cartItem.image.isNotEmpty
                        ? Image.network(
                            cartItem.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              SizedBox(
                width: 8.w,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: .3.sw,
                    child: Text(
                      cartItem.productName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Text(
                    "${cartItem.size} ${cartItem.measurement}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.homeScreenDimTextColor,
                        ),
                  ),
                  if (cartItem.rackName.isNotEmpty)
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
                            text: cartItem.rackName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontSize: 14.sp,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
          Text(
            "Qty: ${cartItem.stockQuantity}",
            style: TextStyle(
              fontSize: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
