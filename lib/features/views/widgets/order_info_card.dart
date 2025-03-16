import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/controllers/services/date_formatter.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:provider/provider.dart';

class OrderInfoCard extends StatelessWidget {
  final OrderDetailModel data;

  const OrderInfoCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (context, homeProvider, child) {
      final order = homeProvider.orderDetailModel!.data!;

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
              Text('Order ID: ${order.id}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text('Status: ${order.status}',
                  style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Total Price: ${order.total}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    });
  }
}
