import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/stock_verification/provider/stock_verification_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class StockRackScanScreen extends BaseScanScreen {
  final bool changeRack;
  StockRackScanScreen(
      {super.key, super.scanTitle = 'Rack Scanner', this.changeRack = false});

  bool hasScanned = false;

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;

    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      if (!code.toLowerCase().contains("rack")) {
        handleInvalidCode(context, controller, code);
        return;
      }

      if (changeRack) {
        final result =
            Provider.of<StockVerificationProvider>(context, listen: false)
                .onRackChangeScan(context, code);
        if (!result && context.mounted) {
          handleInvalidCode(context, controller, code);
        }
      } else {
        final result =
            Provider.of<StockVerificationProvider>(context, listen: false)
                .onRackScan(context, code);
        if (!result && context.mounted) {
          handleInvalidCode(context, controller, code);
        }
      }
    } catch (e) {
      log(e.toString());
    } finally {
      hasScanned = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        navigatePop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, changeRack ? "Change Rack" : "Scan Rack code");
  }
}
