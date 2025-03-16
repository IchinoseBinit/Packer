import 'package:flutter/material.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/router.dart';
import 'package:provider/provider.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/widgets/general_elevated_button.dart';
import 'package:packer/constants/app_colors.dart';

class OrderNotificationList extends StatelessWidget {
  const OrderNotificationList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (_, value, __) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: value.notifications.length,
        primary: false,
        itemBuilder: (context, index) {
          return buildNotificationItem(context, index);
        },
      );
    });
  }

  Widget buildNotificationItem(BuildContext context, int index) {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
    final notification = homeProvider.notifications[index];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.fillColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Order (${notification.status})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Customer: ${notification.customerName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 5),
          Text(
            'Order ID: ${notification.orderId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GeneralElevatedButton(
            title: "Accept",
            onPressed: () {
              homeProvider.acknowledgeOrder(context, notification.orderId);
              navigate(context,
                  route: NavigationConstants.orderDetailsRoute,
                  extra: notification.orderId);
            },
          ),
        ],
      ),
    );
  }
}
