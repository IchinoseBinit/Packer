import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

import 'base_scan_screen.dart';

class BasketScanScreen extends BaseScanScreen {
  final String? basketCode;
  final bool forOrder;
  final bool fromCall;
  final int orderId;

  BasketScanScreen({
    super.key,
    this.basketCode,
    this.forOrder = false,
    this.fromCall = false,
    this.orderId = 0,
  }) : super(
          scanTitle: "Basket Scanner",
          showFlash: true,
          showBackButton: true,
        );

  bool _processing = false;

  @override
  void onScreenCreated(BuildContext context) {
    final message = (forOrder || basketCode == null)
        ? "Scan Basket Code"
        : "Scan Basket: $basketCode";
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, message);
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (_processing) return;
    _processing = true;

    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      if (!code.toLowerCase().contains("basket")) {
        handleInvalidCode(context, controller, code);
        return;
      }

      bool result = false;

      if (forOrder) {
        result = await Provider.of<OrderProvider>(context, listen: false)
            .updateBucketData(context, code);
        if (fromCall && context.mounted && result) {
          navigate(context,
              route: NavigationConstants.orderDetailsRoute, extra: orderId);
          Provider.of<OrderProvider>(context, listen: false).initState();
        } else if (result && context.mounted) {
          Navigator.pop(context, true);
          return;
        }
      } else {
        result = Provider.of<PackerTransferProvider>(context, listen: false)
            .scanBasketCode(context, code);

        if (result && context.mounted) {
          navigateReplacement(
            context,
            route: NavigationConstants.transferDetailsRoute,
          );
          return;
        }
      }

      if (context.mounted && !result) {
        handleInvalidCode(context, controller, code);
        return;
      }
    } catch (_) {
      if (context.mounted) {
        handleInvalidCode(context, controller, code);
      }
    } finally {
      _processing = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code) {
    debugger();
    ShowAlertDialog(
      disableBackground: true,
      body: Text("Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context); // dismiss dialog
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Clean up if needed
  }
}
