import 'package:flutter/material.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:provider/provider.dart';

import '/enum/order_status_type.dart';
import '/features/views/auth/model/order_notification.dart';

VoidCallback getCallbackFunction(BuildContext context,
    {required OrderNotification orderItem}) {
  switch (orderItem.status) {
    case OrderStatusType.packerAssigned:
      return () {
        Provider.of<OrderProvider>(context, listen: false).initState();
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
      };
    case OrderStatusType.completed:
      return () {
        Provider.of<OrderProvider>(context, listen: false).initState();
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
      };
    case OrderStatusType.cancelled:
      return () {
        Provider.of<OrderProvider>(context, listen: false).initState();
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
      };

    default:
      return () {};
  }
}
