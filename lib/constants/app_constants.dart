import 'package:flutter/material.dart';

class AppConstants {
  static final navigatorKey = GlobalKey<NavigatorState>();

  static const padding =
      EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 20);

  static const bottomNavBarButtonPadding =
      EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 20);

  static const String galliMapsToken = "349ebf7c-9980-483d-8b16-6b193617ed52";

  static const String BASE62_CHARS =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
}

class HiveConstants {
  static const String hivePath = "fasto_packer_data";
  static const String storeId = "store_";
  static const String order = "order_#";
  static const String orderReturn = "order_return_#";
  static const String inventoryTransferRequest = "inventory_transfer_request_#";
}
