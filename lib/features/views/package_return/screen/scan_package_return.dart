import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:packer/controllers/services/navigate.dart';
import 'package:packer/controllers/services/show_toast_message.dart';
import 'package:packer/features/views/package_return/provider/package_return_provider.dart';
import 'package:packer/features/views/scanner/provider/scan_message_provider.dart';
import 'package:packer/features/views/scanner/views/base_scan_screen.dart';
import 'package:packer/features/views/widgets/show_alert_dialog.dart';
import 'package:packer/utils/qr_message.dart';
import 'package:provider/provider.dart';

class ScanPackageReturn extends BaseScanScreen {
  final int orderId;
  final String packageId;

  const ScanPackageReturn({
    super.key,
    required this.orderId,
    required this.packageId,
  }) : super(
          scanTitle: 'Scan Ice Pack To Return',
          showFlash: true,
          showBackButton: true,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

  @override
  void onScreenCreated(BuildContext context) {
    Provider.of<ScanMessageProvider>(context, listen: false)
        .setMessage(context, "Scan Ice Pack QR Code : $packageId");
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

      if (code != packageId) {
        throw Exception("Scanned package does not match the return package.");
      }

      await context
          .read<PackageReturnProvider>()
          .returnPackage(context, orderId, code);

      showToast("Package returned successfully");
      await navigatePop(context);
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
