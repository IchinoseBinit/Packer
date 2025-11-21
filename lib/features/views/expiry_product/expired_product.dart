import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/expiry_product/controller/expired_product_controller.dart';
import 'package:packer/features/views/expiry_product/widgets/expired_product_card_widget.dart';
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
  void dispose() {
    _controller.dispose();
    super.dispose();
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

          return CustomScrollView(
            controller: _controller,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= provider.expiryProductModel.length) {
                        if (provider.isPaginationLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        } else {
                          return const SizedBox
                              .shrink(); // Empty space if not loading
                        }
                      }

                      final item = provider.expiryProductModel[index];

                      return ExpiredProductCardWidget(item: item);
                    },
                    childCount: provider.expiryProductModel.length +
                        (provider.hasNextPage ? 1 : 0),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
