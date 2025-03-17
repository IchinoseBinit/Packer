import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';

class OrderInfoCard extends StatelessWidget {
  final OrderDetailModel data;

  const OrderInfoCard({Key? key, required this.data}) : super(key: key);

  

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0.h),
        side: BorderSide(
          color: Theme.of(context).primaryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Info',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Order ID: ${data.data?.id ?? ""} ',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('Status: ${data.data?.status ?? ""}',
                style: Theme.of(context).textTheme.bodyMedium),
            // Text(
            //   'Created: ${data.createdTimestamp != null ? DateFormatter().formatTimestamp(data.createdTimestamp!) : 'N/A'}',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
            // Text(
            //   'Accepted: ${data.acknowledgedTimestamp != null ? DateFormatter().formatTimestamp(data.acknowledgedTimestamp!) : 'N/A'}',
            //   style: Theme.of(context).textTheme.bodyMedium,
            // ),
          ],
        ),
      ),
    );
  }
}