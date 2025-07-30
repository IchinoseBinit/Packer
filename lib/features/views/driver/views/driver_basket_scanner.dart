import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:mobile_scanner/src/mobile_scanner_controller.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/driver/controller/driver_controller.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class DriverBasketScanner extends BaseScanScreen {
  DriverBasketScanner({super.scanTitle = "Scan Basket"});

  bool hasScanned = false;
  @override
  Widget? buildFloatingButton(BuildContext context, MobileScannerController controller) {
    return SizedBox.shrink();
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code, MobileScannerController controller) async {
    try {
      if (hasScanned) return;
      hasScanned = true;
      controller.stop();

      HapticFeedback.heavyImpact();

      final value = Provider.of<DriverController>(context, listen: false).onScanBasket(context, code);
      if (value.success && context.mounted) {
        Navigator.pop(context);
        if (value.message != null) {
          showToast(value.message!);
        }
      } else if (context.mounted) {
        await Future.delayed(const Duration(seconds: 1));
        if (value.message == null) {
          controller.start();
        } else {
          handleInvalidQrCode(context, controller, code, value.message);
        }
      }
    } catch (e) {
      handleInvalidQrCode(context, controller, code);
    } finally {
      hasScanned = false;
    }
  }

  void handleInvalidQrCode(BuildContext context, MobileScannerController controller, String code, [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () async {
        navigatePop(context);
        await controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // TODO: implement onDispose
  }

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<DriverController>(context, listen: false).initializeScan(context);
  }

}