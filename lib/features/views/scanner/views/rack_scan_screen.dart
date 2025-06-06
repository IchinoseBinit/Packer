import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class RackScanScreen extends BaseScanScreen {
  final String? rackCode;
  final int productId;
  bool hasScanned = false;
  bool forCarton = false;

  RackScanScreen({
    super.key,
    this.rackCode,
    required this.productId,
    this.forCarton = false,
  }) : super(
          scanTitle: 'Rack Scanner',
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(rackCode == null ? "Assign a rack" : "Scan Rack $rackCode");
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

      if (forCarton) {
        final result = await Provider.of<StockProvider>(context, listen: false).onScanCarton(context, code);
        if (result && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);
        } else if (context.mounted) {
          removeLoading(context);
          hasScanned = false;
          controller.start();
        }
      }


      if (rackCode == null && context.mounted) {
        // update rack
        final result = await Provider.of<PackerTransferProvider>(context, listen: false)
            .updateRack(context, code, productId);
        if (result && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);
        } else if (context.mounted) {
          removeLoading(context);
          hasScanned = false;
          controller.start();
        }
      }

      if (rackCode == code && context.mounted) {
        Navigator.pop(context, true);
      } else if (context.mounted) {
        hasScanned = false;
        controller.start();
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller);
      }
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
