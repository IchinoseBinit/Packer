import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:provider/provider.dart';

class StoreSelectionScreen extends StatelessWidget {
  const StoreSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text("Store Selection"),
        needLeading: false,
      ),
      body: FutureBuilder(
          future: Provider.of<StockVerificationProvider>(context, listen: false)
              .fetchStores(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            final storeList =
                Provider.of<StockVerificationProvider>(context).storeList;
            return Padding(
              padding: AppConstants.padding,
              child: ListView.separated(
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 16);
                },
                itemCount: storeList.length,
                itemBuilder: (context, index) {
                  final store = storeList[index];
                  return StoreCard(
                  storeName: store.name,
                  onPressed: () {
                    Provider.of<StockVerificationProvider>(context, listen: false).setSelectedStore(store);
                    navigate(
                      context,
                      route: NavigationConstants.stockVerificationRoute,
                      extra: store.id.toString(),
                    );
                  },
                );
                },
              ),
            );
          }),
    );
  }
}


class StoreCard extends StatelessWidget {
  final String storeName;
  final VoidCallback onPressed;

  const StoreCard({
    super.key,
    required this.storeName,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: primaryColor.withOpacity(0.4), width: 1),
      ),
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: primaryColor,
              child: const Icon(Icons.storefront, color: Colors.white),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                storeName,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("View", style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}

