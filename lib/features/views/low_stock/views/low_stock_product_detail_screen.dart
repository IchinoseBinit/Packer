import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/extensions/list_extension.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class LowStockProductDetailScreen extends StatelessWidget {
  const LowStockProductDetailScreen({
    super.key,
    required this.rackName,
    required this.productList,
  });

  final String rackName;
  final List<ProductModel> productList;

  @override
  Widget build(BuildContext context) {
    final state = context.read<StockProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              rackName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            CircleAvatar(
              child: Text(
                productList.length.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180.w,
                crossAxisSpacing: 8.w,
                childAspectRatio: 0.45,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = productList[index];

                  final quantity =
                      (product.quantity > (product.mainStoreStock ?? 0))
                          ? product.mainStoreStock
                          : product.quantity;

                  return ProductCard(
                    key: ValueKey(product.productId),
                    width: double.infinity,
                    onTap: () {
                      if (state.checkScanCount(product.productId)) {
                        return;
                      }
                      ErrorHandler.alertDialog(context, "Scan Carton First");
                    },
                    productModel: CommonProductModel.fromProductModel(product),
                    status: state.getScannedList(product.productId).length ==
                            quantity
                        ? ItemStatus.done
                        : ItemStatus.remaining,
                    quantity: (quantity ?? 0) -
                        state.getScannedList(product.productId).length,
                    statusToShow: state.trolleyItems
                        .firstWhereOrNull(
                            (e) => e.productId == product.productId)
                        ?.status
                        .name,
                  );
                },
                childCount: productList.length,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GeneralElevatedButton(
          onPressed: () => navigate(
            context,
            route: NavigationConstants.qrScanScreenRoute,
            extra: {
              'scanCarton': true,
              'isLowStockCarton': true,
            },
          ),
          title: "Scan",
        ),
      ),
    );
  }
}
