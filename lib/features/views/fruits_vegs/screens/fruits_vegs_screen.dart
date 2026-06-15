import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/fruits_vegs/providers/fruits_vegs_provider.dart';
import 'package:packer/features/views/fruits_vegs/widgets/scan_tag_screen.dart';
import 'package:packer/features/views/fruits_vegs/widgets/show_units_info.dart';
import 'package:packer/features/views/low_stock/model/product_model.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:provider/provider.dart';

class FruitsVegsScreen extends StatefulWidget {
  const FruitsVegsScreen({super.key});

  @override
  State<FruitsVegsScreen> createState() => _FruitsVegsScreenState();
}

class _FruitsVegsScreenState extends State<FruitsVegsScreen> {
  //

  @override
  void initState() {
    Future.microtask(
        () => context.read<FruitsVegsProvider>().getFruitsVegsData(context));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fruits and Vegetables')),
      body: Consumer<FruitsVegsProvider>(
        builder: (context, provider, child) {
          return provider.fruitsVegsState.when(
            idle: () {
              return const Center(child: CircularProgressIndicator());
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            success: (data) {
              final fruitsVegs = data.results;
              final groupedByRack = <String, List<ProductModel>>{};

              for (final item in fruitsVegs) {
                final rackName = (item.rackName).toString();
                groupedByRack.putIfAbsent(rackName, () => <ProductModel>[]);
                groupedByRack[rackName]!.add(item);
              }

              final rackNames = groupedByRack.keys.toList();

              return CustomScrollView(
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
                                final unit = await ShowUnitsInfo.show(
                                    context: context, productModel: item);

                                if (unit == null) return;
                                //
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ScanTagScreen(
                                      productModel: item,
                                      unit: unit,
                                    ),
                                  ),
                                );

                                //
                              },
                              productModel:
                                  CommonProductModel.fromProductModel(item),
                              status: ItemStatus.remaining,
                            );
                          },
                          childCount: groupedByRack[rackName]?.length ?? 0,
                        ),
                      ),
                    ),
                  ],
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
