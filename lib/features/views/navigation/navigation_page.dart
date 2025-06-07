import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/home/home_screen.dart';
import 'package:packer/features/views/low_stock/views/home_warehouse_screen.dart';
import 'package:packer/features/views/order/views/order_screen.dart';
import 'package:packer/features/views/profile/profile_screen.dart';
import 'package:packer/features/views/stock_verification/views/stock_verification_screen.dart';
import 'package:packer/features/views/stock_verification/views/store_selection_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'package:svg_flutter/svg.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  var selectedIndex = 0;

  void onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  final widgets = [
    const HomeScreen(),
    // const OrderScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final home =Provider.of<HomeProvider>(context, listen: false);
    if (home.isAuditUser()) {
      widgets[0] = StoreSelectionScreen();
    } else if (home.packerSummary?.storeType.contains("main") == true) {
      widgets[0] = HomeWarehouseScreen();
    } 
  }

  @override
  Widget build(BuildContext context) {
    Color changingColor = AppColors.primaryColor;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        handleWillPop(context);
      },
      child: Scaffold(
          body: widgets[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            onTap: onItemTapped,
            currentIndex: selectedIndex,
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  width: 32.w,
                  height: 32.h,
                  color: selectedIndex == 0 ? changingColor : Colors.grey,
                  AppAssets.homeIcon,
                ),
                label: 'Home',
              ),
              // BottomNavigationBarItem(
              //   icon: Column(
              //     children: [
              //       SvgPicture.asset(
              //         width: 32.w,
              //         height: 32.h,
              //         color: selectedIndex == 1 ? changingColor : Colors.grey,
              //         AppAssets.box,
              //       ),
              //     ],
              //   ),
              //   label: 'Orders',
              // ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  width: 32.w,
                  height: 32.h,
                  color: selectedIndex == 1 ? changingColor : Colors.grey,
                  AppAssets.profile,
                ),
                label: 'Profile',
              ),
            ],
          )),
    );
  }

  Future handleWillPop(BuildContext context) async {
    if (selectedIndex != 0) {
      onItemTapped(0);
    } else {
      ShowAlertDialog(
        title: "Exit",
        body: const Text("Do you want to exit the app?"),
        okFunc: () async {
          Navigator.pop(context);
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        },
        needCancel: true,
        cancelFunc: () => Navigator.pop(context),
      ).showAlertDialog(context);
    }
  }
}
