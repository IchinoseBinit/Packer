import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_assets.dart';
import 'package:packer/features/views/order/models/fetch_order_details.dart';
import 'package:packer/utils/call_number.dart';
import 'package:svg_flutter/svg.dart';

class CustomerInfoCard extends StatelessWidget {
  final OrderDetailsFetch customer;

  const CustomerInfoCard({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Info:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              width: 1.5,
              color: const Color(0xffEAEAEA),
            ),
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            title: Text(customer.customerInfo.name),
            subtitle: const Text(
              "(Customer)",
            ),
            leading: const CircleAvatar(
              radius: 26,
              child: Icon(Icons.person),
            ),
            trailing: customer.customerInfo.phoneNumber.isNotEmpty
                ? InkWell(
                  onTap: () {
                    callNumber(customer.customerInfo.phoneNumber);
                  },
                  child: CircleAvatar(
                      backgroundColor: const Color(0xff54B976),
                      radius: 24,
                      child: SvgPicture.asset(
                        AppAssets.phoneRingIcon,
                      ),
                    ),
                )
                : const SizedBox.shrink(),
          ),
        ),
        // Text(
        //   'Name: ${customer.customerInfo.name}', // Access name directly
        //   style: Theme.of(context).textTheme.bodySmall,
        // ),
        // Text(
        //   'Phone no: ${customer.customerInfo.phoneNumber}', // Access phone directly
        //   style: Theme.of(context).textTheme.bodySmall,
        // ),
      ],
    );
  }
}
