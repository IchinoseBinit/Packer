import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/home/widgets/notification_order_card.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/order/utils/order_callback_func.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen> {

  @override
  void initState() {
    Provider.of<OrderProvider>(context, listen: false).fetchOrders(orderType: "all");
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : provider.orders.isEmpty
              ? Center(
                  child: Text(
                    'No orders available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.orders.length,
                  primary: false,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final orderItem = provider.orders[index];
                    switch (orderItem.status) {
                      case OrderStatusType.acknowledged:
                      case OrderStatusType.picked:
                      case OrderStatusType.completed:
                      case OrderStatusType.cancelled:
                        return NotificationOrderCard(
                          orderItem: orderItem,
                          primaryColor: AppColors.primaryColor,
                          callback: getCallbackFunction(context,
                              orderItem: orderItem),
                        );
                      default:
                        return Container();
                    }
                  },
                ),
    );
  }
}
