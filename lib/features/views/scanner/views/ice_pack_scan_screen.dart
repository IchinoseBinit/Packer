import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/features/views/order/api/order_api.dart';
import 'package:packer/features/views/order/provider/order_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';
import 'base_scan_screen.dart';

class IcePackScanScreen extends BaseScanScreen {
  const IcePackScanScreen({
    super.key,
  }) : super(
          scanTitle: 'Scan Ice Pack',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Ice Pack QR Code");
  }

  @override
  Widget? buildFloatingButton(
      BuildContext context, MobileScannerController controller) {
    return null;
  }

  @override
  Future<void> onCodeDetected(BuildContext context, String code,
      MobileScannerController controller) async {
    try {
      controller.stop();
      HapticFeedback.heavyImpact();

      await OrderApi.checkPackage(code);

      // add ice pack to order provider
      Provider.of<OrderProvider>(context, listen: false)
          .scanIcePack(context, code);
    } catch (e) {
      handleInvalidCode(context, controller, code, e.toString());
      return;
    }
  }

  void handleInvalidCode(
      BuildContext context, MobileScannerController controller, String code,
      [String? message]) {
    ShowAlertDialog(
      disableBackground: true,
      body: Text(message ?? "Invalid QR ${detectQrMessage(code)}"),
      okFunc: () {
        Navigator.pop(context);
        controller.start();
      },
    ).showAlertDialog(context);
  }

  @override
  void onDispose(MobileScannerController controller) {
    // Any cleanup specific to cart item scanning
  }
}
