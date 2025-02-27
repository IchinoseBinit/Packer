import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_view/photo_view.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:svg_flutter/svg_flutter.dart';

class ViewImageScreen extends StatelessWidget {
  const ViewImageScreen({
    super.key,
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(imageUrl),
            ),
            GestureDetector(
              onTap: () {
                navigatePop(context);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  height: 40.sp,
                  width: 40.sp,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SvgPicture.asset(AppAssets.backArrow),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
