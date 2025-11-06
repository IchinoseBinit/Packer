import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
class ProductItemList extends StatelessWidget {
  const ProductItemList({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              AppAssets.dahii,
              height: 45.h,
              width: 45.h,
            ),
            SizedBox(
              width: 10.w,
            ),
            Column(
              children: [
                Text(
                  'Nandani Thick Curd',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '500 ml',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        Text(
          'x 1',
          style: TextStyle(fontWeight: FontWeight.bold),
        )
      ],
    );
  }
}
