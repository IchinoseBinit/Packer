// ignore_for_file: sized_box_for_whitespace

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

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

class ProfileScreen extends StatelessWidget {
  final List<Map<String, dynamic>> personalInfoData = [];

  final List<Map<String, dynamic>> otherInfoData = [];

  ProfileScreen({super.key});

  void _prepareOtherInfoData(BuildContext context, HomeProvider value) {
    // Add transfer_list screen only for non-main stores, if not already added
    if (value.isMainStore() == false &&
        !otherInfoData
            .any((e) => e['screen'] == NavigationConstants.transferListRoute)) {
      otherInfoData.add({
        'icon': Icons.inventory,
        'title': 'Inventory Items',
        'screen': NavigationConstants.transferListRoute,
      });
    }

    // Add Stock Verification screen only if user is a store manager and not already added
    if (value.isStoreManager() &&
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
    // // productListScreenRoute
    // if (!value.isAuditUser() &&
    //     !otherInfoData.any(
    //         (e) => e['screen'] == NavigationConstants.productListScreenRoute)) {
    //   otherInfoData.add({
    //     'icon': Icons.list,
    //     'title': 'Re-Rack',
    //     'screen': NavigationConstants.productListScreenRoute,
    //   });
    // }

    if (!value.isAuditUser() &&
        !value.isMainStore() &&
        !otherInfoData.any((e) => e['title'] == 'Order Return')) {
      otherInfoData.add({
        'icon': Icons.repeat_rounded,
        'title': 'Order Return',
        'screen': NavigationConstants.orderReturnScreenRoute,
      });
    }
    if (!value.isAuditUser() &&
        !otherInfoData.any((e) => e['title'] == 'Report Damage')) {
      otherInfoData.add({
        'icon': Icons.report,
        'title': 'Report Damage',
      });
    }
    if (!value.isAuditUser() &&
        !otherInfoData.any((e) => e['title'] == 'Request QR')) {
      otherInfoData.add({
        'icon': Icons.qr_code,
        'title': 'Request QR',
      });
    }
    // if (!otherInfoData.any((e) => e['title'] == 'Clear Cache')) {
    //   otherInfoData.add({
    //     'icon': Icons.delete,
    //     'title': 'Clear Cache',
    //     // 'screen': NavigationConstants.clearCacheScreenRoute,
    //     'onTap': () {
    //       ShowAlertDialog(
    //         title: 'Clear Cache',
    //         body: Text('Are you sure you want to clear cache?'),
    //         okFunc: () {
    //           HiveDBService.wipeHiveCompletely();
    //          navigatePop(context);
    //         },
    //         needCancel: true,
    //         cancelFunc: () {
    //           navigatePop(context);
    //         },
    //       ).showAlertDialog(context);
    //     }
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    double myToolBarHeight = 150.h;
    return Consumer<HomeProvider>(builder: (context, value, child) {
      Provider.of<PackerTransferProvider>(context, listen: false)
          .setRole(value.packerSummary?.storeType ?? "");

      _prepareOtherInfoData(context, value);

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
                    final bool isOrderReturn =
                        otherInfoData[index]['title'] == "Order Return";
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            if (otherInfoData[index]['onTap'] != null) {
                              otherInfoData[index]['onTap']();
                            }
                            if (otherInfoData[index]['screen'] != null) {
                              navigate(context,
                                  route: otherInfoData[index]['screen']);
                            }
                            if (otherInfoData[index]['title'] == "Request QR") {
                              navigate(context,
                                  route:
                                      NavigationConstants.damageScanScreenRoute,
                                  extra: {'qr': false, 'requestQr': true});
                            }
                            if (otherInfoData[index]['title'] ==
                                "Report Damage") {
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) => Container(
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
                                                  marginH: 6.w,
                                                  title: "With QR",
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
                                                  marginH: 6.w,
                                                  title: "Without QR",
                                                  onPressed: () {
                                                    navigate(context,
                                                        route: NavigationConstants
                                                            .damageScanScreenRoute,
                                                        extra: {'qr': false});
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ));
                            } else {
                              navigate(context,
                                  route: otherInfoData[index]['screen']);
                            }
                          },
                          titleTextStyle: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 16.sp,
                          ),
                          iconColor: AppColors.primaryColor,
                          leading: Icon(otherInfoData[index]['icon']),
                          title: Text(otherInfoData[index]['title']),
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
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            showLoading(context);
                            AuthController().logout().then(
                              (value) async {
                                removeLoading(context);
                                Provider.of<HomeProvider>(context,
                                        listen: false)
                                    .resetUser();
                                if (value is bool) {
                                  navigateAndRemoveAll(context,
                                      route: NavigationConstants.loginRoute);
                                } else {
                                  ErrorHandler().errorHandler(context, value);
                                }
                              },
                            );
                          },
                          child: Text('Logout'),
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
