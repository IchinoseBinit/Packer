import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:provider/provider.dart';
import 'package:packer/features/views/fruits_vegs/widgets/scan_tag_screen.dart';

class CantSayList extends StatefulWidget {
  const CantSayList({
    super.key,
    required this.selectedDate,
    this.storeId,
  });

  final DateTime selectedDate;
  final int? storeId;

  @override
  State<CantSayList> createState() => _CantSayListState();
}

class _CantSayListState extends State<CantSayList> {
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
      context.read<FruitsVegsProvider>().loadMoreCantSayData(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<FruitsVegsProvider>().getCantSayData(
            context,
            date: widget.selectedDate,
            storeId: widget.storeId,
          ),
      child: Consumer<FruitsVegsProvider>(
        builder: (context, provider, child) {
          return provider.cantSayState.when(
            idle: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            success: (_) {
              final fruitsVegs = provider.cantSayItems;
              final isLoadingMore = provider.isLoadingMoreCantSay;

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
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
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
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180.w,
                          crossAxisSpacing: 8.w,
                          childAspectRatio: 0.5,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = groupedByRack[rackName]![index];
                            final width = (1.sw - 12.w - 24.w) / 2;

                            return ProductCard(
                              width: width,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanTagScreen(
                                      productModel: item,
                                      isCantSay: true,
                                    ),
                                  ),
                                );

                                if (context.mounted) {
                                  context
                                      .read<FruitsVegsProvider>()
                                      .getCantSayData(
                                        context,
                                        date: widget.selectedDate,
                                        storeId: widget.storeId,
                                      );
                                }
                              },
                              productModel:
                                  CommonProductModel.fromProductModel(item),
                              status: ItemStatus.remaining,
                              statusToShow: "Cant Say",
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
