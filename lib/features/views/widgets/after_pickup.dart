import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/widgets/customer_address.dart';
import 'package:packer/features/views/widgets/customer_name_column.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';

class AfterPickup extends StatelessWidget {
  final bool isOrderPicked;
  final String customerName;
  final void Function() markArrived;
  const AfterPickup(
      {super.key,
      required this.isOrderPicked,
      required this.markArrived,
      required Null Function() onPressed,
      required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomerNameTile(
          customerName: customerName,
          phoneOnPressed: () {},
        ),
        SizedBox(
          height: 10.h,
        ),
        CustomerAddressTile(
          customerPrimaryAddress: 'B-1/297, Block B Chicken Station, Baneshwor',
          customerSecondaryAddress: '234, Block B, Kathmandu, Nepal',
        ),
        SizedBox(
          height: 20.h,
        ),
        if (isOrderPicked)
          GeneralElevatedButton(
              title: "Mark Arrived",
              isDisabled: !isOrderPicked,
              onPressed: markArrived),
      ],
    );
  }
}
