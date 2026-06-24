import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/audit_product/models/stock_audit_model.dart';
import 'package:packer/features/views/audit_product/providers/stock_audit_provider.dart';
import 'package:packer/features/views/audit_product/widgets/audit_units_sheet.dart';
import 'package:packer/features/views/order/widgets/cart_items_list.dart';
import 'package:packer/features/views/product/model/common_product_model.dart';
import 'package:packer/features/views/product/product_card.dart';
import 'package:provider/provider.dart';

/// Rack-grouped, paginated grid of audit products — mirrors the
/// fruits & vegs list UI, backed by [AuditProductModel] (a [ProductModel]).
class AuditProductList extends StatefulWidget {
  const AuditProductList({super.key, required this.onRefresh});

  /// Re-runs page 1 with the screen's current filters.
  final Future<void> Function() onRefresh;

  @override
  State<AuditProductList> createState() => _AuditProductListState();
}

class _AuditProductListState extends State<AuditProductList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<StockAuditProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Consumer<StockAuditProvider>(
        builder: (context, provider, _) {
          return provider.state.when(
            idle: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error) =>
                _ErrorView(error: error, onRetry: widget.onRefresh),
            success: (_) {
              final items = provider.items.toList();

              if (items.isEmpty) return const _EmptyView();

              // group by rack, preserving order
              final grouped = <String, List<AuditProductModel>>{};
              for (final item in items) {
                final rack = item.rackName.isEmpty ? 'Unknown' : item.rackName;
                grouped.putIfAbsent(rack, () => []).add(item);
              }
              final rackNames = grouped.keys.toList();

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
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              TextSpan(
                                text: rackName,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: 16.sp),
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
                            final item = grouped[rackName]![index];
                            final width = (1.sw - 12.w - 24.w) / 2;

                            return ProductCard(
                              width: width,
                              onTap: () =>
                                  AuditUnitsSheet.open(context, product: item),
                              productModel:
                                  CommonProductModel.fromProductModel(item),
                              // expected vs done drives the badge
                              quantity: item.expectedQuantity,
                              status: item.isCompleted
                                  ? ItemStatus.done
                                  : ItemStatus.remaining,
                              statusToShow: "Audited",
                            );
                          },
                          childCount: grouped[rackName]?.length ?? 0,
                        ),
                      ),
                    ),
                  ],
                  if (provider.isLoadingMore)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    // scrollable so pull-to-refresh still works when empty
    return ListView(
      children: [
        SizedBox(height: 200.h),
        const Center(child: Text('No audit products found')),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40.r, color: Colors.redAccent),
            SizedBox(height: 12.h),
            Text(error, textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
