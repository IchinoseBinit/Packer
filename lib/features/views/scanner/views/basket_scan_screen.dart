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
  @override
  final bool fromCall;
  final int orderId;
  final bool forTransfer;
  final bool forExpiredProducts;

  BasketScanScreen({
    super.key,
    this.basketCode,
    this.forOrder = false,
    this.fromCall = false,
    this.forTransfer = false,
    this.forExpiredProducts = false,
    this.orderId = 0,
  }) : super(
          scanTitle: "Basket Scanner",
          showFlash: true,
          showBackButton: true,
          fromCall: fromCall,
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
    Provider.of<OrderProvider>(context, listen: false)
        .clearBasket(code); // Set the basket code for order provider
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      if (!code.toLowerCase().contains("basket")) {
        handleInvalidCode(context, controller, code);
        return;
      }

      if (forOrder) {
        showLoading(context);
        var bucketResult =
            await Provider.of<OrderProvider>(context, listen: false)
                .updateBucketData(context, code);

        if (fromCall && context.mounted && bucketResult.success) {
          removeLoading(context);
          Provider.of<OrderProvider>(context, listen: false).initState();
          navigate(context, route: NavigationConstants.dashboardRoute);
          navigate(context,
              route: NavigationConstants.orderDetailsRoute, extra: orderId);
        } else if (bucketResult.success && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);

          return;
        } else {
          if (bucketResult.message == null) {
            removeLoading(context);
            controller.start();
            _processing = false;
          } else {
            removeLoading(context);
            handleInvalidCode(context, controller, code, bucketResult.message);
          }
        }
      } else if (forTransfer) {
        Provider.of<OrderProvider>(context, listen: false)
            .scanDamagedProductBasket(code);
        navigateReplacement(context,
            route: NavigationConstants.productScanScreenRoute,
            extra: {
              'forDamageTransfer': true,
              'forExpiredProducts': forExpiredProducts,
            });
      } else {
        var result = Provider.of<PackerTransferProvider>(context, listen: false)
            .scanBasketCode(context, code);

        if (result && context.mounted) {
          navigateReplacement(
            context,
            route: NavigationConstants.transferDetailsRoute,
          );
          return;
        } else {
          handleInvalidCode(context, controller, code);
        }
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
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context); // dismiss dialog
        // removeLoading(context);
        // removeLoading(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Clean up if needed
  }
}
