import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/features/views/profile/provider/order_return_provider.dart';
import 'package:packer/features/views/widgets/general_appbar.dart';
import 'package:provider/provider.dart';

class OrderReturnScreen extends StatefulWidget {
  const OrderReturnScreen({super.key});

  @override
  State<OrderReturnScreen> createState() => _OrderReturnScreenState();
}

class _OrderReturnScreenState extends State<OrderReturnScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderReturnProvider>(context, listen: false)
          .fetchOrderReturns();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GeneralAppBar(
        middleWidget: const Text('Order Return'),
      ),
      body: Consumer<OrderReturnProvider>(
        builder: (context, provider, child) {
          if (provider.returnOrder.isEmpty) {
            return const Center(child: Text("No returned orders found."));
          }

          return ListView.builder(
            itemCount: provider.returnOrder.length,
            itemBuilder: (context, index) {
              final order = provider.returnOrder[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.primaryColor,
                      width: 1.w,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      "OrderId : ${order.orderId}",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Basket : ${order.basket}",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12.sp,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        Text(
                          "Created At : ${order.createdAt}",
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10.sp,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w400,
                                  ),
                        ),
                      ],
                    ),
                    onTap: () {
                      // Handle tap for order return item
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
