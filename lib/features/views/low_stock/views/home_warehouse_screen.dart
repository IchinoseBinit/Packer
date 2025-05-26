import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/firebase_opt/firebase.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/low_stock/model/low_stock_model.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/widgets/custom_switch.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

class HomeWarehouseScreen extends StatefulWidget {
  const HomeWarehouseScreen({super.key});

  @override
  State<HomeWarehouseScreen> createState() => _HomeWarehouseScreenState();
}

class _HomeWarehouseScreenState extends State<HomeWarehouseScreen> {
  Timer? timer;
  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    timer = Timer.periodic(Duration(minutes: 5), (timer) {
      Provider.of<StockProvider>(context, listen: false)
          .fetchLowStockProducts();
    });
  }

  void stopTimer() {
    if (timer != null) {
      timer!.cancel();
    }
  }

  @override
  void dispose() {
    stopTimer();
    FirebaseAPI().cancelScheduledNotification();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (context, homeProvider, child) {
      if (homeProvider.isOnline) {
        Provider.of<StockProvider>(context, listen: false)
            .fetchLowStockProducts();
        startTimer();
      } else {
        stopTimer();
        FirebaseAPI().cancelScheduledNotification();
        Provider.of<StockProvider>(context, listen: false).reset();
      }
      return Scaffold(
        appBar: GeneralAppBar(
          needLeading: false,
          middleWidget: Consumer<HomeProvider>(builder: (_, value, __) {
            return const CustomSwitch(fromWareHouse: true);
          }),
          trailingSvgAsset: AppAssets.bell_icon,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await Provider.of<StockProvider>(context, listen: false)
                        .fetchLowStockProducts();
                  },
                  child: Consumer<StockProvider>(
                    builder: (context, value, child) {
                      if (value.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (value.isError) {
                        return Center(
                          child: Text(
                            value.errorMessage,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      } else {
                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 16.h),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: value.lowStockList.length,
                          itemBuilder: (context, index) {
                            return LowStockCard(
                              model: value.lowStockList[index],
                              primaryColor: Theme.of(context).primaryColor,
                              callback: () {
                                Provider.of<StockProvider>(context,
                                        listen: false)
                                    .onDetailsTaped(
                                        context, value.lowStockList[index]);
                              },
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 20.h),
                child: GeneralElevatedButton(
                  title: 'Scan Carton',
                  onPressed: () {
                    navigate(
                      context,
                      route: NavigationConstants.qrScanScreenRoute,
                      extra: {'scanCarton': true},
                    ).then((value) {
                      log('Scan Carton Value: $value');
                      if (value != null) {
                        Provider.of<StockProvider>(context, listen: false)
                            .onScanCarton(context, value);
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class LowStockCard extends StatelessWidget {
  final LowStockModel model;
  final Color primaryColor;
  final VoidCallback? callback;

  const LowStockCard({
    Key? key,
    required this.model,
    required this.primaryColor,
    this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: const Icon(Icons.near_me, color: Colors.white),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store: ${model.storeName}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        'Product Count: ${model.products.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (callback != null) ...[
              SizedBox(height: 12.h),
              const Divider(),
              SizedBox(height: 12.h),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    callback?.call();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Text(
                      'Details',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
