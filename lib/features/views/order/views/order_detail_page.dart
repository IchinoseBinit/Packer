// order_details.dart

import 'package:flutter/material.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
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
          if (value.orderDetailModel == null ||
              value.orderDetailModel!.productDetails == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = value.orderDetailModel!.productDetails!;

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 1, color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.separated(
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(products[index].productName ?? "No Name"),
                          subtitle: Text(
                              "Quantity: ${products[index].quantity.toString()}"),
                          leading: products[index].imageUrl != null
                              ? Image.network(products[index].imageUrl!)
                              : const Icon(Icons.image),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
