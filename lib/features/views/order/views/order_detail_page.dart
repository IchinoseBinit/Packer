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
    final isFull = Provider.of<OrderProvider>(context, listen: true).isChecked;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (did, result) async {
        if (did) return;
        Provider.of<OrderProvider>(context, listen: false).initState();
        navigatePop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Order Details"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Provider.of<OrderProvider>(context, listen: false).initState();
              navigatePop(context);
            },
          ),
          actions: [
            if (isFull)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () {
                    navigate(context,
                        route: NavigationConstants.bucketqrScreenRoute,
                        extra: widget.orderId);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text("Add basket",
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primaryColor)),
                    ),
                  ),
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
