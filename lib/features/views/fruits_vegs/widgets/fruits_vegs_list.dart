import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/fruits_vegs/widgets/scan_tag_screen.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:provider/provider.dart';

class FruitsVegsList extends StatefulWidget {
  const FruitsVegsList({
    super.key,
    required this.checkedProducts,
    required this.selectedDate,
    this.storeId,
  });

  final bool checkedProducts;
  final DateTime selectedDate;
  final int? storeId;

  @override
  State<FruitsVegsList> createState() => _FruitsVegsListState();
}

class _FruitsVegsListState extends State<FruitsVegsList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<FruitsVegsProvider>().loadMoreFruitsVegsData(
            context,
            checkedProducts: widget.checkedProducts,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FruitsVegsProvider>().getFruitsVegsData(
            context,
            checkedProducts: widget.checkedProducts,
            date: widget.selectedDate,
            storeId: widget.storeId,
          ),
      child: Consumer<FruitsVegsProvider>(
        builder: (context, provider, child) {
          return provider.stateFor(widget.checkedProducts).when(
                idle: () => const Center(child: CircularProgressIndicator()),
                loading: () => const Center(child: CircularProgressIndicator()),
                success: (_) {
                  final fruitsVegs = provider.itemsFor(widget.checkedProducts);
                  final isLoadingMore =
                      provider.isLoadingMoreFor(widget.checkedProducts);

                  final groupedByRack = <String, List<ProductModel>>{};
                  for (final item in fruitsVegs) {
                    final rackName = item.rackName.toString();
                    groupedByRack.putIfAbsent(rackName, () => <ProductModel>[]);
                    groupedByRack[rackName]!.add(item);
                  }

                  final rackNames = groupedByRack.keys.toList();

                  if (rackNames.isEmpty) {
                    return const Center(child: Text('No products found'));
                  }

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      for (final rackName in rackNames) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          sliver: SliverToBoxAdapter(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: "Rack Name: ",
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge),
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
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180.w,
                              crossAxisSpacing: 8.w,
                              childAspectRatio: 0.5,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = groupedByRack[rackName]![index];
                                final width = (1.sw - 12.w - 24.w) / 2;
                                final userRole =
                                    context.read<HomeProvider>().user.role;

                                return ProductCard(
                                  width: width,
                                  onTap: () async {
                                    if (widget.checkedProducts &&
                                        userRole == UserRole.packer) {
                                      await navigate(
                                        context,
                                        route: NavigationConstants
                                            .basketScanScreenRoute,
                                        extra: {
                                          'forTransfer': true,
                                          'tags': item.units
                                              ?.map((unit) => unit.tag!)
                                              .toList(),
                                        },
                                      );
                                      return;
                                    }

                                    if (widget.checkedProducts &&
                                        userRole == UserRole.productChecker) {
                                      return;
                                    }

                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ScanTagScreen(productModel: item),
                                      ),
                                    );

                                    context
                                        .read<FruitsVegsProvider>()
                                        .getFruitsVegsData(
                                          context,
                                          checkedProducts:
                                              widget.checkedProducts,
                                          date: widget.selectedDate,
                                          storeId: widget.storeId,
                                        );
                                  },
                                  productModel:
                                      CommonProductModel.fromProductModel(item),
                                  status:
                                      (userRole == UserRole.productChecker &&
                                              widget.checkedProducts)
                                          ? ItemStatus.remaining
                                          : widget.checkedProducts
                                              ? ItemStatus.done
                                              : ItemStatus.remaining,
                                  statusToShow: "Transfer Damaged",
                                );
                              },
                              childCount: groupedByRack[rackName]?.length ?? 0,
                            ),
                          ),
                        ),
                      ],
                      if (isLoadingMore)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
                error: (error) => Center(child: Text('Error: $error')),
              );
        },
      ),
    );
  }
}
