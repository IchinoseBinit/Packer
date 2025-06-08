import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class IdentifierScanScreen extends BaseScanScreen {
  final String identifier;
  bool hasScanned = false;

  IdentifierScanScreen({
    super.key,
    required this.identifier,
  }) : super(
          scanTitle: 'Identifier Scanner',
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage("Scan Inventory Code");
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
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();

      if (identifier == code) {
        hasScanned = false;
        Navigator.pop(context, true);
      } else if (context.mounted) {
        hasScanned = false;
        controller.start();
      }
    } catch (e) {
      handleInvalidCode(context, controller);
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller) {
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
