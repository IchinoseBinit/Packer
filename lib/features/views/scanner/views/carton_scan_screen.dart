import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/low_stock/provider/stock_provider.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/custom_loading_indicator.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class CartonScanScreen extends BaseScanScreen {
  final int cartonId;
  final bool fromVerification;
  CartonScanScreen({super.key, required this.cartonId, this.fromVerification = false})
      : super(
          scanTitle: 'Carton Scanner',
          showFlash: true,
          showBackButton: true,
        );

  bool _isProcessing = false;

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Carton Code");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      await controller.stop();
      HapticFeedback.heavyImpact();

      showLoading(context);
      log("Carton Code: $code");

      if (!code.toLowerCase().contains("carton")) {
        if (context.mounted) {
          handleInvalidCode(context, controller, code);
        }
        return;
      }


      bool result = false;
      
      if (!fromVerification && context.mounted) {
        result = await Provider.of<StockProvider>(context, listen: false)
          .onScanCarton(context, code, cartonId: cartonId);
      } else if (fromVerification && context.mounted) {
        result = Provider.of<StockVerificationProvider>(context, listen: false)
          .onScanCarton(context, code);
      }

      if (!result && context.mounted) {
        handleInvalidCode(context, controller, code);
      } else if (context.mounted) {
        removeLoading(context);
        // Optionally navigate back or show success message
      }
    } catch (e) {
      if (context.mounted) {
        handleInvalidCode(context, controller, code);
      }
    } finally {
      _isProcessing = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code) {
    removeLoading(context);
    ShowAlertDialog(
      disableBackground: true,
      body: Text("Invalid QR ${detectQrMessage(code)}"),
      okFunc: () async {
        navigatePop(context);
        await controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Cleanup if needed
  }
}
