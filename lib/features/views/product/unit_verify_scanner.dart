import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/features/views/product/provider/product_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class UnitVerifyScanner extends BaseScanScreen {
  final bool reScan;

  bool hasScanned = false;
  UnitVerifyScanner({
    this.reScan = false,
    super.key,
  }) : super(
          scanTitle: "Rack Scanner",
          showFlash: true,
          showBackButton: true,
        );

  @override
  void onScreenCreated(BuildContext context) {
    if (!reScan) {
      final message = Provider.of<ProductProvider>(context, listen: false)
          .unitVerifyModel
          ?.productAvailability
          ?.rackName;
      Provider.of<ScanMessageProvider>(context, listen: false).setMessage(
          context,
          'Scan rack code${message?.isNotEmpty ?? false ? ' :: $message' : ''}');
    }
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    if (hasScanned) return;
    hasScanned = true;

    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      log("code for unit verify: $code");

      // if (!productScan) {
      if (!code.contains('rack')) {
        handleInvalidCode(context, controller, code);
        return;
      }
      // navigatePop(context);
      Future.delayed(
        Durations.medium1,
        () {
          if (!context.mounted) return;
          final success = Provider.of<ProductProvider>(context, listen: false)
              .handleRackScan(context, code, reScan);
          if (!success && context.mounted) {
            controller.start();
          }
        },
      );
      // } else {
      //   final success =
      //       await Provider.of<ProductProvider>(context, listen: false)
      //           .scanProduct(context, code);
      //   if (success && context.mounted) {
      //     Navigator.pop(context);
      //   } else {
      //     controller.start();
      //   }
      // }
    } catch (e) {
      handleInvalidCode(context, controller, code);
    } finally {
      hasScanned = false;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      // canDismiss: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        navigatePop(context);
        controller.start();
      },
    ).showAlertDialog(context);
    hasScanned = false;
  }

  @override
  void onDispose(MobileScannerController controller) async {
    await controller.stop();
    await controller.dispose();
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return const SizedBox.shrink();
  }
}
