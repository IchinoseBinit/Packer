import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class CollectedProductView extends StatefulWidget {
  const CollectedProductView({super.key});

  @override
  State<CollectedProductView> createState() => _CollectedProductViewState();
}

class _CollectedProductViewState extends State<CollectedProductView> {
  late Future<List<LowStockModel>> fetchFuture;

  @override
  Widget build(BuildContext context) {
    fetchFuture = Provider.of<StockProvider>(context, listen: false)
        .openBoxForLowStockList(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          Provider.of<StockProvider>(context, listen: false)
              .fetchLowStockProducts(context);
        }
      },
      child: Scaffold(
        appBar: GeneralAppBar(
          middleWidget: const Text("Collected Product"),
          leadingOnPressed: () {
            Provider.of<StockProvider>(context, listen: false)
                .fetchLowStockProducts(context);
            Navigator.pop(context);
          },
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
          child: FutureBuilder(
              future: fetchFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }
                if (snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("No Product Collected"),
                  );
                }
                final lowStockList = snapshot.data!;
                return ListView.builder(
                  itemCount: lowStockList.length,
                  itemBuilder: (context, index) {
                    final lowStock = lowStockList[index];
                    if (lowStock.qty == 0) return const SizedBox.shrink();
                    return LowStockCard(
                      model: lowStock,
                      count: lowStock.qty,
                      primaryColor: Theme.of(context).primaryColor,
                      callback: () {
                        navigate(
                          context,
                          route: NavigationConstants.trolleyScannerRoute,
                        );
                      },
                    );
                  },
                );
              }),
        ),
      ),
    );
  }
}
