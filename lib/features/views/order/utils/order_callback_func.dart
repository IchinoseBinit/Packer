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
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
        Provider.of<OrderProvider>(context, listen: false).initState();
      };
    case OrderStatusType.completed:
      return () {
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
        Provider.of<OrderProvider>(context, listen: false).initState();
      };
    case OrderStatusType.cancelled:
      return () {
        navigate(context,
            route: NavigationConstants.orderDetailsRoute,
            extra: orderItem.orderId);
        Provider.of<OrderProvider>(context, listen: false).initState();
      };

    default:
      return () {};
  }
}
