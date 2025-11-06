import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
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
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0.h),
      ),
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order ID: ${widget.data.data.id ?? ""} ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    orderProvider.allCartItemScanned()
                        ? Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.green700,
                              borderRadius: BorderRadius.circular(4.h),
                            ),
                            child: Text(
                              "Completed",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                            ),
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.orderDetailColor,
                              borderRadius: BorderRadius.circular(4.h),
                            ),
                            child: Text(
                              "In Progress",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.orderDetailFontColor,
                                  ),
                            ),
                          )
                  ],
                ),

                Row(
                  children: [
                    Text('Status:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                            )),
                    Text(' ${widget.data.data.status ?? ""}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            )),
                  ],
                ),

                Consumer<OrderProvider>(
                    builder: (context, orderProvider, child) {
                  if (orderProvider.bucketData.isNotEmpty) {
                    return Row(
                      children: [
                        Text(
                          'Basket: ',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          orderProvider.bucketData,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                        )
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
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
          ],
        ),
      ),
    );
  }
}
