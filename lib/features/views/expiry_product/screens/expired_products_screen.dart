import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/expiry_product/providers/expired_product_provider.dart';
import 'package:packer/features/views/expiry_product/widgets/expired_product_card_widget.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class ExpiredProductsScreen extends StatefulWidget {
  const ExpiredProductsScreen({super.key});

  @override
  State<ExpiredProductsScreen> createState() => ExpiredProductsScreenState();
}

class ExpiredProductsScreenState extends State<ExpiredProductsScreen> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context
          .read<ExpiredProductProvider>()
          .fetchExpiredProduct(isFirstTime: true);
    });

    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<ExpiredProductProvider>();

    if (_controller.position.pixels >=
            _controller.position.maxScrollExtent - 200 &&
        provider.hasNextPage &&
        !provider.isPaginationLoading) {
      provider.fetchExpiredProduct();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(middleWidget: const Text("Near Expiry Products")),
      body: Consumer<ExpiredProductProvider>(
        builder: (_, provider, __) {
          /// First-time loading
          if (provider.isLoading && provider.expiryProductModel.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          /// Empty state
          if (!provider.isLoading && provider.expiryProductModel.isEmpty) {
            return Center(
              child: Text(
                "No Expired Products Found.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            );
          }

          return CustomScrollView(
            controller: _controller,
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final isLastItem =
                          index == provider.expiryProductModel.length;

                      /// Pagination loading indicator
                      if (isLastItem && provider.isPaginationLoading) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(child: CircularProgressIndicator()),
                        );
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
