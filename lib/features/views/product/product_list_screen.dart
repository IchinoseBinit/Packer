import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intrinsic_grid_view/intrinsic_grid_view.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/packer_transfer/views/transfer_item.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/model/product_avaliability.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ProductProvider>(context, listen: false)
        .fetchProductAvailability(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Product List'),
        ),
        bottomNavigationBar: Container(
          color: AppColors.backgroundColor,
          padding: EdgeInsets.symmetric(
            vertical: 16.h,
            horizontal: 16.w,
          ),
          child: GeneralElevatedButton(
            marginH: 12.w,
            title: "Scan Product",
            onPressed: () {
              Provider.of<ProductProvider>(context, listen: false)
                  .onItemTap(context, null);

            },
          ),
        ),
        body: Consumer<ProductProvider>(
          builder: (_, provider, __) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (provider.productAvailabilityList.isEmpty) {
              return const Center(
                child: Text('No Product left to scan'),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.rackList.length,
              itemBuilder: (context, index) {
                final rackName = provider.rackList[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text(rackName),
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
                    // 8.h
                    SizedBox(height: 8.h),
                    IntrinsicGridView.vertical(
                      columnCount: 2,
                      verticalSpace: 12.w,
                      horizontalSpace: 12.w,
                      children: List.generate(
                        provider.rackMap[rackName]?.length ?? 0,
                        (index) {
                          final product = provider.rackMap[rackName]![index];
                          // ItemStatus status =provider.checkScanCount(product.productId)
                          //           ? ItemStatus.done
                          //           : ItemStatus.remaining;
                          final width = (1.sw - 12.w - 32.w) / 2;

                          return ProductCard(
                            width: width,
                            onTap: () {
                              provider.onItemTap(context, product.productId);
                            },
                            productModel:
                                CommonProductModel.fromProductAvailability(
                                    product),
                            status: ItemStatus.remaining,
                          );
                        },
                      ),
                    )
                    // if (provider.rackProductMap[rackName] != null)
                    //   ...provider.rackProductMap[rackName]!.map(
                    //     (product) => ProductCard(
                    //     onTap: () {
                    //       if (provider.checkScanCount(product.productId)) {
                    //         return;
                    //       }
                    //       provider.onItemTap(context, product.productId);

                    //     },
                    //       productModel: CommonProductModel.fromProductAvailability(product),
                    //       status: provider.checkScanCount(product.productId)
                    //           ? ItemStatus.done
                    //           : ItemStatus.remaining,
                    //       quantity: provider.getTagsList(product.productId, true).length,
                    //     ),
                    //   ),
                  ],
                );
              },
            );
          },
        ));
  }
}

class ItemWidget extends StatelessWidget {
  const ItemWidget({
    super.key,
    required this.model,
    required this.status,
    this.quantity = 1,
  });

  final ProductAvailability model;
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
              child: model.image.isNotEmpty
                  ? Image.network(
                      model.image,
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
                "Quantity: ${model.productUnits.length}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: text2Color,
                    ),
              ),
              // Text(
              //   "${model.size} ${model.measurement}",
              //   style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //         color: text2Color,
              //       ),
              // ),
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
