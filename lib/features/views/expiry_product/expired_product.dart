import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/expiry_product/controller/expired_product_controller.dart';
import 'package:provider/provider.dart';

class ExpiryProducts extends StatefulWidget {
  const ExpiryProducts({super.key});

  @override
  State<ExpiryProducts> createState() => _ExpiryProductsState();
}

class _ExpiryProductsState extends State<ExpiryProducts> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    // Fetch for first time
    Future.microtask(() {
      context
          .read<ExpiredProductController>()
          .fetchExpiredProduct(isFirstTime: true);
    });

    // Pagination listener
    _controller.addListener(() {
      final provider = context.read<ExpiredProductController>();

      if (_controller.position.pixels == _controller.position.maxScrollExtent &&
          provider.hasNextPage) {
        provider.fetchExpiredProduct();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Near Expiry Products")),
      body: Consumer<ExpiredProductController>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.expiryProductModel.isEmpty) {
            return Center(
                child: Text(
              "No Expired Products Found.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
            ));
          }

          return ListView.builder(
            controller: _controller,
            itemCount: provider.expiryProductModel.length +
                (provider.hasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.expiryProductModel.length) {
                // Pagination loader
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final item = provider.expiryProductModel[index];

              return InkWell(
                onTap: () => navigate(context,
                    route: NavigationConstants.productScanScreenRoute,
                    extra: {
                      'forDamageRequest': true,
                    }),
                child: Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.cartTextColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Product ID: #${item.productId}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w800),
                            ),
                            Text(
                              "Total Units: ${item.totalUnits}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // child: ListTile(
                //   title: Text(item.productName),
                //   subtitle: Text("Total Units: ${item.totalUnits}"),
                //   trailing: Text("#${item.productId}"),
                // ),
              );
            },
          );
        },
      ),
    );
  }
}
