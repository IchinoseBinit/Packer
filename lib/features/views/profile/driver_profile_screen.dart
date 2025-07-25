import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/api/error_handler.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/auth/provider/auth_provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/custom_profile_tile.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeProvider = Provider.of<HomeProvider>(context);
    double myToolBarHeight = 150.h;
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
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
                  name: homeProvider.user.name,
                  id: homeProvider.user.id,
                  phoneNumber: homeProvider.user.phoneNumber ?? homeProvider.user.role.name,
                ),
              ],
            ),
          ),
          toolbarHeight: myToolBarHeight,
        ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
           
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
                            Provider.of<HomeProvider>(context, listen: false)
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
    );
  }
}
