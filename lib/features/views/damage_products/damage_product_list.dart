import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class DamageProductList extends StatefulWidget {
  const DamageProductList({super.key});

  @override
  State<DamageProductList> createState() => _DamageProductListState();
}

class _DamageProductListState extends State<DamageProductList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: Text('Damage Product List'),
      ),
      body: Column(
        children: [
          GeneralElevatedButton(
              title: "Scan Product",
              onPressed: () {
                navigate(context,
                    route: NavigationConstants.productScanScreenRoute,
                    extra: {
                      'forDamageReceive': true,
                    });
              }),
          SizedBox(
            height: 20.h,
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: 5, // Example item count
            separatorBuilder: (context, index) => SizedBox(
              height: 10.h,
            ),
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Damage Product ${index + 1}'),
                subtitle: Text('Hellooo ${index + 1}'),
                trailing: Icon(Icons.arrow_forward_ios_rounded),
                onTap: () {
                  // navigate(context, route: NavigationConstants.scanRackRoute);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
