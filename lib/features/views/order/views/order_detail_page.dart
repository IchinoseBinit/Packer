// order_details.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/order/models/see_order_details_packer.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:provider/provider.dart';

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
  }

  Future<void> fetchOrderDetails() async {
    try {
      Provider.of<HomeProvider>(context, listen: false)
          .acknowledgeOrder(context, widget.orderId);
    } catch (error) {
      print('Error fetching order details: $error');
      // Handle error as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Details"),
      ),
      // body: FutureBuilder<void>(
      //   future: future,
      //   builder: (context, snapshot) {
      //     print(widget.orderId);
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(child: CircularProgressIndicator.adaptive());
      //     }
      //     final orderProvider = Provider.of<OrderProvider>(context);
      //     if (orderProvider.orderDetails == null) {
      //       return const Center(child: Text('Cannot fetch data'));
      //     }
      //     return OrderDetailsContent(
      //       orderId: widget.orderId,
      //       // order: OrderProvider.,
      //     );
      //   },
      // ),

      body: Consumer<HomeProvider>(
        builder: (context, value, child) {
          final OrderDetailModel? orderDetails =
              Provider.of<HomeProvider>(context).orderDetailModel;

          if (value.orderDetailModel == null ||
              value.orderDetailModel!.productDetails == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = value.orderDetailModel!.productDetails!;
          final user = value.orderDetailModel!.data!.userInfo!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order ID: ${widget.orderId} '),
                        Text('Username: ${user.name}'),
                        Text('Address: ${user.address}')
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 10.h,
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 1, color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final String image =
                          "http://13.211.205.215:8000${products[index].imageUrl}";
                      return InkWell(
                        onTap: () => navigate(context,
                            route: NavigationConstants.productqrScreenRoute),
                        child: ListTile(
                          title: Text(products[index].productName ?? "No Name"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  "Quantity: ${products[index].quantity.toString()}"),
                              Row(
                                children: [
                                  Text(
                                      "Size: ${products[index].size.toString()}"),
                                  Text(
                                      " ${products[index].measurement.toString()}"),
                                ],
                              ),
                            ],
                          ),
                          leading: products[index].imageUrl != null
                              ? Image.network(image)
                              : const Icon(Icons.image),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 8.h,
                ),
                if (orderDetails!.data!.status != OrderStatusType.completed &&
                    orderDetails.data!.status != OrderStatusType.cancelled)
                  GeneralElevatedButton(
                    onPressed: () {
                      showLoading(context);
                      // TODO: Bill order
                      Provider.of<OrderProvider>(context, listen: false)
                          .billOrder(widget.orderId)
                          .then((value) {
                        removeLoading(context);

                        Provider.of<HomeProvider>(context, listen: false)
                            .fetchLatestOrders();
                        if (value is bool) {
                          navigateAndRemoveAll(context,
                              route: NavigationConstants.dashboardRoute);
                        } else {
                          showToast(value.toString());
                        }
                      });
                    },
                    title: 'Bill this order',
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
