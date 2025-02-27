import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/controllers/extensions/string_extension.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/app_constants.dart';
import 'package:packer/constants/navigation_constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: AppConstants.padding,
          child: Column(
            children: [
              Spacer(),
              Image.asset(
                AppAssets.logoImage,
                height: 160.h,
                width: 160.w,
              ),
              // Image.network(
              //     scale: 0.2,
              //     height: 130.h,
              //     width: 130.w,
              //     "https://upload.wikimedia.org/wikipedia/commons/f/ff/Ondes-Sonores-2017-130X130-shaka.jpg"),
              SizedBox(
                height: 100.h,
              ),
              GeneralElevatedButton(
                  title: "Login",
                  isDisabled: false,
                  onPressed: () {
                    context
                        .go(NavigationConstants.loginRoute.addSlashInRoute());
                  }),
              SizedBox(
                height: 20.h,
              ),
              GeneralElevatedButton(
                textStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp),
                // textStyle: TextStyle(
                //   color: AppColors.primaryColor,
                //   fontWeight: FontWeight.w600,
                // ),
                bgColor: AppColors.fillColor,
                title: "Register",
                isDisabled: false,
                onPressed: () {},
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
