import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/expiry_product/providers/expired_product_provider.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
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
                for (final rackName in provider.rackList) ...[
                  SliverPadding(
                    padding: EdgeInsetsGeometry.symmetric(horizontal: 8.h),
                    sliver: SliverToBoxAdapter(
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
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 8.h)),
                  SliverPadding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180.w,
                        crossAxisSpacing: 8.w,
                        childAspectRatio: 0.5,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item =
                              provider.rackProductMap[rackName]![index];

                          return ProductCard(
                            width: double.infinity,
                            onTap: () async {
                              await navigate(
                                context,
                                route:
                                    NavigationConstants.basketScanScreenRoute,
                                extra: {
                                  'forTransfer': true,
                                  'forExpiredProducts': true,
                                  'tags': item.unitTags,
                                },
                              );

                              await context
                                  .read<ExpiredProductProvider>()
                                  .fetchExpiredProduct(isFirstTime: false);
                            },
                            productModel:
                                CommonProductModel.fromNearExpiry(item),
                            status: item.unitTags.isNotEmpty
                                ? ItemStatus.remaining
                                : ItemStatus.done,
                            quantity: item.unitTags.length,
                          );
                        },
                        childCount:
                            provider.rackProductMap[rackName]?.length ?? 0,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
