import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/vendor/models/vendor_model.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class LowStockDetails extends StatefulWidget {
  const LowStockDetails({super.key, required this.lowStockModel});

  final LowStockModel? lowStockModel;

  @override
  State<LowStockDetails> createState() => _LowStockDetailsState();
}

class _LowStockDetailsState extends State<LowStockDetails> {
  Vendors? selectedVendor;

  @override
  void initState() {
    super.initState();
    if (widget.lowStockModel != null) {
      Provider.of<StockProvider>(context, listen: false).onDetailsTaped(
        context,
        widget.lowStockModel!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Provider.of<StockProvider>(context, listen: false).reset();
          navigatePop(context);
        }
      },
      child: Consumer<StockProvider>(
        builder: (context, state, child) {
          final model = state.selectedModel ?? LowStockModel();

          if (state.isLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state.isError) {
            return Scaffold(
              body: Center(child: Text(state.errorMessage)),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text("${model.storeName} - ${model.qty}",
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Provider.of<StockProvider>(context, listen: false).reset();
                  navigatePop(context);
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () async {
                    final vendor = await navigate(context,
                        route: NavigationConstants.searchVendor);
                    if (vendor != null) {
                      selectedVendor = vendor;
                      if (widget.lowStockModel != null) {
                        Provider.of<StockProvider>(context, listen: false)
                            .onDetailsTaped(context, widget.lowStockModel!,
                                vendorId: vendor.id);
                      }
                    }
                  },
                )
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () =>
                  Provider.of<StockProvider>(context, listen: false)
                      .onDetailsTaped(context, widget.lowStockModel!,
                          vendorId: selectedVendor?.id),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: CustomScrollView(
                  slivers: [
                    // Vendor Chip
                    if (selectedVendor != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Chip(
                            label: Text(
                              selectedVendor!.name,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            deleteIcon: const Icon(Icons.close,
                                size: 18, color: Colors.white),
                            onDeleted: state.isLoading
                                ? null
                                : () {
                                    selectedVendor = null;
                                    if (widget.lowStockModel != null) {
                                      Provider.of<StockProvider>(context,
                                              listen: false)
                                          .onDetailsTaped(
                                              context, widget.lowStockModel!);
                                    }
                                  },
                          ),
                        ),
                      ),
                    // Products by Rack
                    for (final rackName in state.rackNameList)
                      SliverToBoxAdapter(
                        child: InkWell(
                          onTap: () {
                            navigate(
                              context,
                              route: NavigationConstants
                                  .lowStockProductDetailRoute,
                              extra: {
                                "rackName": rackName,
                                "productList": state.rackProductMap[rackName],
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            margin: EdgeInsets.all(4.r),
                            child: ListTile(
                              title: Text(
                                "Rack Name: ${rackName.isEmpty ? "N/A" : rackName}",
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontSize: 16.sp),
                              ),
                              subtitle: Text(
                                "No. of Products: ${state.rackProductMap[rackName]?.length}",
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: Colors.grey),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: (!state.isLoading && !state.isError)
                ? Padding(
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
                  )
                : SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
