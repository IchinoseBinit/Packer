import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

class OrderInfoCard extends StatefulWidget {
  final OrderDetailModel data;

  const OrderInfoCard({super.key, required this.data});

  @override
  State<OrderInfoCard> createState() => _OrderInfoCardState();
}

class _OrderInfoCardState extends State<OrderInfoCard> {
  bool ischecked = false;

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Info',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Order ID: ${widget.data.data.id ?? ""} ',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text('Status: ${widget.data.data.status ?? ""}',
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
            SizedBox(
              child: Row(
                children: [
                  Checkbox(
                      value: ischecked,
                      onChanged: (value) {
                        setState(() {
                          ischecked = value ?? false;
                        });
                        // debugger();
                        Provider.of<OrderProvider>(context, listen: false)
                            .toggle(value!);
                        // _ischecked = value!;
                      }),
                  Text(
                    "is filled",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
