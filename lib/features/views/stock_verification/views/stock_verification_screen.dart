import 'package:flutter/material.dart';
import 'package:packer/features/views/stock_verification/model/stock_item_model.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/cart_item.dart';
import '/constants/app_colors.dart';

class StockVerificationScreen extends StatefulWidget {
  const StockVerificationScreen({super.key});

  @override
  State<StockVerificationScreen> createState() =>
      _StockVerificationScreenState();
}

class _StockVerificationScreenState extends State<StockVerificationScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<StockVerificationProvider>(context, listen: false)
        .fetchStockItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Verification'),
      ),
      body: Consumer<StockVerificationProvider>(
          builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: provider.stockItems.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      Provider.of<StockVerificationProvider>(context,
                              listen: false)
                          .onItemTap(context, provider.stockItems[index]);
                    },
                    child: StockItemWidget(
                      cartItem: provider.stockItems[index],
                    ),
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
    return Padding(
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
