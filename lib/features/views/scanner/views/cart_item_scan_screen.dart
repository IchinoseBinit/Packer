import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class CartItemScanScreen extends BaseScanScreen {
  final int productId;
  bool hasScanned = false;

  CartItemScanScreen({
    super.key,
    required this.productId,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    final message = Provider.of<OrderProvider>(context, listen: false)
        .scanProductMessage(productId);
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(message);
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();
      showLoading(context);

      // split code to get product id
      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        handleInvalidCode(context, controller);
        return;
      }

      final result = Provider.of<OrderProvider>(context, listen: false)
          .scanProduct(context, productId, code);
      if (result && context.mounted) {
        removeLoading(context);
        Navigator.pop(context, true);
      } else if (context.mounted) {
        removeLoading(context);
        hasScanned = false;
        controller.start();
      }
    } catch (e) {
      handleInvalidCode(context, controller);
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller) {
    removeLoading(context);
    ShowAlertDialog(
      disableBackground: true,
      body: const Text("Invalid QR"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Any cleanup specific to cart item scanning
  }
}
