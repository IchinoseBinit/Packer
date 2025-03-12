import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:packer/constants/app_colors.dart';
import 'package:packer/enum/order_status_type.dart';
import 'package:packer/features/views/auth/provider/home_provider.dart';
import 'package:packer/features/views/home/widgets/notification_order_card.dart';
import 'package:packer/features/views/order/utils/order_callback_func.dart';
import 'package:packer/features/views/home/widgets/order_notifications_list.dart';

class OrderListWidget extends StatelessWidget {
  const OrderListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (context, val, child) {
      if (val.isOnline) {
        if (val.isLoading) {
          return const Center(
            child: CircularProgressIndicator.adaptive(),
          );
        } else
        if (val.latestOrder.isNotEmpty) {
          return ListView.builder(
            itemCount: val.latestOrder.length,
            shrinkWrap: true,
            primary: false,
            itemBuilder: (context, index) {
              final orderItem = val.latestOrder[index];
              switch (orderItem.status) {
                case OrderStatusType.packer_assigned:
                  return NotificationOrderCard(
                    orderItem: orderItem,
                    primaryColor: AppColors.primaryColor,
                    callback:
                        getCallbackFunction(context, orderItem: orderItem),
                  );
                case OrderStatusType.picked:
                  return NotificationOrderCard(
                    orderItem: orderItem,
                    primaryColor: AppColors.primaryColor,
                    callback:
                        getCallbackFunction(context, orderItem: orderItem),
                  );
                case OrderStatusType.completed:
                  return NotificationOrderCard(
                    orderItem: orderItem,
                    primaryColor: AppColors.primaryColor,
                    callback:
                        getCallbackFunction(context, orderItem: orderItem),
                  );
                default:
                  return Container();
              }
            },
          );
        } else if (val.isAvailable && val.notifications.isNotEmpty) {
          return const OrderNotificationList();
        }
      }
      return const SizedBox.shrink();
    });
  }


}
