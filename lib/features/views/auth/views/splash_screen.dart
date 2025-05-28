
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:packer/controllers/api/dio_client.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/secure_storage_helper.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/constants/secure_storage_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkPermissions();

    Future.delayed(const Duration(seconds: 1)).then((value) async {
      SecureStorageHelper()
          .readKey(key: SecureStorageConstants.accessTokenKey)
          .then((value) async {
        if (value != null) {
          DioClient();
          DioClient.token = value;
          DioClient.refreshToken = (await SecureStorageHelper()
                  .readKey(key: SecureStorageConstants.refreshTokenKey))
              .toString();


          await Provider.of<HomeProvider>(context, listen: false)
              .fetchpackerSummary();

          // Navigate to the home screen
          if (context.mounted) {
            // final homeProvider =
            //     Provider.of<HomeProvider>(context, listen: false);
            // if (homeProvider.packerSummary?.storeType.contains("main") ==
            //     true) {
            //   navigateReplacement(context,
            //       route: NavigationConstants.lowStockRoute);
            //     return;
            // }
            navigateReplacement(context,
                route: NavigationConstants.dashboardRoute);
          }
        } else {
          navigateReplacement(context, route: NavigationConstants.loginRoute);
        }
      });
    });

    // TODO: SecureStorage check access Token
    // Refresh Token
    // If yes access token, go to
    // HomeScreen
    // IF no access token and refresh token
    // RegisterScreen
  }

  Future<void> _checkPermissions() async {
    // Request location permission
    if (await Permission.location.request().isGranted) {
      print("Location permission granted");
    } else {
      print("Location permission denied");
    }

    // Request storage permission (for gallery access)
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 1.sw,
        color: AppColors.splashNewBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Center(
              child: Image.asset(
                AppAssets.splashScreenLogo,
                fit: BoxFit.contain,
                width: 300.h,
                height: 300.h,
              ),
            ),
            const Spacer(),
            Text(
              "Packer App",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(
              height: 24.h,
            ),
          ],
        ),
      ),
    );
  }
}
