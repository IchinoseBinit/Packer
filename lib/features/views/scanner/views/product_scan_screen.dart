import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/packer_transfer/provider/packer_transfer_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class ProductScanScreen extends BaseScanScreen {
  final int productId;
  bool hasScanned = false;
  bool fromStockVerification = false;
  bool fromTransfer = false;

  ProductScanScreen({
    super.key,
    required this.productId,
    this.fromStockVerification = false,
    this.fromTransfer = false,
  }) : super(
          scanTitle: 'Product Scanner',
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage("Scan Product Code");
  }

  // list of scanned units

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;

      controller.stop();
      HapticFeedback.heavyImpact();

      // split code to get product id
      final prodId = int.tryParse(code.split('-').first) ?? 0;
      if (prodId != productId) {
        handleInvalidCode(context, controller);
        return;
      }

      showLoading(context);

      if (fromStockVerification) {
       final result = await Provider.of<StockVerificationProvider>(context, listen: false)
            .onScanProduct(context, productId, code);
        if ((result) && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);
        }else if (context.mounted) {
          handleInvalidCode(context, controller);
        }
      } else

      if (fromTransfer) {
       final result = await Provider.of<PackerTransferProvider>(context, listen: false)
            .scanProduct(context, productId, code);
        if ((result) && context.mounted) {
          removeLoading(context);
          Navigator.pop(context, true);
        }else if (context.mounted) {
          handleInvalidCode(context, controller);
        }
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
