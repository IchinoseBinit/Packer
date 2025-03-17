import 'dart:developer';

import 'package:flutter/material.dart';
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
  }

  Future<void> fetchOrderDetails() async {
    try {
      await Provider.of<OrderProvider>(context, listen: false)
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
      body: FutureBuilder<void>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          final orderProvider = Provider.of<OrderProvider>(context);
          if (orderProvider.orderDetails == null) {
            return const Center(child: Text('Cannot fetch data'));
          }
          return OrderDetailsContent(
            orderId: widget.orderId,
          );
        },
      ),
    );
  }
}
