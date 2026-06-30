// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/hive_db/hive_db_service.dart';
import 'package:packer/features/views/auth/model/user.dart';
import 'package:packer/features/views/audit_product/utils/start_stock_audit.dart';
import 'package:packer/features/views/order/widgets/ask_confirmation.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';

import 'package:provider/provider.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/custom_profile_tile.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, dynamic>> personalInfoData = [];

  final List<Map<String, dynamic>> otherInfoData = [];

  void _prepareOtherInfoData(BuildContext context, HomeProvider value) {
    final UserRole currentRole = context.read<HomeProvider>().user.role;
    if (currentRole == UserRole.productChecker) {
      otherInfoData.add({
        'icon': Icons.local_florist,
        'title': 'Fruits and Vegetables',
        'screen': NavigationConstants.fruitsVegsScreenRoute,
      });
      otherInfoData.add({
        'icon': Icons.leave_bags_at_home,
        'title': 'Request Leave',
        'screen': NavigationConstants.leaveRequestScreenRoute,
      });
      return;
    }

    // Add transfer_list screen only for non-main stores, if not already added
    if (value.isMainStore() == false &&
        !otherInfoData
            .any((e) => e['screen'] == NavigationConstants.transferListRoute)) {
      otherInfoData.add({
        'icon': Icons.inventory,
        'title': 'Inventory Items',
        'screen': NavigationConstants.transferListRoute,
        'onTap': () => navigate(context,
            route: NavigationConstants.transferListRoute,
            extra: {'isDamage': false}),
      });
    }
    if (value.isMainStore() &&
        !otherInfoData.any((e) =>
            e['screen'] ==
            NavigationConstants.inventoryTransferMainStoreRoute)) {
      otherInfoData.add({
        'icon': Icons.inventory,
        'title': 'Inventory Transfer',
        'screen': NavigationConstants.inventoryTransferMainStoreRoute,
      });
    }
    if (value.isMainStore() == false &&
        !otherInfoData.any((e) =>
            e['screen'] ==
            NavigationConstants.inventoryTransferRequestListRoute)) {
      otherInfoData.add({
        'icon': Icons.swap_horiz_rounded,
        'title': 'Inventory Transfer Request',
        'screen': NavigationConstants.inventoryTransferRequestListRoute,
      });
    }

    // Add Stock Verification screen only if user is a store manager and not already added
    if (
        // value.isStoreManager() &&
        !otherInfoData.any(
            (e) => e['screen'] == NavigationConstants.storeSelectionRoute)) {
      otherInfoData.add({
        'icon': Icons.domain_verification,
        'title': 'Stock Verification',
        'screen': NavigationConstants.storeSelectionRoute,
      });
    }
    if (!value.isAuditUser() &&
        !value.isMainStore() &&
        !otherInfoData.any((e) =>
            e['screen'] == NavigationConstants.receiveTransferListRoute)) {
      otherInfoData.add({
        'icon': Icons.local_shipping_rounded,
        'title': 'Receive Basket',
        'screen': NavigationConstants.receiveTransferListRoute,
      });
    }
    // if (!value.isAuditUser() &&
    //     !value.isMainStore() &&
    //     !otherInfoData.any((e) =>
    //         e['screen'] == NavigationConstants.unitProductScannerRoute)) {
    //   otherInfoData.add({
    //     'icon': Icons.local_shipping_rounded,
    //     'title': 'Re-Rack',
    //     'screen': NavigationConstants.unitProductScannerRoute,
    //   });
    // }
    // productListScreenRoute
    if (!value.isAuditUser() &&
        !otherInfoData.any(
            (e) => e['screen'] == NavigationConstants.productlistScreenRoute)) {
      otherInfoData.add({
        'icon': Icons.list,
        'title': 'Re-Rack',
        'screen': NavigationConstants.productlistScreenRoute,
      });
    }

    if (!value.isAuditUser() &&
        !value.isMainStore() &&
        !otherInfoData.any((e) => e['title'] == 'Order Return')) {
      otherInfoData.add({
        'icon': Icons.repeat_rounded,
        'title': 'Order Return',
        'screen': NavigationConstants.orderReturnScreenRoute,
      });
    }

    otherInfoData.add({
      'icon': Icons.not_interested,
      'title': 'Lost Item',
      'onTap': () => navigate(context,
              route: NavigationConstants.damageScanScreenRoute,
              extra: {
                'scanRack': true,
                'forLostItem': true,
              }),
    });

    //
    otherInfoData.add({
      'icon': Icons.ac_unit,
      'title': 'Package Return',
      'screen': NavigationConstants.packageReturnScreenRoute,
    });

    if (!value.isAuditUser() &&
        !value.isMainStore() &&
        !otherInfoData.any((e) => e['title'] == 'Request QR')) {
      otherInfoData.add({
        'icon': Icons.qr_code,
        'title': 'Request QR',
      });
    }

    if (!value.isAuditUser() &&
        !value.isMainStore() &&
        !otherInfoData.any((e) => e['title'] == 'Transfer Damaged Products')) {
      otherInfoData.add({
        'icon': Icons.transfer_within_a_station,
        'title': 'Transfer Damaged Products',
      });
    }
    if (value.isMainStore() &&
        !otherInfoData.any((e) => e['title'] == 'Receive Damaged Products')) {
      otherInfoData.add({
        'icon': Icons.transfer_within_a_station,
        'title': 'Receive Damaged Products',
        'screen': NavigationConstants.transferListRoute,
        'onTap': () {
          navigate(context,
              route: NavigationConstants.transferListRoute,
              extra: {'isDamage': true});
        },
      });
    }

    if (!value.isAuditUser() &&
        value.isMainStore() == true &&
        !otherInfoData.any((e) => e['title'] == 'Product Damage Request')) {
      otherInfoData.add({
        'icon': Icons.repeat_rounded,
        'title': 'Product Damage Request',
      });
    }
    if (!value.isAuditUser() &&
        !otherInfoData.any((e) =>
            e['screen'] == NavigationConstants.expiryProductScreenRoute)) {
      otherInfoData.add({
        'icon': Icons.repeat_rounded,
        'title': 'Product Near Expiry',
        'screen': NavigationConstants.expiryProductScreenRoute,
      });
    }

    //
    final UserRole role = context.read<HomeProvider>().user.role;
    if (role == UserRole.packer || role == UserRole.productChecker) {
      otherInfoData.add({
        'icon': Icons.local_florist,
        'title': 'Fruits and Vegetables',
        'screen': NavigationConstants.fruitsVegsScreenRoute,
      });
    }

    if (!otherInfoData.any((e) => e['title'] == 'Stock Audit')) {
      otherInfoData.add({
        'icon': Icons.fact_check,
        'title': 'Stock Audit',
        'onTap': () => startStockAudit(context),
      });
    }

    //
    otherInfoData.add({
      'icon': Icons.leave_bags_at_home,
      'title': 'Request Leave',
      'screen': NavigationConstants.leaveRequestScreenRoute,
    });
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      Provider.of<PackerTransferProvider>(context, listen: false)
          .setRole(homeProvider.packerSummary?.storeType ?? "");
      _prepareOtherInfoData(context, homeProvider);
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    double myToolBarHeight = 150.h;
    return Consumer<HomeProvider>(builder: (context, value, child) {
      return Scaffold(
        appBar: AppBar(
          title: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
            ),
            height: myToolBarHeight,
            child: Column(
              children: [
                Spacer(),
                CustomProfileListTile(
                  profileImage: AppAssets.profileImage,
                  name: value.user.name,
                  id: value.user.id,
                  phoneNumber: value.user.phoneNumber ?? value.user.role.name,
                ),
              ],
            ),
          ),
          toolbarHeight: myToolBarHeight,
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 10),
                Text(
                  "Other Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w100,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: otherInfoData.length,
                  itemBuilder: (context, index) {
                    final otherInfo = otherInfoData[index];
                    final bool isOrderReturn =
                        otherInfo['title'] == "Order Return";
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (otherInfo['onTap'] != null) {
                              otherInfo['onTap']();
                            } else if (otherInfo['screen'] != null) {
                              navigate(context, route: otherInfo['screen']);
                            }

                            //  else if (otherInfo['title'] ==
                            //     "Receive Damaged Products") {
                            //   navigate(
                            //     context,
                            //     route:
                            //         NavigationConstants.damageProductReturnList,
                            //   );
                            // }
                            // else if (otherInfo['title'] ==
                            //     "Request QR") {
                            //   navigate(context,
                            //       route:
                            //           NavigationConstants.damageScanScreenRoute,
                            //       extra: {'qr': false, 'requestQr': true});
                            // }
                            else if (otherInfo['title'] == "Request QR") {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) => SafeArea(
                                        child: Container(
                                          height: 100.h,
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12.w, vertical: 8.h),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 16.h,
                                                  ),
                                                  child: GeneralElevatedButton(
                                                    marginH: 4.w,
                                                    title: "With QR",
                                                    textStyle: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white),
                                                    onPressed: () {
                                                      navigate(context,
                                                          route: NavigationConstants
                                                              .damageScanScreenRoute,
                                                          extra: {'qr': true});
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 16.h,
                                                  ),
                                                  child: GeneralElevatedButton(
                                                    marginH: 4.w,
                                                    title: "Without QR",
                                                    textStyle: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white),
                                                    onPressed: () {
                                                      navigate(context,
                                                          route: NavigationConstants
                                                              .damageScanScreenRoute,
                                                          extra: {
                                                            'qr': false,
                                                          });
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 16.h,
                                                  ),
                                                  child: GeneralElevatedButton(
                                                    marginH: 4.w,
                                                    title: "With Rack",
                                                    textStyle: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white),
                                                    onPressed: () {
                                                      navigate(context,
                                                          route: NavigationConstants
                                                              .damageScanScreenRoute,
                                                          extra: {
                                                            'scanRack': true,
                                                            'qr': false,
                                                          });
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ));
                            } else if (otherInfo['title'] ==
                                'Transfer Damaged Products') {
                              navigate(context,
                                  route:
                                      NavigationConstants.basketScanScreenRoute,
                                  extra: {
                                    'forTransfer': true,
                                  });
                            } else if (otherInfo['title'] ==
                                'Receive Damaged Products') {
                              navigate(
                                context,
                                route: NavigationConstants.transferListRoute,
                                extra: true,
                              );
                            } else if (otherInfo['title'] ==
                                'Product Damage Request') {
                              navigate(context,
                                  route: NavigationConstants
                                      .productScanScreenRoute,
                                  extra: {
                                    'forDamageRequest': true,
                                  });
                            } else {
                              navigate(context, route: otherInfo['screen']);
                            }
                          },
                          titleTextStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                          iconColor: AppColors.primaryColor,
                          leading: Icon(otherInfo['icon']),
                          title: Text(otherInfo['title']),
                          trailing: Icon(Icons.chevron_right),
                        ),
                        if (isOrderReturn)
                          Divider(
                            color: Colors.grey.withValues(alpha: .5),
                            thickness: 1,
                          ),
                      ],
                    );
                  },
                ),
                SizedBox(height: .4.sh),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 170.w,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14.w),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryColor,
                            ),
                            onPressed: () async {
                              final isConfirmed = await AskConfirmation.show(
                                context,
                                title: 'Do you want to logout?',
                              );

                              if (!isConfirmed) {
                                return;
                              }

                              final isOnline = context
                                  .read<HomeProvider>()
                                  .packerSummary
                                  ?.isOnline = false;

                              // Packers must checkout (scan warehouse QR)
                              // before logout.
                              if ((value.user.role == UserRole.packer) &&
                                  isOnline == true) {
                                await showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Checkout Required'),
                                    content: const Text(
                                        'You need to checkout before logout. '
                                        'Scan the warehouse QR to continue.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );

                                if (!context.mounted) return;
                                final checkedOut = await navigate(
                                  context,
                                  route: NavigationConstants
                                      .packerCheckoutScanRoute,
                                );

                                // Abort logout if checkout was not completed.
                                if (checkedOut != true) {
                                  return;
                                }
                                if (!context.mounted) return;
                              }

                              showLoading(context);
                              await Provider.of<HomeProvider>(context,
                                      listen: false)
                                  .updatepackerStatus(false, context,
                                      showErrorDialog: false);

                              AuthController().logout().then(
                                (value) {
                                  removeLoading(context);
                                  Provider.of<HomeProvider>(context,
                                          listen: false)
                                      .resetUser();
                                  if (value is bool) {
                                    navigateAndRemoveAll(context,
                                        route: NavigationConstants.loginRoute);
                                  } else {
                                    ErrorHandler.alertDialog(context,
                                        "Something went wrong. Please try again later",
                                        () {
                                      navigatePop(context);
                                    });
                                  }
                                },
                              );
                            },
                            child: Text(
                              'Logout',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.backgroundColor),
                            ),
                          ),
                        ),
                      ),
                      if (value.user.role != UserRole.productChecker)
                        SizedBox(
                          width: 170.w,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                ),
                                onPressed: () {
                                  ShowAlertDialog(
                                    title: 'Clear Cache',
                                    body: Text(
                                        'Are you sure you want to clear cache?'),
                                    okFunc: () {
                                      HiveDBService.wipeHiveCompletely();
                                      navigatePop(context);
                                    },
                                    needCancel: true,
                                    cancelFunc: () {
                                      navigatePop(context);
                                    },
                                  ).showAlertDialog(context);
                                },
                                child: Text(
                                  "Clear Cache",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.backgroundColor,
                                      ),
                                )),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      );
    });
  }
}
