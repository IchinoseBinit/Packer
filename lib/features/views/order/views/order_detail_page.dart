import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:provider/provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/order/views/order_details_content.dart';

class OrderDetails extends StatefulWidget {
  final String orderId;

  const OrderDetails({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  late Future<void> future;
  @override
  void initState() {
    super.initState();
    future = fetchOrderDetails();
    Provider.of<OrderProvider>(context, listen: false).initState();
  }

  Future<void> fetchOrderDetails() async {
    try {
      await Provider.of<OrderProvider>(context, listen: false)
          .acknowledgeOrder(context, widget.orderId);
    } catch (error) {
      print('Error fetching order details: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, result) async {
        if (did) return;
        // Provider.of<OrderProvider>(context, listen: false).initState(0);
        navigatePop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Order Details"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Provider.of<OrderProvider>(context, listen: false).initState(0);
              navigatePop(context);
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: InkWell(
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text(
                            'Do you want to add another basket?',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                navigate(context,
                                    route:
                                        NavigationConstants.bucketqrScreenRoute,
                                    extra: widget.orderId);
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        );
                      });
                },
                child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Icon(
                      Icons.shopping_cart,
                      size: 24.sp,
                      color: AppColors.primaryColor,
                    )),
              ),
            )
          ],
        ),
        body: RefreshIndicator(
          onRefresh: fetchOrderDetails,
          child: FutureBuilder<void>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator.adaptive());
              }
              final orderProvider = Provider.of<OrderProvider>(context);
              if (orderProvider.orderDetails == null) {
                return const Center(child: Text('Cannot fetch data'));
              }
              return OrderDetailsContent(
                order: orderProvider.orderDetails!,
              );
            },
          ),
        ),
      ),
    );
  }
}
