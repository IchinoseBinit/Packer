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

    /// Fetch initial data safely after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ExpiredProductProvider>()
          .fetchExpiredProduct(isFirstTime: true);
    });

    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

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
      appBar: GeneralAppBar(
        middleWidget: const Text("Near Expiry Products"),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context
              .read<ExpiredProductProvider>()
              .fetchExpiredProduct(isFirstTime: false);
        },
        child: Consumer<ExpiredProductProvider>(
          builder: (_, provider, __) {
            /// Initial loading
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

            /// Product list with pagination
            return CustomScrollView(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == provider.expiryProductModel.length) {
                          return provider.isPaginationLoading
                              ? Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : const SizedBox.shrink();
                        }

                        final item = provider.expiryProductModel[index];
                        return Column(
                          children: [
                            ExpiredProductCardWidget(item: item),
                            SizedBox(height: 12.h),
                          ],
                        );
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
      ),
    );
  }
}
