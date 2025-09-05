import 'dart:async';

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

class _HomeWarehouseScreenState extends State<HomeWarehouseScreen>
    with WidgetsBindingObserver {
  Timer? timer;
  bool _initialized = false;
  bool refetch = false;

  final FirebaseAPI _firebaseAPI = FirebaseAPI();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setup();
    });
  }

  Future<void> _setup() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final stockProvider = Provider.of<StockProvider>(context, listen: false);

    if (homeProvider.isOnline) {
      await stockProvider.fetchLowStockProducts(context, isFromBuild: true);
      startTimer();
    } else {
      stopTimer();
      _firebaseAPI.cancelScheduledNotification();
      stockProvider.reset();
    }

    setState(() {
      _initialized = true;
    });
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        Provider.of<StockProvider>(context, listen: false)
            .fetchLowStockProducts(context);
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (refetch && state == AppLifecycleState.resumed) {
      Provider.of<StockProvider>(context, listen: false)
          .fetchLowStockProducts(context);
      refetch = false;
    } else if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      refetch = true;
    }
  }

  @override
  void dispose() {
    stopTimer();
    _firebaseAPI.cancelScheduledNotification();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, homeProvider, _) {
        return Scaffold(
          appBar: GeneralAppBar(
            needLeading: false,
            middleWidget: CustomSwitch(
              fromWareHouse: true,
              onPressed: () {
                Provider.of<StockProvider>(context, listen: false)
                    .fetchLowStockProducts(context);
              },
            ),
            trailingSvgAsset: AppAssets.trolleyIcon,
            trailingOnPressed: () {
              navigate(
                context,
                route: NavigationConstants.collectedProductViewRoute,
              );
            },
          ),
          body: !_initialized
              ? const Center(child: CircularProgressIndicator())
              : homeProvider.isOnline
                  ? RefreshIndicator(
                      onRefresh: () async {
                        await Provider.of<StockProvider>(context, listen: false)
                            .fetchLowStockProducts(context);
                      },
                      child: SafeArea(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Consumer<StockProvider>(
                                  builder: (context, value, _) {
                                    if (value.isLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    } else if (value.isError) {
                                      return Center(
                                        child: Text(
                                          value.errorMessage,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge,
                                        ),
                                      );
                                    } else {
                                      return ListView.builder(
                                        itemCount: value.lowStockList.length,
                                        itemBuilder: (context, index) {
                                          return LowStockCard(
                                            model: value.lowStockList[index],
                                            primaryColor:
                                                Theme.of(context).primaryColor,
                                            callback: () {
                                              Provider.of<StockProvider>(
                                                      context,
                                                      listen: false)
                                                  .onDetailsTaped(
                                                context,
                                                value.lowStockList[index],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 20.h),
                              GeneralElevatedButton(
                                title: 'Scan Carton',
                                onPressed: () {
                                  navigate(
                                    context,
                                    route: NavigationConstants
                                        .warehouseCartonScannerRoute,
                                  );
                                },
                              ),
                              SizedBox(height: 20.h),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        'You are currently offline.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
        );
      },
    );
  }
}

class LowStockCard extends StatelessWidget {
  final LowStockModel model;
  final Color primaryColor;
  final VoidCallback? callback;
  final String basketId;
  final int? count;

  const LowStockCard({
    super.key,
    required this.model,
    required this.primaryColor,
    this.callback,
    this.count,
    this.basketId = "",
  });

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
                        'Product Count: ${count ?? model.products.length}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      if (basketId.isNotEmpty) ...[
                        Text(
                          'Basket ID: $basketId',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                        ),
                      ],
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
