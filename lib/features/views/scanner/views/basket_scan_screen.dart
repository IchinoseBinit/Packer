import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/constants/navigation_constants.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class BasketScanScreen extends BaseScanScreen {
  final String? basketCode;
  final bool forOrder;

  BasketScanScreen({
    super.key,
    this.basketCode,
    this.forOrder = false,
  }) : super(
          scanTitle: "Basket Scanner",
          showFlash: true,
          showBackButton: true,
        );

  bool hasScanned = false;

  @override
  void onScreenCreated(BuildContext context) {
    if (forOrder) {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage("Scan Basket Code");
    } else {
      Provider.of<ScanMessageProvider>(context, listen: false)
          .setMessage("Scan Basket: $basketCode");
    }
  }


  @override
  Widget? buildFloatingButton(BuildContext context,
      MobileScannerController controller) {
    return SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      // if already scanned return
      if (hasScanned) return;
      hasScanned = true;

      // stop scanner and show loading
      controller.stop();
      HapticFeedback.heavyImpact();
      showLoading(context);

      // check if qr code is basket
      if (!code.toLowerCase().contains("basket")) {
        hasScanned = false;
        handleInvalidCode(context, controller);
        return;
      }

      // update bucket data if scanning basket for order
      if (forOrder) {
        final result = await Provider.of<OrderProvider>(context, listen: false)
            .updateBucketData(code);
        if (result && context.mounted) {
          removeLoading(context);
          hasScanned = false;
          Navigator.pop(context, true);
        } else if (context.mounted) {
          removeLoading(context);
          hasScanned = false;
          controller.start();
        }
      } else {
        final result = Provider.of<PackerTransferProvider>(context, listen: false)
            .scanBasketCode(context, code);
        if (result && context.mounted) {
          hasScanned = false;
          removeLoading(context);
          navigateReplacement(context,
              route: NavigationConstants.transferDetailsRoute);
        } else if (context.mounted) {
         handleInvalidCode(context, controller);
        }
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller);
      }
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
    // Provider.of<PackerTransferProvider>(context, listen: false).resetHasScanned();
  }
}
