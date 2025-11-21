import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/constants/navigation_constants.dart';


class ThankYouPage extends StatelessWidget {
  const ThankYouPage({super.key});

  @override
  Widget build(BuildContext context) {
    int deliveryTime = 30;
    return Scaffold(
      backgroundColor: Color(0xFFFF4E96),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Spacer(),
          Text(
            'Thank You!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Container(
              height: 100.h,
              width: 100.w,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50.0),
                  color: Colors.white),
              child: Image.asset(AppAssets.thankyou)),
          SizedBox(height: 16.0),
          Text(
            'You\'ve delivered in',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$deliveryTime minutes',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(50.0),
            ),
            child: IconButton(
              onPressed: () {
                context.go(NavigationConstants.initialRoute +
                    NavigationConstants.dashboardRoute);
              },
              icon: Icon(
                Icons.close,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 20.h),
        ]),
      ),
    );
  }
}
