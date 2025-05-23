// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/features/views/auth/model/user.dart';
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
  final List<Map<String, dynamic>> personalInfoData = [
    {
      'icon': Icons.lock_clock,
      'title': 'Shift',
      "screen": 'shifts',
    },
    {
      'icon': Icons.history,
      'title': 'Documents',
      'screen': NavigationConstants.documentListScreenRoute,
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'COD Settlement',
      'screen': NavigationConstants.unsettledOrdersRoute,
    },
    {
      'icon': Icons.summarize,
      'title': 'Summary',
      'screen': NavigationConstants.weeklySummaryRoute,
    },
  ];

  List<Map<String, dynamic>> otherInfoData = [
    {
      'icon': Icons.notifications,
      'title': 'Notification',
      'screen': 'notification',
    },
    {
      'icon': Icons.history,
      'title': 'Transaction History',
      'screen': 'transaction_history',
    },
    {
      'icon': Icons.inventory,
      'title': 'Inventory Items',
      'screen': 'transfer_list',
    },
  ];

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double myToolBarHeight = 150.h;
    return Consumer<HomeProvider>(builder: (context, value, child) {
      // if (value.user.role == UserRole.manager) {
      //   if (otherInfoData.length <= 2) {
      //     otherInfoData.add({
      //       'icon': Icons.transform,
      //       'title': 'Transfer Items',
      //       'screen': 'transfer_list',
      //     });
      //   }
      // }
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
                  "Your Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w100,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: personalInfoData.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        print(personalInfoData[index]['screen']);
                        navigate(context,
                            route: personalInfoData[index]['screen']);
                      },
                      titleTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                      ),
                      iconColor: AppColors.primaryColor,
                      leading: Icon(personalInfoData[index]['icon']),
                      title: Text(personalInfoData[index]['title']),
                      trailing: Icon(Icons.chevron_right),
                    );
                  },
                ),
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
                  itemCount: otherInfoData.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        navigate(context,
                            route: otherInfoData[index]['screen']);
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
                    );
                  },
                ),
                SizedBox(
                  height: 10,
                ),
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
                                  // Handle registration failure
                                  ErrorHandler().errorHandler(context, value);
                                }
                              },
                            );
                          },
                          child: Text('Logout'),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'VERSION 21.2.2',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
